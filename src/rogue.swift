
import Citrus
import Draw

/// The main game world state.
final class World: ParentableObject {
    let seed: UInt64
    var floors: [Floor] = []
    var primary: Entity!

    init(seed: UInt64 = .random(in: 1...(.max))) {
        self.seed = seed
        super.init()
        self.floors = (1...3).map { depth in .init(self, depth: depth) }
    }

    func update(with input: borrowing Input) {

    }

    func draw(with input: borrowing Input, into target: inout Renderer) {

    }
}

/// A proceduraly generated dungeon floor.
final class Floor: ParentableObject {
    @Parent var world: World
    var entities: Set<Entity> = []
    var tiles: [Tile] = []

    init(_ world: World, depth: Int) {
        self.world = world
    }
}

/// A tile which uses unique instances across the world.
class Tile {

}

/// A tile which reuses the same instance across the world.
class SharedTile: Tile {

}

/// A dynamic grid-independent game object.
class Entity: ParentableObject {
    @Parent var floor: Floor

    init(_ floor: Floor) {
        self.floor = floor
    }
}

extension Entity: Hashable {
    static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    final func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
