
import Builtin
import Libc
import Ctru
import Draw

@c @used @unsafe
func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int {
    let ptr = unsafe aligned_alloc(alignment, size)

    if unsafe ptr != nil {
        unsafe memptr.pointee = ptr
        return 0
    } else {
        return Int(ENOMEM)
    }
}

@c @used @unsafe
func _getentropy_r(_ r: UnsafeMutablePointer<_reent>!, _ ptr: UnsafeMutableRawPointer!, _ size: Int) -> Int {
    guard unsafe PS_GenerateRandomBytes(ptr, size) == 0 else {
        if let r = unsafe r { unsafe r.pointee._errno = EIO }
        return -1
    }
    return 0
}

public func log(_ string: borrowing String) {
    unsafe string.withCString { str in
        unsafe _ = svcOutputDebugString(str, Int32(string.utf8.count))
    }
}

public func panic(
    because reason: borrowing String,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    log(
        reason.isEmpty
            ? "PANIC in \(file) on line \(line)"
            : "PANIC in \(file) on line \(line): \(reason)"
    )
    svcBreak(USERBREAK_PANIC)
    svcExitProcess()
}

public struct Thread: ~Copyable {
    private var handle: Handle

    public typealias Body = @Sendable () -> Void

    @unsafe
    private struct Context: ~Copyable {
        let stack: UnsafeMutableRawBufferPointer = .allocate(byteCount: 0x40000, alignment: 8)
        let body: Body

        init(body: @escaping Body) {
            unsafe self.body = body
        }

        deinit {
            unsafe stack.deallocate()
        }
    }

    private init(handle: Handle) {
        self.handle = handle
    }

    @discardableResult
    public init(priority: Priority = .high, cpu: Cpu = .any, _ body: @escaping Body) {
        let context = unsafe UnsafeMutableRawPointer
            .allocate(byteCount: MemoryLayout<Context>.size, alignment: MemoryLayout<Context>.alignment)
            .bindMemory(to: Context.self, capacity: 1)

        unsafe context.initialize(to: .init(body: body))

        var handle: Handle = 0
        unsafe svcCreateThread(
            &handle,
            { userdata in
                let context = unsafe userdata!.assumingMemoryBound(to: Context.self)
                unsafe context.pointee.body()
                unsafe context.deinitialize(count: 1).deallocate()
                svcExitThread()
            },
            UInt32(UInt(bitPattern: context)),
            context.pointee.stack.baseAddress!
                .advanced(by: context.pointee.stack.count - 1)
                .bindMemory(to: UInt32.self, capacity: (context.pointee.stack.count) / MemoryLayout<UInt32>.stride),
            priority.rawValue,
            cpu.rawValue
        )

        self.handle = handle
    }

    public func copy() -> Self {
        var newHandle: Handle = 0
        unsafe svcDuplicateHandle(&newHandle, handle)
        return .init(handle: newHandle)
    }

    deinit {
        if handle != 0 {
            svcWaitSynchronization(self.handle, -1)
            svcCloseHandle(handle)
        }
    }

    public mutating func join() {
        if handle != 0 {
            svcWaitSynchronization(self.handle, -1)
            svcCloseHandle(handle)
            handle = 0
        }
    }

    public static func detached(priority: Priority = .high, cpu: Cpu = .any, _ body: @escaping Body) {
        var thread = Self(priority: priority, cpu: cpu, body)
        thread.detach()
    }

    public mutating func detach() {
        svcCloseHandle(handle)
        handle = 0
    }

    public static func sleep(nanoseconds: Int64) {
        svcSleepThread(nanoseconds)
    }

    public enum Priority : Int32 {
        case high   = 0x18
        case medium = 0x25
        case low    = 0x3F
    }

    public enum Cpu : Int32 {
        case any = -1
        case cpu0 = 0
        case cpu1 = 1
        case cpu2 = 2
        case cpu3 = 3
    }
}

public struct Mutex<T>: ~Copyable, @unchecked Sendable where T: ~Copyable {
    private let handle: Handle
    private var value: Cell<T>

    public init(_ value: consuming T) {
        self.value = Cell(value)
        var handle: Handle = 0
        guard unsafe svcCreateMutex(&handle, false) == 0 else { panic(because: "internal mutex failure") }
        self.handle = handle
    }

    public func withLock<E, R>(_ body: (inout T) throws(E) -> R) throws(E) -> R {
        guard svcWaitSynchronization(handle, -1) == 0 else { panic(because: "internal mutex failure") }
        defer {
            guard svcReleaseMutex(handle) == 0 else { panic(because: "internal mutex failure") }
        }

        return try value.with(body)
    }

    deinit {
        if svcCloseHandle(handle) != 0 { log("failed to close a mutex") }
    }
}

@_rawLayout(like: T, movesAsLike)
private struct Cell<T>: ~Copyable where T: ~Copyable {
    @_transparent
    public var address: UnsafeMutablePointer<T> { unsafe .init(Builtin.addressOfRawLayout(self)) }

    @_transparent
    public init(_ value: consuming T) {
        unsafe address.initialize(to: value)
    }

    @_transparent
    deinit {
        unsafe address.deinitialize(count: 1)
    }

    @_transparent
    public func with<E, R>(_ body: (_ value: inout T) throws(E) -> R) throws(E) -> R {
        unsafe try body(&address.pointee)
    }

    @_transparent
    public consuming func move() -> T {
        unsafe address.move()
    }

    @_transparent
    public consuming func move() -> T where T: Copyable {
        unsafe address.pointee
    }
}

extension Cell: @unchecked Sendable where T: Sendable {}

/// A base class for objects capable of serving as a parent in an object graph.
///
/// Annotate parent references with `@Parent` to weakly reference the parent object and avoid
/// a memory leak. It behaves much like `unowned` but delegates the functionality to the object itself
/// rather than the runtime, which is not available in Embedded Swift.
open class ParentableObject {
    private var childProperties: [any ChildProperty] = []

    public init() {}

    deinit {
        for property in childProperties { property.sever() }
    }

    @unsafe
    public final func _registerChildProperty(_ property: any ChildProperty) {
        childProperties.append(property)
    }

    @unsafe
    public final func _severChildProperty(_ property: any ChildProperty) {
        childProperties.removeAll { $0 === property }
    }
}

public protocol ChildProperty: AnyObject {
    func sever()
}

/// Manages an unowned reference to a parent in an object graph.
@propertyWrapper @safe
public final class Parent<T>: ChildProperty where T: ParentableObject {
    private var parent: Unmanaged<T>?

    public func sever() {
        if unsafe parent != nil {
            unsafe wrappedValue._severChildProperty(self)
            unsafe self.parent = nil
        }
    }

    public init(wrappedValue: T) {
        unsafe parent = Unmanaged.passUnretained(wrappedValue)
        unsafe wrappedValue._registerChildProperty(self)
    }

    public var wrappedValue: T {
        get { unsafe parent!.takeUnretainedValue() }
        set {
            if unsafe parent != nil { sever() }
            unsafe parent = Unmanaged.passUnretained(newValue)
            unsafe wrappedValue._registerChildProperty(self)
        }
    }
}

public struct Xoshiro256StarStar: RandomNumberGenerator {
    private var state: InlineArray<4, UInt64>

    private static func rotl(_ x: UInt64, _ k: Int32) -> UInt64 { return (x << k) | (x >> (64 - k)) }

    public init(state: InlineArray<4, UInt64>) {
        precondition(state[0] | state[1] | state[2] | state[3] != 0)
        self.state = state
    }

    public init(from seed: UInt64) {
        precondition(seed != 0)
        self.init(state: [seed, seed << 1, seed << 2, seed << 3])
    }

    public mutating func next() -> UInt64 {
        let result = Self.rotl(state[1] &* 5, 7) &* 9

        let t = state[1] << 17

        state[2] ^= state[0]
        state[3] ^= state[1]
        state[1] ^= state[2]
        state[0] ^= state[3]

        state[2] ^= t

        state[3] = Self.rotl(state[3], 45)

        return result
    }
}

public struct Input: ~Copyable {
    public private(set) var keysPressed: Keys = []
    public private(set) var keysUnpressed: Keys = []
    public private(set) var keysHeld: Keys = []
    public private(set) var keysRepeating: Keys = []

    internal init() {}

    internal mutating func sync() {
        self.keysPressed   = .init(rawValue: hidKeysDown())
        self.keysUnpressed = .init(rawValue: hidKeysUp())
        self.keysHeld      = .init(rawValue: hidKeysHeld())
        self.keysRepeating = .init(rawValue: hidKeysDownRepeat())
    }

    public func keys(pressed set: Keys) -> Bool { keysPressed.contains(set) }
    public func keys(unpressed set: Keys) -> Bool { keysUnpressed.contains(set) }
    public func keys(held set: Keys) -> Bool { keysHeld.contains(set) }
    public func keys(repeating set: Keys) -> Bool { keysRepeating.contains(set) }

    public func keys(pressedAnyOf set: Keys) -> Bool { !keysPressed.intersection(set).isEmpty }
    public func keys(unpressedAnyOf set: Keys) -> Bool { !keysUnpressed.intersection(set).isEmpty }
    public func keys(heldAnyOf set: Keys) -> Bool { !keysHeld.intersection(set).isEmpty }
    public func keys(repeatingAnyOf set: Keys) -> Bool { !keysRepeating.intersection(set).isEmpty }

    public struct Keys: OptionSet, BitwiseCopyable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let a = Self(rawValue: KEY_A)
        public static let b = Self(rawValue: KEY_B)
        public static let x = Self(rawValue: KEY_X)
        public static let y = Self(rawValue: KEY_Y)

        public static let up    = Self(rawValue: KEY_UP)
        public static let down  = Self(rawValue: KEY_DOWN)
        public static let left  = Self(rawValue: KEY_LEFT)
        public static let right = Self(rawValue: KEY_RIGHT)

        public static let cStickUp    = Self(rawValue: KEY_CSTICK_UP)
        public static let cStickDown  = Self(rawValue: KEY_CSTICK_DOWN)
        public static let cStickLeft  = Self(rawValue: KEY_CSTICK_LEFT)
        public static let cStickRight = Self(rawValue: KEY_CSTICK_RIGHT)

        public static let cPadUp    = Self(rawValue: KEY_CPAD_UP)
        public static let cPadDown  = Self(rawValue: KEY_CPAD_DOWN)
        public static let cPadLeft  = Self(rawValue: KEY_CPAD_LEFT)
        public static let cPadRight = Self(rawValue: KEY_CPAD_RIGHT)

        public static let dPadUp    = Self(rawValue: KEY_DUP)
        public static let dPadDown  = Self(rawValue: KEY_DDOWN)
        public static let dPadLeft  = Self(rawValue: KEY_DLEFT)
        public static let dPadRight = Self(rawValue: KEY_DRIGHT)

        public static let start  = Self(rawValue: KEY_START)
        public static let select = Self(rawValue: KEY_SELECT)

        public static let l  = Self(rawValue: KEY_L)
        public static let r  = Self(rawValue: KEY_R)
        public static let zl = Self(rawValue: KEY_ZL)
        public static let zr = Self(rawValue: KEY_ZR)
    }
}

public struct Renderer: ~Copyable {
    public var top: Screen = unsafe Screen(.top)
    public var bottom: Screen = unsafe Screen(.bottom)

    @unsafe
    internal init() {}

    @unsafe
    internal mutating func sync() {
        unsafe top.sync()
        unsafe bottom.sync()
    }

    @safe
    public struct Screen: SizedMutablePlane, ~Copyable {
        public let index: Index

        private var buffer: UnsafeMutablePointer<Pixel>!
        private var stride: Int = 0

        public let width: Int
        public let height: Int

        private typealias Pixel = (b: UInt8, g: UInt8, r: UInt8)

        @unsafe
        internal init(_ index: Index) {
            self.index = index

            (self.width, self.height) = switch index {
                case .top:    (width: Int(GSP_SCREEN_HEIGHT_TOP),    height: Int(GSP_SCREEN_WIDTH))
                case .bottom: (width: Int(GSP_SCREEN_HEIGHT_BOTTOM), height: Int(GSP_SCREEN_WIDTH))
            }
        }

        @unsafe
        internal mutating func sync() {
            var stride: UInt16 = 0; let framebuffer = unsafe gfxGetFramebuffer(
                self.index.rawValue,
                GFX_LEFT,
                &stride,
                nil
            )
            self.stride = Int(stride)

            unsafe self.buffer = UnsafeMutableRawPointer(framebuffer)?
                .bindMemory(to: Pixel.self, capacity: self.width * self.stride)
        }

        @_transparent @const
        private func offset(x: Int, y: Int) -> Int {
            x * stride + (stride - 1 - y)
        }

        public subscript(x: Int, y: Int) -> Color {
            get {
                if x >= 0 && y >= 0 && x < width && y < height {
                    let (b, g, r) = unsafe self.buffer[offset(x: x, y: y)]; then .init(r: r, g: g, b: b)
                } else {
                    .clear
                }
            }
            set {
                if x >= 0 && y >= 0 && x < width && y < height {
                    let (r, g, b) = (newValue.r, newValue.g, newValue.b)
                    unsafe self.buffer[offset(x: x, y: y)] = (b, g, r)
                }
            }
        }

        public enum Index {
            case top
            case bottom

            @_transparent
            internal var rawValue: gfxScreen_t {
                switch self {
                    case .top:    GFX_TOP
                    case .bottom: GFX_BOTTOM
                }
            }
        }
    }
}

public protocol Application: ~Copyable {
    init()
    mutating func update(with input: borrowing Input)
    borrowing func draw(with input: borrowing Input, into target: inout Renderer)
}

extension Application {
    private static func fail(because reason: borrowing String) -> Never {
        unsafe consoleInit(GFX_TOP, nil)
        print(reason)

        var input = Input()

        while aptMainLoop() {
            input.sync()

            if !input.keysHeld.isEmpty { break }

            gfxFlushBuffers()
      		gfxSwapBuffers()
      		gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)
        }

        exit(-1)
    }

    public static func main() {
        osSetSpeedupEnable(true)

        gfxInit(GSP_BGR8_OES, GSP_BGR8_OES, false)
        defer { gfxExit() }

        if romfsInit() != 0 { fail(because: "romfs could not initialize") }
        defer { romfsExit() }

        var app = Self()

        var input = Input()
        var renderer = unsafe Renderer()

        while aptMainLoop() {
            hidScanInput()

            input.sync()
            unsafe renderer.sync()

            if input.keys(held: [.start, .select]) { break }

            app.update(with: input)
            app.draw(with: input, into: &renderer)

            gfxFlushBuffers()
      		gfxSwapBuffers()
      		gspWaitForEvent(GSPGPU_EVENT_VBlank0, true)
        }
    }

    public static func resource(path: borrowing String) -> [UInt8] { ResourceLoader.load(path: path) }

    public static var memoryUsage: (used: Int, free: Int, size: Int) {
        (
            used: Int(osGetMemRegionUsed(MEMREGION_ALL)) / 1024,
            free: Int(osGetMemRegionFree(MEMREGION_ALL)) / 1024,
            size: Int(osGetMemRegionSize(MEMREGION_ALL)) / 1024
        )
    }
}

public struct PerformanceCounter {
    private let startTick = svcGetSystemTick()
    public init() {}
    public func elapsed() -> UInt64 { svcGetSystemTick() - startTick }

    public static let cyclesPerFrame: UInt64 = 268_123_480 / 60

    public static func percentage(cycles: UInt64) -> Float { ratio(cycles: cycles) * 100 }
    public static func ratio(cycles: UInt64) -> Float { Float(cycles) / Float(cyclesPerFrame) }

    public func percentageString() -> String { String(Int(percentage())) + "%" }
    public func percentage() -> Float { ratio() * 100 }
    public func ratio() -> Float { Float(elapsed()) / Float(Self.cyclesPerFrame) }
}

extension PerformanceCounter: CustomStringConvertible {
    public var description: String { percentageString() }
}

private enum ResourceLoader {
    public static func load(path: borrowing String) -> [UInt8] {
        guard let file = unsafe fopen("romfs:/\(path)", "rb") else {
            unsafe panic(because: .init(cString: strerror(__errno()!.pointee)))
        }
        defer { unsafe fclose(file) }

        unsafe fseek(file, 0, SEEK_END)
        let size = unsafe ftell(file)
        unsafe rewind(file)

        guard size > 0 else { return [] }

        return unsafe .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
            initializedCount = unsafe fread(buffer.baseAddress, 1, size, file)
        }
    }
}

/// A native, 3DS platform provided font sheet.
@safe
public struct SystemFontSource: SizedPlane {
    private let font: OpaquePointer

    public var width: Int { 512 }
    public var height: Int { 512 }

    public subscript(x: Int, y: Int) -> Color {
        fatalError()
    }
}

extension Font where Source == Image {
    private static let mineSource = TgaImage(from: ResourceLoader.load(path: "minefont.tga"))
        .flatten()
        .grid(cellWidth: 5, cellHeight: 8)

    public static let mine = Font(height: 8, baseline: 1, spacing: 1, leading: 1) { character in
        switch character {
            case " ": .space(width: 3)

            case "A": .glyph(mineSource.cell(x: 1,  y: 0))
            case "B": .glyph(mineSource.cell(x: 2,  y: 0))
            case "C": .glyph(mineSource.cell(x: 3,  y: 0))
            case "D": .glyph(mineSource.cell(x: 4,  y: 0))
            case "E": .glyph(mineSource.cell(x: 5,  y: 0))
            case "F": .glyph(mineSource.cell(x: 6,  y: 0))
            case "G": .glyph(mineSource.cell(x: 7,  y: 0))
            case "H": .glyph(mineSource.cell(x: 8,  y: 0))
            case "I": .glyph(mineSource.cell(x: 9,  y: 0).resize(horizontal: -1))
            case "J": .glyph(mineSource.cell(x: 10, y: 0))
            case "K": .glyph(mineSource.cell(x: 11, y: 0))
            case "L": .glyph(mineSource.cell(x: 12, y: 0))
            case "M": .glyph(mineSource.cell(x: 13, y: 0))
            case "N": .glyph(mineSource.cell(x: 14, y: 0))
            case "O": .glyph(mineSource.cell(x: 15, y: 0))
            case "P": .glyph(mineSource.cell(x: 16, y: 0))
            case "Q": .glyph(mineSource.cell(x: 17, y: 0))
            case "R": .glyph(mineSource.cell(x: 18, y: 0))
            case "S": .glyph(mineSource.cell(x: 19, y: 0))
            case "T": .glyph(mineSource.cell(x: 20, y: 0))
            case "U": .glyph(mineSource.cell(x: 21, y: 0))
            case "V": .glyph(mineSource.cell(x: 22, y: 0))
            case "W": .glyph(mineSource.cell(x: 23, y: 0))
            case "X": .glyph(mineSource.cell(x: 24, y: 0))
            case "Y": .glyph(mineSource.cell(x: 25, y: 0))
            case "Z": .glyph(mineSource.cell(x: 26, y: 0))

            case "a": .glyph(mineSource.cell(x: 27, y: 0))
            case "b": .glyph(mineSource.cell(x: 28, y: 0))
            case "c": .glyph(mineSource.cell(x: 29, y: 0))
            case "d": .glyph(mineSource.cell(x: 30, y: 0))
            case "e": .glyph(mineSource.cell(x: 31, y: 0))
            case "f": .glyph(mineSource.cell(x: 32, y: 0).resize(left: -1))
            case "g": .glyph(mineSource.cell(x: 33, y: 0))
            case "h": .glyph(mineSource.cell(x: 34, y: 0))
            case "i": .glyph(mineSource.cell(x: 35, y: 0).resize(horizontal: -2))
            case "j": .glyph(mineSource.cell(x: 36, y: 0))
            case "k": .glyph(mineSource.cell(x: 37, y: 0).resize(left: -1))
            case "l": .glyph(mineSource.cell(x: 38, y: 0).resize(left: -1).resize(right: -2))
            case "m": .glyph(mineSource.cell(x: 39, y: 0))
            case "n": .glyph(mineSource.cell(x: 40, y: 0))
            case "o": .glyph(mineSource.cell(x: 41, y: 0))
            case "p": .glyph(mineSource.cell(x: 42, y: 0))
            case "q": .glyph(mineSource.cell(x: 43, y: 0))
            case "r": .glyph(mineSource.cell(x: 44, y: 0))
            case "s": .glyph(mineSource.cell(x: 45, y: 0))
            case "t": .glyph(mineSource.cell(x: 46, y: 0).resize(horizontal: -1))
            case "u": .glyph(mineSource.cell(x: 47, y: 0))
            case "v": .glyph(mineSource.cell(x: 48, y: 0))
            case "w": .glyph(mineSource.cell(x: 49, y: 0))
            case "x": .glyph(mineSource.cell(x: 50, y: 0))
            case "y": .glyph(mineSource.cell(x: 51, y: 0))
            case "z": .glyph(mineSource.cell(x: 52, y: 0))

            case "0": .glyph(mineSource.cell(x: 53, y: 0))
            case "1": .glyph(mineSource.cell(x: 54, y: 0))
            case "2": .glyph(mineSource.cell(x: 55, y: 0))
            case "3": .glyph(mineSource.cell(x: 56, y: 0))
            case "4": .glyph(mineSource.cell(x: 57, y: 0))
            case "5": .glyph(mineSource.cell(x: 58, y: 0))
            case "6": .glyph(mineSource.cell(x: 59, y: 0))
            case "7": .glyph(mineSource.cell(x: 60, y: 0))
            case "8": .glyph(mineSource.cell(x: 61, y: 0))
            case "9": .glyph(mineSource.cell(x: 62, y: 0))

            case ".":  .glyph(mineSource.cell(x: 63, y: 0).resize(horizontal: -2))
            case ",":  .glyph(mineSource.cell(x: 64, y: 0).resize(horizontal: -2))
            case ":":  .glyph(mineSource.cell(x: 65, y: 0).resize(horizontal: -2))
            case ";":  .glyph(mineSource.cell(x: 66, y: 0).resize(horizontal: -2))
            case "'":  .glyph(mineSource.cell(x: 67, y: 0).resize(horizontal: -2))
            case "\"": .glyph(mineSource.cell(x: 68, y: 0).resize(horizontal: -1))
            case "!":  .glyph(mineSource.cell(x: 69, y: 0).resize(horizontal: -2))
            case "?":  .glyph(mineSource.cell(x: 70, y: 0))

            case "#": .glyph(mineSource.cell(x: 71, y: 0))
            case "%": .glyph(mineSource.cell(x: 72, y: 0))
            case "&": .glyph(mineSource.cell(x: 73, y: 0))
            case "$": .glyph(mineSource.cell(x: 74, y: 0))
            case "(": .glyph(mineSource.cell(x: 75, y: 0).resize(horizontal: -1))
            case ")": .glyph(mineSource.cell(x: 76, y: 0).resize(horizontal: -1))

            case "*": .glyph(mineSource.cell(x: 77, y: 0).resize(horizontal: -1))
            case "-": .glyph(mineSource.cell(x: 78, y: 0).resize(horizontal: -1))
            case "+": .glyph(mineSource.cell(x: 79, y: 0).resize(horizontal: -1))
            case "×": .glyph(mineSource.cell(x: 80, y: 0).resize(horizontal: -1))
            case "÷": .glyph(mineSource.cell(x: 81, y: 0).resize(horizontal: -1))

            case "<": .glyph(mineSource.cell(x: 82, y: 0).resize(left: -1))
            case ">": .glyph(mineSource.cell(x: 83, y: 0).resize(right: -1))
            case "=": .glyph(mineSource.cell(x: 84, y: 0).resize(horizontal: -1))

            case "_": .glyph(mineSource.cell(x: 85, y: 0))
            case "[": .glyph(mineSource.cell(x: 86, y: 0).resize(horizontal: -1))
            case "]": .glyph(mineSource.cell(x: 87, y: 0).resize(horizontal: -1))

            case "/":  .glyph(mineSource.cell(x: 88, y: 0))
            case "\\": .glyph(mineSource.cell(x: 89, y: 0))

            case "^": .glyph(mineSource.cell(x: 90, y: 0))
            case "±": .glyph(mineSource.cell(x: 91, y: 0).resize(horizontal: 1))

            case "@": .glyph(mineSource.cell(x: 92, y: 0))
            case "|": .glyph(mineSource.cell(x: 93, y: 0).resize(horizontal: -2))
            case "{": .glyph(mineSource.cell(x: 94, y: 0).resize(horizontal: -1))
            case "}": .glyph(mineSource.cell(x: 95, y: 0).resize(horizontal: -1))

            case "~": .glyph(mineSource.cell(x: 96, y: 0).resize(right: 1))

            case "§": .glyph(mineSource.cell(x: 98, y: 0))

            case "©": .glyph(mineSource.cell(x: 99,  y: 0).resize(right: 2))
            case "®": .glyph(mineSource.cell(x: 101, y: 0).resize(left: 2))
            case "™": .glyph(mineSource.cell(x: 102, y: 0).resize(right: 5).resize(left: -1))

            case "–": .glyph(mineSource.cell(x: 104, y: 0))
            case "¡": .glyph(mineSource.cell(x: 105, y: 0).resize(horizontal: -2))
            case "¿": .glyph(mineSource.cell(x: 106, y: 0))
            case "£": .glyph(mineSource.cell(x: 107, y: 0))
            case "¥": .glyph(mineSource.cell(x: 108, y: 0))
            case "¢": .glyph(mineSource.cell(x: 109, y: 0))
            case "…": .glyph(mineSource.cell(x: 110, y: 0))

            case "·": .glyph(mineSource.cell(x: 111, y: 0).resize(horizontal: -2))
            case "—": .glyph(mineSource.cell(x: 112, y: 0).resize(horizontal: 2))

            case "°": .glyph(mineSource.cell(x: 114, y: 0).resize(right: -1))

            case _: .glyph(mineSource.cell(x: 0, y: 0))
        }
    }
}
