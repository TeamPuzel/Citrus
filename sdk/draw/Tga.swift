
@_eagerMove
public struct TgaImage: SizedPlane {
    private var data: [UInt8]

    private var span: RawSpan { unsafe data.span.bytes }

    public var width: Int { Int(unsafe span.unsafeLoad(fromByteOffset: 12, as: UInt16.self)) }
    public var height: Int { Int(unsafe span.unsafeLoad(fromByteOffset: 14, as: UInt16.self)) }

    public init(from data: [UInt8]) {
        self.data = data
    }

    public subscript(x: Int, y: Int) -> Color {
        get {
            if x >= 0 && y >= 0 && x < width && y < height {
                let index = (x + y * width) * 4
                let (b, g, r, a) = unsafe (
                    b: span.unsafeLoad(fromByteOffset: 18 + index + 0, as: UInt8.self),
                    g: span.unsafeLoad(fromByteOffset: 18 + index + 1, as: UInt8.self),
                    r: span.unsafeLoad(fromByteOffset: 18 + index + 2, as: UInt8.self),
                    a: span.unsafeLoad(fromByteOffset: 18 + index + 3, as: UInt8.self)
                )
                then .init(r: r, g: g, b: b, a: a)
            } else {
                .clear
            }
        }
    }
}
