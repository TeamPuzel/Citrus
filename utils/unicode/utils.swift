
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

func readFile(_ path: String) -> String {
    guard let file = fopen(path, "rb") else {
        fatalError(.init(cString: strerror(errno)) + " where path = \(path)")
    }
    defer { fclose(file) }

    fseek(file, 0, SEEK_END)
    let size = unsafe ftell(file)
    rewind(file)

    guard size > 0 else { return "" }

    let bytes = unsafe Array<UInt8>(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        initializedCount = unsafe fread(buffer.baseAddress, 1, size, file)
    }

    // Convert to String (assumes UTF-8)
    return String(decoding: bytes, as: UTF8.self)
}

struct BitArray {
    var words: [UInt64]
    var size: UInt16

    init(size: Int) {
        self.words = .init(repeating: 0, count: (size + 63) / 64)
        self.size = UInt16(size)
    }

    subscript(bit: Int) -> Bool {
        get { words[bit / 64] & (1 << (bit % 64)) != 0 }
        set {
            if newValue {
                words[bit / 64] |= 1 << (bit % 64)
            } else {
                words[bit / 64] &= ~(1 << (bit % 64))
            }
        }
    }

    mutating func insert(_ bit: Int) -> Bool {
        let oldData = words[bit / 64]
        words[bit / 64] |= 1 << (bit % 64)
        return oldData & (1 << (bit % 64)) == 0
    }
}

struct Mph {
    private(set) var bitArrays: [BitArray] = []
    private(set) var ranks: [[UInt16]] = []

    init(for keys: [UInt64]) {
        self.init(gamma: 1, keys: keys)
    }

    init(gamma: Double, keys: [UInt64]) {
        var size: Int
        var a: BitArray
        var collide: Set<Int>
        var redoKeys: [UInt64] = keys
        var i: UInt64 = 0

        repeat {
            size = max(64, Int(gamma * Double(redoKeys.count)))
            a = BitArray(size: size)
            collide = []

            for key in redoKeys {
                let idx = Int(hash(UInt32(key), level: UInt32(size), seed: UInt32(i)))

                if !collide.contains(idx), !a.insert(idx) {
                    collide.insert(idx)
                }
            }

            var tmpRedo: [UInt64] = []

            for key in redoKeys {
                let idx = Int(hash(UInt32(key), level: UInt32(size), seed: UInt32(i)))

                if collide.contains(idx) {
                    a[idx] = false
                    tmpRedo.append(key)
                }
            }

            bitArrays.append(a)
            redoKeys = tmpRedo
            i += 1
        } while !redoKeys.isEmpty

        var pop: UInt16 = 0

        for bitArray in bitArrays {
            var rank: [UInt16] = []

            for i in 0..<bitArray.words.count {
                let v = bitArray.words[i]

                if i % 8 == 0 {
                    rank.append(pop)
                }

                pop += UInt16(v.nonzeroBitCount)
            }

            ranks.append(rank)
        }
    }

    func index(for key: UInt64) -> Int {
        for i in 0..<bitArrays.count {
            let b = bitArrays[i]
            let idx = Int(hash(UInt32(key), level: UInt32(b.size), seed: UInt32(i)))

            if b[idx] {
                var rank = ranks[i][idx / 512]

                for j in (idx / 64) & ~7 ..< idx / 64 {
                    rank += UInt16(b.words[j].nonzeroBitCount)
                }

                let finalWord = b.words[idx / 64]

                if idx % 64 > 0 {
                    rank += UInt16((finalWord << (64 - (idx % 64))).nonzeroBitCount)
                }

                return Int(rank)
            }
        }

        return -1
    }
}

func scramble(_ scalar: UInt32) -> UInt32 {
    var scalar = scalar
    scalar &*= 0xCC9E2D51
    scalar = (scalar << 15) | (scalar >> 17)
    scalar &*= 0x1B873593
    return scalar
}

func hash(_ scalar: UInt32, level: UInt32, seed: UInt32) -> UInt32 {
    var hash = seed

    hash ^= scramble(scalar)
    hash = (hash << 13) | (hash >> 19)
    hash = hash &* 5 &+ 0xE6546B64

    hash ^= scramble(level)
    hash = (hash << 13) | (hash >> 19)
    hash = hash &* 5 &+ 0xE6546B64

    hash ^= 8
    hash ^= hash >> 16
    hash ^= 0x85EBCA6B
    hash ^= hash >> 13
    hash ^= 0xC2B2AE35
    hash ^= hash >> 16

    return hash % level
}

fileprivate func _eytzingerize<C: Collection>(
    _ collection: C,
    result: inout [C.Element],
    sourceIndex: Int,
    resultIndex: Int
) -> Int where C.Element: Comparable, C.Index == Int {
    var sourceIndex = sourceIndex
    if resultIndex < result.count {
        sourceIndex = _eytzingerize(
            collection, result: &result, sourceIndex: sourceIndex, resultIndex: 2 * resultIndex)
        result[resultIndex] = collection[sourceIndex]
        sourceIndex = _eytzingerize(
            collection, result: &result, sourceIndex: sourceIndex + 1, resultIndex: 2 * resultIndex + 1)
    }
    return sourceIndex
}

/// Takes a sorted collection and reorders it to an array-encoded binary search tree, as originally
/// developed by Michaël Eytzinger in the 16th century. This allows binary searching the array later to touch
/// roughly 4x fewer cachelines, significantly speeding it up.
func eytzingerize<C: Collection>(_ collection: C, dummy: C.Element) -> [C.Element]
where C.Element: Comparable, C.Index == Int {
    var result = Array(repeating: dummy, count: collection.count + 1)
    _ = _eytzingerize(collection, result: &result, sourceIndex: 0, resultIndex: 1)
    return result
}

// Given a collection, format it into a string within 80 columns and fitting as
// many elements in a row as possible.
func formatCollection<C: Collection>(
    _ c: C,
    into result: inout String,
    using handler: (C.Element) -> String
) {
    // Our row length always starts at 2 for the initial indentation.
    var rowLength = 2

    for element in c {
        let string = handler(element)

        if rowLength == 2 {
            result += "    "
        }

        if rowLength + string.count + 1 > 100 {
            result += "\n    "
            rowLength = 2
        } else {
            result += rowLength == 2 ? "" : " "
        }

        result += "\(string),"

        // string.count + , + space
        rowLength += string.count + 1 + 1
    }
}

public func emitCollection<C: Collection>(
    _ collection: C,
    name: String,
    type: String,
    into result: inout String,
    formatter: (C.Element) -> String
) {
    result += """
        let \(name): InlineArray<\(collection.count), \(type)> = [

        """

    formatCollection(collection, into: &result, using: formatter)

    result += "\n]\n\n"
}

public func emitCollection<C: Collection>(
    _ collection: C,
    name: String,
    into result: inout String
) where C.Element: FixedWidthInteger {
    emitCollection(
        collection,
        name: name,
        type: "\(C.Element.isSigned ? "" : "U")Int\(C.Element.bitWidth)",
        into: &result
    ) {
        "0x\(String($0, radix: 16, uppercase: true))"
    }
}

// Emits an abstract minimal perfect hash function into C arrays.
func emitMph(_ mph: Mph, name: String, label: String, into result: inout String) {
    result += "@const let unicode\(label)LevelCount = \(mph.bitArrays.count)\n\n"
    emitMphSizes(mph, name, into: &result)
    emitMphBitArrays(mph, name, into: &result)
    emitMphRanks(mph, name, into: &result)
    emitMphValueOffsets(mph, name, into: &result)
}

// BitArray sizes
func emitMphSizes(_ mph: Mph, _ name: String, into result: inout String) {
    emitCollection(
        mph.bitArrays,
        name: "unicode\(name)Sizes",
        type: "UInt16",
        into: &result
    ) {
        "0x\(String($0.size, radix: 16, uppercase: true))"
    }
}

func emitMphBitArrays(_ mph: Mph, _ name: String, into result: inout String) {
    var flattenedKeys: [UInt64] = []
    var offsets: [UInt16] = [0]

    for ba in mph.bitArrays {
        flattenedKeys.append(contentsOf: ba.words)
        offsets.append(UInt16(flattenedKeys.count))
    }

    emitCollection(
        flattenedKeys,
        name: "unicode\(name)KeysData",
        into: &result
    )

    emitCollection(
        offsets,
        name: "unicode\(name)KeysOffsets",
        into: &result
    )
}

func emitMphRanks(_ mph: Mph, _ name: String, into result: inout String) {
    var flattenedRanks: [UInt16] = []
    var offsets: [UInt16] = [0]

    for rankList in mph.ranks {
        flattenedRanks.append(contentsOf: rankList)
        offsets.append(UInt16(flattenedRanks.count))
    }

    emitCollection(
        flattenedRanks,
        name: "unicode\(name)RanksData",
        into: &result
    )

    emitCollection(
        offsets,
        name: "unicode\(name)RanksOffsets",
        into: &result
    )
}

func emitMphValueOffsets(_ mph: Mph, _ name: String, into result: inout String) {
    var cumulative = 0
    var valueOffsets: [UInt32] = []

    for ba in mph.bitArrays {
        valueOffsets.append(UInt32(cumulative))
        // The MPH index is based on the number of set bits (rank)
        // so we count the 1s in each bitArray (level)
        cumulative += ba.words.reduce(0) { $0 + $1.nonzeroBitCount }
    }

    emitCollection(
        valueOffsets,
        name: "unicode\(name)ValueOffsets",
        into: &result
    )
}

// Takes an unflattened array of scalar ranges and some Equatable property and
// attempts to merge ranges who share the same Equatable property. E.g:
//
//     0x0 ... 0xA  = .control
//     0xB ... 0xB  = .control
//     0xC ... 0x1F = .control
//
//    into:
//
//    0x0 ... 0x1F = .control
func flatten<T: Equatable>(
    _ unflattened: [(ClosedRange<UInt32>, T)]
) -> [(ClosedRange<UInt32>, T)] {
    var result: [(ClosedRange<UInt32>, T)] = []

    for elt in unflattened.sorted(by: { $0.0.lowerBound < $1.0.lowerBound }) {
        guard !result.isEmpty, result.last!.1 == elt.1 else {
            result.append(elt)
            continue
        }

        if elt.0.lowerBound == result.last!.0.upperBound + 1 {
            result[result.count - 1].0 = result.last!.0.lowerBound ... elt.0.upperBound
        } else {
            result.append(elt)
        }
    }

    return result
}

func flatten(
    _ unflattened: [ClosedRange<UInt32>]
) -> [ClosedRange<UInt32>] {
    var result: [ClosedRange<UInt32>] = []

    for elt in unflattened.sorted(by: { $0.lowerBound < $1.lowerBound }) {
        guard !result.isEmpty else {
            result.append(elt)
            continue
        }

        if elt.lowerBound == result.last!.upperBound + 1 {
            result[result.count - 1] = result.last!.lowerBound ... elt.upperBound
        } else {
            result.append(elt)
        }
    }

    return result
}

// Takes an unflattened array of scalars and some Equatable property and
// attempts to merge scalars into ranges who share the same Equatable
// property. E.g:
//
//     0x9 = .control
//     0xA = .control
//     0xB = .control
//     0xC = .control
//
//    into:
//
//    0x9 ... 0xC = .control
func flatten<T: Equatable>(
    _ unflattened: [(UInt32, T)]
) -> [(ClosedRange<UInt32>, T)] {
    var result: [(ClosedRange<UInt32>, T)] = []

    for elt in unflattened.sorted(by: { $0.0 < $1.0 }) {
        guard !result.isEmpty, result.last!.1 == elt.1 else {
            result.append((elt.0 ... elt.0, elt.1))
            continue
        }

        if elt.0 == result.last!.0.upperBound + 1 {
            result[result.count - 1].0 = result.last!.0.lowerBound ... elt.0
        } else {
            result.append((elt.0 ... elt.0, elt.1))
        }
    }

    return result
}

// Given a string to the UnicodeData file, return the flattened list of scalar
// to Canonical Combining Class.
//
// Each line in this data file is formatted like the following:
//
//     0000;<control>;Cc;0;BN;;;;;N;NULL;;;;
//
// Where each section is split by a ';'. The first section informs us of the
// scalar in the line with the various properties. For the purposes of CCC data,
// we only need the 0 in between the Cc and BN (index 3) which is the raw value
// for the CCC.
func getCCCData(from data: String, with dict: inout [UInt32: UInt16]) {
    for line in data.split(separator: "\n") {
        let components = line.split(separator: ";", omittingEmptySubsequences: false)

        let ccc = UInt16(components[3])!

        // For the most part, CCC 0 is the default case, so we can save much more
        // space by not keeping this information and making it the fallback case.
        if ccc == 0 {
            continue
        }

        let scalarStr = components[0]
        let scalar = UInt32(scalarStr, radix: 16)!

        var newValue = dict[scalar, default: 0]

        // Store our ccc past the 3rd bit.
        newValue |= ccc << 3

        dict[scalar] = newValue
    }
}

// Given a string to the DerivedNormalizationProps Unicode file, return the
// flattened list of scalar to NFC Quick Check.
//
// Each line in one of these data files is formatted like the following:
//
//     0343..0344    ; NFC_QC; N # Mn   [2] COMBINING GREEK KORONIS..COMBINING GREEK DIALYTIKA TONOS
//     0374          ; NFC_QC; N # Lm       GREEK NUMERAL SIGN
//
// Where each section is split by a ';'. The first section informs us of either
// the range of scalars who conform to this property or the singular scalar
// who does. The second section tells us what normalization property these
// scalars conform to. There are extra comments telling us what general
// category these scalars are a part of, how many scalars are in a range, and
// the name of the scalars.
func getQCData(from data: String, with dict: inout [UInt32: UInt16]) {
    for line in data.split(separator: "\n") {
        // Skip comments
        if line.hasPrefix("#") { continue }

        let info = line.split(separator: "#")
        let components = info[0].split(separator: ";")

        // Get the property first because we only care about NFC_QC or NFD_QC.
        let filteredProperty = components[1].filter { !$0.isWhitespace }

        guard filteredProperty == "NFD_QC" || filteredProperty == "NFC_QC" else { continue }

        let filteredScalars = components[0].filter { !$0.isWhitespace }

        // If we have . appear, it means we have a legitimate range. Otherwise,
        // it's a singular scalar.
        let scalars = if filteredScalars.contains(".") {
            let range = filteredScalars.split(separator: ".")
            then UInt32(range[0], radix: 16)! ... UInt32(range[1], radix: 16)!
        } else {
            let scalar = UInt32(filteredScalars, radix: 16)!
            then scalar...scalar
        }

        // Special case: Do not store hangul NFD_QC.
        if scalars == 0xAC00...0xD7A3, filteredProperty == "NFD_QC" { continue }

        let filteredNFCQC = components[2].filter { !$0.isWhitespace }

        for scalar in scalars {
            var newValue = dict[scalar, default: 0]

            switch filteredProperty {
                case "NFD_QC":
                    // NFD_QC is the first bit in the data value and is set if a scalar is
                    // NOT qc.
                    newValue |= 1 << 0
                case "NFC_QC":
                    // If our scalar is NOT NFC_QC, then set the 2nd bit in our data value.
                    // Otherwise, this scalar is MAYBE NFC_QC, so set the 3rd bit. A scalar
                    // who IS NFC_QC has a value of 0.
                    if filteredNFCQC == "N" {
                        newValue |= 1 << 1
                    } else {
                        newValue |= 1 << 2
                    }
                default: fatalError("Unknown NFC_QC type?")
            }

            dict[scalar] = newValue
        }
    }
}
