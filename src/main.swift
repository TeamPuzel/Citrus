
import Citrus
import Draw

@main
struct Game: Application {
    let sheet = TgaImage(from: resource(path: "tiles.tga"))
        .flatten()
        .grid(cellWidth: 32, cellHeight: 48)

    var (x, y) = (16, 16)

    mutating func update(with input: borrowing Input) {
        if input.keys(heldAnyOf: .left)  { x -= 1 }
        if input.keys(heldAnyOf: .right) { x += 1 }
        if input.keys(heldAnyOf: .up)    { y -= 1 }
        if input.keys(heldAnyOf: .down)  { y += 1 }
    }

    func draw(with input: borrowing Input, into target: inout Renderer) {
        var top = target.top.inout.mozaic(scale: 2)
        top.clear(with: .Pico.darkBlue)

        top.draw(sheet.cell(x: 1, y: 0), x: x, y: y)

        var bottom = target.bottom.inout.mozaic(scale: 2)
        bottom.clear(with: .Pico.darkBlue)

        bottom.draw(Text("Hello, Unicode™", font: .mine), x: 2, y: 2)
    }
}
