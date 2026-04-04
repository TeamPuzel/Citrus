
public struct Color: Equatable, BitwiseCopyable, Sendable {
    public var r, g, b, a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        (self.r, self.g, self.b, self.a) = (r, g, b, a)
    }

    public init(gray: UInt8, alpha: UInt8 = 255) {
        self.init(r: gray, g: gray, b: gray, a: alpha)
    }

    public func with(r: UInt8? = nil, g: UInt8? = nil, b: UInt8? = nil, a: UInt8? = nil) -> Color {
        .init(r: r ?? self.r, g: g ?? self.g, b: b ?? self.b, a: a ?? self.a)
    }
}

public protocol Palette {
    static var count: Int { get }
    static subscript(index: Int) -> Color { get }
}

extension Palette {
     public static func makeIterator() -> PaletteIterator<Self> { .init() }
     public static func random() -> Color { self[.random(in: 0...count - 1)] }
}

public struct PaletteIterator<P: Palette>: Sequence, IteratorProtocol {
    public typealias Element = Color

    private var index = 0

    public mutating func next() -> Color? {
        if index < P.count {
            let ret = P[index]
            index += 1
            return ret
        } else {
            return nil
        }
    }
}

extension Color {
    public static let clear = Self(gray: 0, alpha: 0)
    public static let white = Self(gray: 255)
    public static let black = Self(gray: 0)

    /// My personal color palette.
    public enum Strawberry: Palette {
        public static let strawberry = Color(r: 214, g: 95,  b: 118)
        public static let banana     = Color(r: 230, g: 192, b: 130)
        public static let apple      = Color(r: 205, g: 220, b: 146)
        public static let lime       = Color(r: 177, g: 219, b: 159)
        public static let blueberry  = Color(r: 129, g: 171, b: 201)
        public static let lemon      = Color(r: 240, g: 202, b: 101)
        public static let orange     = Color(r: 227, g: 140, b: 113)

        public static let white = Color(r: 224, g: 224, b: 224)
        public static let light = Color(r: 128, g: 128, b: 128)
        public static let gray  = Color(r: 59,  g: 59,  b: 59 )
        public static let dark  = Color(r: 28,  g: 28,  b: 28 )
        public static let black = Color(r: 15,  g: 15,  b: 15 )

        public static let count = 12

        public static subscript(index: Int) -> Color {
            switch index {
                case 0:  strawberry
                case 1:  banana
                case 2:  apple
                case 3:  lime
                case 4:  blueberry
                case 5:  lemon
                case 6:  orange

                case 7:  white
                case 8:  light
                case 9:  gray
                case 10: dark
                case 11: black

                case _: fatalError()
            }
        }
    }

    /// The Pico-8 color palette.
    public enum Pico: Palette {
        public static let black      = Color(r: 0,   g: 0,   b: 0  )
        public static let darkBlue   = Color(r: 29,  g: 43,  b: 83 )
        public static let darkPurple = Color(r: 126, g: 37,  b: 83 )
        public static let darkGreen  = Color(r: 0,   g: 135, b: 81 )
        public static let brown      = Color(r: 171, g: 82,  b: 53 )
        public static let darkGray   = Color(r: 95,  g: 87,  b: 79 )
        public static let lightGray  = Color(r: 194, g: 195, b: 199)
        public static let white      = Color(r: 255, g: 241, b: 232)
        public static let red        = Color(r: 255, g: 0,   b: 77 )
        public static let orange     = Color(r: 255, g: 163, b: 0  )
        public static let yellow     = Color(r: 255, g: 236, b: 39 )
        public static let green      = Color(r: 0,   g: 228, b: 54 )
        public static let blue       = Color(r: 41,  g: 173, b: 255)
        public static let lavender   = Color(r: 131, g: 118, b: 156)
        public static let pink       = Color(r: 255, g: 119, b: 168)
        public static let peach      = Color(r: 255, g: 204, b: 170)

        public static let count = 16

        public static subscript(index: Int) -> Color {
            switch index {
                case 0:  black
                case 1:  darkBlue
                case 2:  darkPurple
                case 3:  darkGreen
                case 4:  brown
                case 5:  darkGray
                case 6:  lightGray
                case 7:  white
                case 8:  red
                case 9:  orange
                case 10: yellow
                case 11: green
                case 12: blue
                case 13: lavender
                case 14: pink
                case 15: peach

                case _: fatalError()
            }
        }
    }

    /// The Picotron color palette.
    public enum Picotron: Palette {
        public static var black:      Color { .Pico.black      }
        public static var darkBlue:   Color { .Pico.darkBlue   }
        public static var darkPurple: Color { .Pico.darkPurple }
        public static var darkGreen:  Color { .Pico.darkGreen  }
        public static var brown:      Color { .Pico.brown      }
        public static var darkGray:   Color { .Pico.darkGray   }
        public static var lightGray:  Color { .Pico.lightGray  }
        public static var white:      Color { .Pico.white      }
        public static var red:        Color { .Pico.red        }
        public static var orange:     Color { .Pico.orange     }
        public static var yellow:     Color { .Pico.yellow     }
        public static var green:      Color { .Pico.green      }
        public static var lightBlue:  Color { .Pico.blue       }
        public static var lavender:   Color { .Pico.lavender   }
        public static var pink:       Color { .Pico.pink       }
        public static var peach:      Color { .Pico.peach      }

        public static let blue        = Color(r: 48,  g: 93,  b: 166)
        public static let teal        = Color(r: 73,  g: 162, b: 160)
        public static let violet      = Color(r: 111, g: 80,  b: 147)
        public static let darkTeal    = Color(r: 32,  g: 82,  b: 88 )
        public static let darkBrown   = Color(r: 108, g: 51,  b: 44 )
        public static let umber       = Color(r: 69,  g: 46,  b: 56 )
        public static let gray        = Color(r: 158, g: 137, b: 123)
        public static let lightPink   = Color(r: 243, g: 176, b: 196)
        public static let crimson     = Color(r: 179, g: 37,  b: 77 )
        public static let darkOrange  = Color(r: 219, g: 114, b: 44 )
        public static let lime        = Color(r: 165, g: 234, b: 95 )
        public static let darkLime    = Color(r: 79,  g: 175, b: 92 )
        public static let sky         = Color(r: 133, g: 220, b: 243)
        public static let lightViolet = Color(r: 183, g: 155, b: 218)
        public static let magenta     = Color(r: 208, g: 48,  b: 167)
        public static let darkPeach   = Color(r: 239, g: 139, b: 116)

        public static let count = 32

        public static subscript(index: Int) -> Color {
            switch index {
                case 0:  black
                case 1:  darkBlue
                case 2:  darkPurple
                case 3:  darkGreen
                case 4:  brown
                case 5:  darkGray
                case 6:  lightGray
                case 7:  white
                case 8:  red
                case 9:  orange
                case 10: yellow
                case 11: green
                case 12: lightBlue
                case 13: lavender
                case 14: pink
                case 15: peach

                case 16: blue
                case 17: teal
                case 18: violet
                case 19: darkTeal
                case 20: darkBrown
                case 21: umber
                case 22: gray
                case 23: lightPink
                case 24: crimson
                case 25: darkOrange
                case 26: lime
                case 27: darkLime
                case 28: sky
                case 29: lightViolet
                case 30: magenta
                case 31: darkPeach

                case _: fatalError()
            }
        }
    }

    // A palette imitating the GameBoy screen.
    public enum GameBoy: Palette {
        public static let black = Color(r: 15,  g: 56,  b: 15)
        public static let dark  = Color(r: 48,  g: 98,  b: 48)
        public static let light = Color(r: 139, g: 172, b: 15)
        public static let white = Color(r: 160, g: 210, b: 48)

        public static let count = 4

        public static subscript(index: Int) -> Color {
            switch index {
                case 0: black
                case 1: dark
                case 2: light
                case 3: white

                case _: fatalError()
            }
        }
    }
}

/// A nominal type wrapping a blending function. This allows easy namespaced (and inferred) usage
/// which would not be possible with a typealias. The idea is to extend this type to add constant instances.
public struct ColorBlender: Sendable {
    private let blendFunction: BlendFunction

    public init(using function: @escaping BlendFunction) {
        self.blendFunction = function
    }

    public func blend(top: Color, bottom: Color) -> Color {
        blendFunction(top, bottom)
    }

    public typealias BlendFunction = @Sendable (_ top: Color, _ bottom: Color) -> Color
}

extension ColorBlender {
    /// A simple blending function which does not do any blending but blindly overwrites the bottom color.
    public static let overwrite = Self { top, bottom in top }

    /// A simple blending function which overwrites the bottom color only if the top color is fully opaque.
    public static let binary = Self { top, bottom in top.a == 255 ? top : bottom }

    /// A relatively complex blending function which performs integer-space alpha blending.
    ///
    /// Note that this style of blending does not work well with plane composition. Alpha blending performs
    /// division which makes composition non-associative. For this reason this is not the default style of blending.
    public static let normal = Self { top, bottom in
        let bottom: (r: Int, g: Int, b: Int, a: Int) =
            (r: Int(bottom.r), g: Int(bottom.g), b: Int(bottom.b), a: Int(bottom.a))
        let top: (r: Int, g: Int, b: Int, a: Int) =
            (r: Int(top.r), g: Int(top.g), b: Int(top.b), a: Int(top.a))
        let invA = 255 - bottom.a

        return Color(
            r: UInt8((bottom.r * bottom.a + top.r * invA) / 255),
            g: UInt8((bottom.g * bottom.a + top.g * invA) / 255),
            b: UInt8((bottom.b * bottom.a + top.b * invA) / 255),
            a: UInt8((bottom.a + (top.a * invA) / 255))
        )
    }
}

extension Color {
    /// Perform blending with self as the bottom color.
    public func blend(under other: Self, with blender: ColorBlender) -> Self {
        blender.blend(top: other, bottom: self)
    }

    /// Perform blending with self as the top color.
    public func blend(over other: Self, with blender: ColorBlender) -> Self {
        blender.blend(top: self, bottom: other)
    }
}

/// A plane is the fundamental graphics primitive, an infinite pixel space.
///
/// Planes have several laws associated with them, most importantly that all access is fault tolerant.
/// Writing or reading out of bounds for example should do something semantically relevant to the concrete plane,
/// perhaps discarding the value or returning a default. Graphics can be programmed very freely this way since
/// we need not concern ourselves with the program crashing. If safety is critical one should use a special
/// plane which guards against failure, but that should be a rare use case.
public protocol Plane: ~Copyable, ~Escapable {
    subscript(x: Int, y: Int) -> Color { borrowing get }
}

/// A sized plane is a refinement which specifies an extent directed towards positive x and y.
///
/// It is a soft extent, for example a slice of an infinite mutable plane should still forward "out of bounds" access.
/// If that is not desirable a wrapper plane should be used which adds such a constraint.
/// The purpose of sized planes is to reason about parts of infinite pixel space in a finite amount of time.
/// It would be impossible to clear an infinite plane, but one can absolutely clear a sized slice within.
public protocol SizedPlane: Plane, ~Copyable, ~Escapable {
    var width: Int { borrowing get }
    var height: Int { borrowing get }
}

/// A refinement of planes which allows mutation.
///
/// Technically it would be valid to just make all planes mutable and have those incapable of preserving such
/// operations discard the writes, however it is helpful to reason about this in the type system. A distinct
/// category for mutation allows rejecting code which would not do anything useful. Some more abstract
/// planes might consider allowing discarded mutation if there is a use case for it.
public protocol MutablePlane: Plane, ~Copyable, ~Escapable {
    subscript(x: Int, y: Int) -> Color { borrowing get mutating set }
}

/// A special kind of plane, a root node of sorts. Allows flattening planes into itself.
public protocol PrimitivePlane: SizedPlane, ~Copyable, ~Escapable {
    @_lifetime(copy plane)
    init(flattening plane: borrowing some SizedPlane & ~Copyable & ~Escapable)
}

public typealias SizedMutablePlane = SizedPlane & MutablePlane

extension SizedPlane where Self: ~Copyable, Self: ~Escapable {
    /// Shorthand for flattening a plane into a primitive image, for
    /// cases where allocating the memory and losing information is preferable to repeatedly recomputing all layers.
    ///
    /// This method is a convenience and overloads the generic version of this function in cases where
    /// an explicit type is not provided, since an `Image` is the most basic of planes.
    /// Notably however it is not the most primitive, that title goes to the `InfiniteImage` which satisfies the
    /// entirety of the most pure definition one could come up with for all plane semantics, a true infinite space.
    /// Obviously though our primitiveness is constrained to sized constructs as we can't flatten into an
    /// infinite space in a finite amount of time.
    ///
    /// It is the equivalent of calling `.flatten(into: Image.self)`.
    @_disfavoredOverload public borrowing func flatten() -> Image { .init(flattening: self) }
    /// Shorthand for flattening planes into a primitive.
    ///
    /// This overload allows specifying the type in the middle of a method chain.
    public borrowing func flatten<T>(into type: T.Type) -> T where T: PrimitivePlane { .init(flattening: self) }
    /// Shorthand for flattening planes into a primitive.
    ///
    /// This overload is used when inferring the return type.
    public borrowing func flatten<T>() -> T where T: PrimitivePlane { .init(flattening: self) }
}

public enum Origin {
    case topLeft, topRight, bottomLeft, bottomRight
    case left, right, top, bottom
    case center

    @_transparent @const
    public func offset(for plane: borrowing some SizedPlane & ~Copyable & ~Escapable) -> (x: Int, y: Int) {
        switch self {
            case .topLeft:     (0,               0               )
            case .topRight:    (plane.width - 1, 0               )
            case .bottomLeft:  (0,               plane.height - 1)
            case .bottomRight: (plane.width - 1, plane.height - 1)
            case .left:        (0,               plane.height / 2)
            case .right:       (plane.width - 1, plane.height / 2)
            case .top:         (plane.width / 2, 0               )
            case .bottom:      (plane.width / 2, plane.height - 1)
            case .center:      (plane.width / 2, plane.height / 2)
        }
    }
}

extension MutablePlane where Self: ~Copyable, Self: ~Escapable {
    public mutating func pixel(_ color: Color, x: Int, y: Int, blender: ColorBlender = .binary) {
        self[x, y] = self[x, y].blend(under: color, with: blender)
    }

    public mutating func clear(with color: Color = .clear, blender: ColorBlender = .overwrite) where Self: SizedPlane {
        for x in 0..<self.width {
            for y in 0..<self.height {
                self.pixel(color, x: x, y: y, blender: blender)
            }
        }
    }

    public mutating func draw(
        _ plane: borrowing some SizedPlane & ~Copyable & ~Escapable,
        x: Int, y: Int,
        blender: ColorBlender = .binary
    ) {
        for ix in 0..<plane.width {
            for iy in 0..<plane.height {
                self.pixel(plane[ix, iy], x: ix + x, y: iy + y, blender: blender)
            }
        }
    }

    @_transparent
    public mutating func draw(
        _ plane: borrowing some SizedPlane & ~Copyable & ~Escapable, blender: ColorBlender = .binary
    ) {
        self.draw(plane, x: 0, y: 0, blender: blender)
    }

    @_transparent
    public mutating func draw(
        _ plane: borrowing some SizedPlane & ~Copyable & ~Escapable,
        from sourceOrigin: Origin = .topLeft, at destinationOrigin: Origin,
        blender: ColorBlender = .binary
    ) where Self: SizedPlane {
        let (x, y) = destinationOrigin.offset(for: self)
        let offset = sourceOrigin.offset(for: plane)
        self.draw(plane, x: x - offset.x, y: y - offset.y, blender: blender)
    }

    @_transparent
    public mutating func draw(
        _ plane: borrowing some SizedPlane & ~Copyable & ~Escapable,
        aligning origin: Origin = .topLeft,
        blender: ColorBlender = .binary
    ) where Self: SizedPlane {
        self.draw(plane, from: origin, at: origin, blender: blender)
    }
}

extension Plane where Self: ~Copyable {
    public var borrow: Borrow<Self> { Borrow(self) }
    public var `inout`: Inout<Self> { mutating get { Inout(&self) } }
}

extension Borrow: Plane where Value: Plane, Value: ~Copyable {
    public subscript(x: Int, y: Int) -> Color { value[x, y] }
}

extension Borrow: SizedPlane where Value: SizedPlane, Value: ~Copyable {
    public var width: Int { value.width }
    public var height: Int { value.height }
}

extension Inout: Plane where Value: Plane, Value: ~Copyable {
    public subscript(x: Int, y: Int) -> Color { value[x, y] }
}

extension Inout: MutablePlane where Value: MutablePlane, Value: ~Copyable {
    public subscript(x: Int, y: Int) -> Color {
        get { value[x, y] }
        set { value[x, y] = newValue }
    }
}

extension Inout: SizedPlane where Value: SizedPlane, Value: ~Copyable {
    public var width: Int { value.width }
    public var height: Int { value.height }
}

public struct PlaneSlice<Inner>: SizedPlane, ~Copyable, ~Escapable
where
    Inner: Plane, Inner: ~Copyable, Inner: ~Escapable
{
    public var inner: Inner
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(of inner: consuming Inner, x: Int, y: Int, width: Int, height: Int) {
        self.inner = inner
        (self.x, self.y, self.width, self.height) = (x, y, width, height)
    }

    public subscript(x: Int, y: Int) -> Color {
        inner[x + self.x, y + self.y]
    }

    public consuming func resize(left offset: Int) -> Self {
        .init(of: inner, x: x - offset, y: y, width: max(0, width + offset), height: height)
    }

    public consuming func resize(right offset: Int) -> Self {
        .init(of: inner, x: x, y: y, width: max(0, width + offset), height: height)
    }

    public consuming func resize(top offset: Int) -> Self {
        .init(of: inner, x: x, y: y - offset, width: width, height: max(0, height + offset))
    }

    public consuming func resize(bottom offset: Int) -> Self {
        .init(of: inner, x: x, y: y, width: width, height: max(0, height + offset))
    }

    public consuming func resize(horizontal offset: Int) -> Self {
        .init(of: inner, x: x - offset, y: y, width: max(0, width + offset * 2), height: height)
    }

    public consuming func resize(vertical offset: Int) -> Self {
        .init(of: inner, x: x, y: y - offset, width: width, height: max(0, height + offset * 2))
    }

    public consuming func resize(all offset: Int) -> Self {
        resize(vertical: offset).resize(horizontal: offset)
    }

    public consuming func shifted(x: Int, y: Int) -> Self {
        .init(of: inner, x: x + self.x, y: y + self.x, width: width, height: height)
    }
}

extension PlaneSlice: MutablePlane where Inner: MutablePlane, Inner: ~Copyable, Inner: ~Escapable {
    public subscript(x: Int, y: Int) -> Color {
        get { inner[x + self.x, y + self.x] }
        set { inner[x + self.x, y + self.x] = newValue }
    }
}

extension PlaneSlice: Escapable where Inner: ~Copyable, Inner: Escapable {}
extension PlaneSlice: Copyable where Inner: Copyable, Inner: ~Escapable {}
extension PlaneSlice: Sendable where Inner: Sendable {}

extension Plane where Self: ~Copyable, Self: ~Escapable {
    public consuming func slice(x: Int, y: Int, width: Int, height: Int) -> PlaneSlice<Self> {
        .init(of: self, x: x, y: y, width: width, height: height)
    }
}

extension SizedPlane where Self: ~Copyable, Self: ~Escapable {
    public consuming func slice() -> PlaneSlice<Self> {
        .init(of: self, x: 0, y: 0, width: width, height: height)
    }

    @_transparent
    public consuming func resize(left offset: Int) -> PlaneSlice<Self> {
        slice().resize(left: offset)
    }

    @_transparent
    public consuming func resize(right offset: Int) -> PlaneSlice<Self> {
        slice().resize(right: offset)
    }

    @_transparent
    public consuming func resize(top offset: Int) -> PlaneSlice<Self> {
        slice().resize(top: offset)
    }

    @_transparent
    public consuming func resize(bottom offset: Int) -> PlaneSlice<Self> {
        slice().resize(bottom: offset)
    }

    @_transparent
    public consuming func resize(horizontal offset: Int) -> PlaneSlice<Self> {
        slice().resize(horizontal: offset)
    }

    @_transparent
    public consuming func resize(vertical offset: Int) -> PlaneSlice<Self> {
        slice().resize(vertical: offset)
    }

    @_transparent
    public consuming func resize(all offset: Int) -> PlaneSlice<Self> {
        slice().resize(all: offset)
    }

    @_transparent
    public consuming func shifted(x: Int, y: Int) -> PlaneSlice<Self> {
        slice().shifted(x: x, y: y)
    }
}

public struct PlaneGrid<Inner>: ~Copyable where Inner: Plane, Inner: ~Copyable {
    public var inner: Inner
    public let cellWidth: Int
    public let cellHeight: Int

    public init(of inner: consuming Inner, cellWidth: Int, cellHeight: Int) {
        self.inner = inner
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
    }

    @_lifetime(borrow self)
    public func cell(x: Int, y: Int) -> PlaneSlice<Borrow<Inner>> {
        inner.borrow.slice(x: x * cellWidth, y: y * cellHeight, width: cellWidth, height: cellHeight)
    }

    @_lifetime(&self)
    @_disfavoredOverload
    public mutating func cell(x: Int, y: Int) -> PlaneSlice<Inout<Inner>> {
        inner.inout.slice(x: x * cellWidth, y: y * cellHeight, width: cellWidth, height: cellHeight)
    }

    @_disfavoredOverload
    public consuming func cell(x: Int, y: Int) -> PlaneSlice<Inner> {
        inner.slice(x: x * cellWidth, y: y * cellHeight, width: cellWidth, height: cellHeight)
    }
}

extension PlaneGrid: Copyable where Inner: Copyable {}
extension PlaneGrid: Sendable where Inner: Sendable {}

extension Plane where Self: ~Copyable {
    public consuming func grid(cellWidth: Int, cellHeight: Int) -> PlaneGrid<Self> {
        .init(of: self, cellWidth: cellWidth, cellHeight: cellHeight)
    }
}

/// An inversly scaled plane. Viewing a plane through a mozaic makes it seem smaller by the scale value,
/// and the sampling becomes sparse and truncated. Writing sets entire chunks of pixels.
///
/// A mozaic can be used as an interestic graphical effect or a quick way to draw at a lower resolution.
public struct MozaicPlane<Inner>: Plane, ~Copyable, ~Escapable where Inner: Plane, Inner: ~Copyable, Inner: ~Escapable {
    public var inner: Inner
    public var scale: Int

    public init(of inner: consuming Inner, scale: Int) {
        precondition(scale > 0)
        self.inner = inner
        self.scale = scale
    }

    public subscript(x: Int, y: Int) -> Color {
        inner[x * scale, y * scale]
    }
}

extension MozaicPlane: MutablePlane where Inner: MutablePlane, Inner: ~Copyable, Inner: ~Escapable {
    public subscript(x: Int, y: Int) -> Color {
        get { inner[x * scale, y * scale] }
        set {
            for sx in 0..<scale {
                for sy in 0..<scale {
                    inner[x * scale + sx, y * scale + sy] = newValue
                }
            }
        }
    }
}

extension MozaicPlane: SizedPlane where Inner: SizedPlane, Inner: ~Copyable, Inner: ~Escapable {
    public var width: Int { inner.width / scale }
    public var height: Int { inner.height / scale }
}

extension MozaicPlane: Escapable where Inner: ~Copyable, Inner: Escapable {}
extension MozaicPlane: Copyable where Inner: Copyable, Inner: ~Escapable {}
extension MozaicPlane: Sendable where Inner: Sendable {}

extension Plane where Self: ~Copyable, Self: ~Escapable {
    public consuming func mozaic(scale: Int) -> MozaicPlane<Self> { .init(of: self, scale: scale) }
}

/// A plane scaled up by a specific value. Draw operations are fairly lossy and have to be truncated.
public struct ScaledPlane<Inner>: Plane, ~Copyable, ~Escapable where Inner: Plane, Inner: ~Copyable, Inner: ~Escapable {
    public var inner: Inner
    public var scale: Int

    public init(of inner: consuming Inner, by scale: Int) {
        precondition(scale > 0)
        self.inner = inner
        self.scale = scale
    }

    public subscript(x: Int, y: Int) -> Color {
        inner[x / scale, y / scale]
    }
}

extension ScaledPlane: MutablePlane where Inner: MutablePlane, Inner: ~Copyable, Inner: ~Escapable {
    public subscript(x: Int, y: Int) -> Color {
        get { inner[x / scale, y / scale] }
        set { inner[x / scale, y / scale] = newValue }
    }
}

extension ScaledPlane: SizedPlane where Inner: SizedPlane, Inner: ~Copyable, Inner: ~Escapable {
    public var width: Int { inner.width * scale }
    public var height: Int { inner.height * scale }
}

extension ScaledPlane: Escapable where Inner: ~Copyable, Inner: Escapable {}
extension ScaledPlane: Copyable where Inner: Copyable, Inner: ~Escapable {}
extension ScaledPlane: Sendable where Inner: Sendable {}

extension Plane where Self: ~Copyable, Self: ~Escapable {
    public consuming func scaled(by scale: Int) -> ScaledPlane<Self> { .init(of: self, by: scale) }
}

public struct PlaneMap<Inner>: Plane, ~Copyable, ~Escapable where Inner: Plane, Inner: ~Copyable, Inner: ~Escapable {
    public var inner: Inner
    public var transform: Transform

    public init(of inner: consuming Inner, transform: @escaping Transform) {
        self.inner = inner
        self.transform = transform
    }

    public subscript(x: Int, y: Int) -> Color { transform(inner[x, y], x, y) }

    public typealias Transform = @Sendable (_ color: Color, _ x: Int, _ y: Int) -> Color
    public typealias SimpleTransform = @Sendable (_ color: Color) -> Color
}

extension PlaneMap: SizedPlane where Inner: SizedPlane, Inner: ~Copyable, Inner: ~Escapable {
    public var width: Int { inner.width }
    public var height: Int { inner.height }
}

extension PlaneMap: Escapable where Inner: ~Copyable, Inner: Escapable {}
extension PlaneMap: Copyable where Inner: Copyable, Inner: ~Escapable {}
extension PlaneMap: Sendable where Inner: Sendable {}

extension Plane where Self: ~Copyable, Self: ~Escapable {
    /// Lazily map color on access.
    consuming func map(_ transform: @escaping PlaneMap.Transform) -> PlaneMap<Self> {
        .init(of: self, transform: transform)
    }

    /// Lazily map color on access.
    consuming func map(_ transform: @escaping PlaneMap.SimpleTransform) -> PlaneMap<Self> {
        .init(of: self) { color, _, _ in transform(color) }
    }

    /// Shorthand for a simple color map from one color to another.
    consuming func map(_ match: Color, to new: Color) -> PlaneMap<Self> {
        self.map { $0 == match ? new : $0 }
    }

    /// Shorthand for a simple color map from all but one color to another.
    consuming func map(not match: Color, to new: Color) -> PlaneMap<Self> {
        self.map { $0 == match ? $0 : new }
    }

    /// Shorthand for a color map from a color matching a predicate to another.
    consuming func map(to new: Color, where predicate: @escaping @Sendable (_ color: Color) -> Bool) -> PlaneMap<Self> {
        self.map { predicate($0) ? new : $0 }
    }
}

/// An abstract, fully featured plane. It does not have any size nor does it do anything at all,
/// so it can be used anywhere as a no-op construct.
public struct VoidPlane: SizedMutablePlane, PrimitivePlane, Sendable {
    public init() {}

    public var width: Int { 0 }
    public var height: Int { 0 }

    public subscript(x: Int, y: Int) -> Color {
        get { .clear }
        set {}
    }

    public init(flattening plane: borrowing some SizedPlane & ~Copyable & ~Escapable) {}
}

@_eagerMove
public struct Image: SizedMutablePlane, PrimitivePlane, Sendable {
    private var data: [Color]
    public private(set) var width: Int
    public private(set) var height: Int

    public var span: Span<Color> { data.span.extracting(first: width * height) }

    public init(width: Int, height: Int, color: Color = .clear) {
        self.data = .init(repeating: color, count: width * height)
        self.width = width
        self.height = height
    }

    public init(width: Int, height: Int, initializingWith initializer: (_ x: Int, _ y: Int) -> Color) {
        self.data = unsafe .init(unsafeUninitializedCapacity: width * height) { buffer, initializedCount in
            for x in 0..<width {
                for y in 0..<height {
                    unsafe buffer[x + y * width] = initializer(x, y)
                    initializedCount += 1
                }
            }
        }
        self.width = width
        self.height = height
    }

    public mutating func resize(width: Int, height: Int) {
        if width == self.width && height <= self.height {
            // We can avoid reallocation in the trivial case where the stride does not change.
            self.height = height
        } else {
            self = .init(width: width, height: height) { x, y in self[x, y] }
        }
    }

    public mutating func shrinkToFit() {
        if data.count > width * height {
            self = .init(width: width, height: height) { x, y in self[x, y] }
        }
    }

    public subscript(x: Int, y: Int) -> Color {
        get { if x >= 0 && y >= 0 && x < width && y < height { data[x + y * width] } else { .clear } }
        set { if x >= 0 && y >= 0 && x < width && y < height { data[x + y * width] = newValue } }
    }

    public init(flattening plane: borrowing some SizedPlane & ~Copyable & ~Escapable) {
        self = .init(width: plane.width, height: plane.height) { x, y in plane[x, y] }
    }
}

/// An image but with inline storage.
///
/// This type is not implementable until const arithmetic is possible, since our storage is `width * height`.
/// It might technically be possible with some horrible macros but it's probably not worth it anyway.
@available(swift 9999)
public struct InlineImage<let width: Int, let height: Int>: SizedMutablePlane, PrimitivePlane, Sendable {
    public var width: Int { Self.width }
    public var height: Int { Self.height }

    private init(color: Color = .clear) { fatalError() }

    public subscript(x: Int, y: Int) -> Color {
        get { fatalError() }
        set { fatalError() }
    }

    public init(flattening plane: borrowing some SizedPlane & ~Copyable & ~Escapable) { fatalError() }
}
