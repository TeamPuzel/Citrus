
public struct Font<Source> where Source: Plane, Source: ~Copyable {
    public var height, baseline, spacing, leading: Int
    public var map: SymbolMap

    public init(height: Int, baseline: Int, spacing: Int, leading: Int, map: @escaping SymbolMap) {
        (self.height, self.baseline, self.spacing, self.leading) = (height, baseline, spacing, leading)
        self.map = map
    }

    public subscript(character: Character) -> Symbol {
        borrowing get { map(character) }
    }

    public typealias SymbolMap = @Sendable (_ character: Character) -> Symbol

    public enum Symbol: ~Copyable {
        case glyph(PlaneSlice<Source>)
        case space(width: Int)

        public var width: Int {
            switch self {
                case .glyph(let slice): slice.width
                case .space(let width): width
            }
        }
    }
}

extension Font: Sendable where Source: Sendable {}

extension Font.Symbol: Sendable where Source: Sendable {}

public struct Text<FontSource>: SizedPlane, ~Copyable where FontSource: Plane, FontSource: ~Copyable {
    public let content: String
    public let font: Font<FontSource>
    public let color: Color

    public let width: Int
    public var height: Int { font.height }

    // TODO: A more elaborate lazy solution using interior mutability.
    private let cache: Image

    public init(_ content: String, font: consuming Font<FontSource>, color: Color = .white) {
        self.content = content
        self.color = color
        let width = content.reduce(-font.spacing) { acc, char in acc + font[char].width + font.spacing }

        var cache = Image(width: width, height: font.height)
        var cursor = 0

        for character in content {
            switch font[character] {
                case .glyph(let slice):
                    // We copy width for later rather than borrow the slice as that causes Swift
                    // to crash during compilation at the moment.
                    let width = slice.width
                    cache.draw(slice.map(.white, to: color), x: cursor, y: 0, blender: .overwrite)
                    cursor += width + font.spacing
                case .space(let width):
                    cursor += width
            }
        }

        self.width = width
        self.font = font
        self.cache = cache
    }

    public subscript(x: Int, y: Int) -> Color { cache[x, y] }
}

extension Text: Copyable where FontSource: Copyable {}
extension Text: Sendable where FontSource: Sendable {}
