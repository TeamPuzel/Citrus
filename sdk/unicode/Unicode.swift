// A native port of Swift's Unicode runtime.

import Swift
import Builtin

#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
@_transparent
func abortUnicodeDisabled() -> Never { fatalError("unicode support not enabled") }
#endif

/// Every 4 byte chunks of data that we need to hash (in this case only ever
/// scalars and levels who are all uint32), we need to calculate K. At the end
/// of this scramble sequence to get K, directly apply this to the current hash.
@_transparent
func scramble(_ scalar: UInt32) -> UInt32 {
    var scalar = scalar
    scalar &*= 0xCC9E2D51
    scalar = (scalar << 15) | (scalar >> 17)
    scalar &*= 0x1B873593
    return scalar
}

/// This is a reimplementation of MurMur3 hash with a modulo at the end.
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

/// This implementation is based on the minimal perfect hashing strategy found
/// here: https://arxiv.org/pdf/1702.03154.pdf
@_transparent
func getMphIndex(
    for scalar: UInt32,
    levels: Int,
    keys: Span<UInt64>,
    keyOffsets: Span<UInt16>,
    ranks: Span<UInt16>,
    rankOffsets: Span<UInt16>,
    valueOffsets: Span<UInt32>,
    sizes: Span<UInt16>
) -> Int {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    var resultIndex = 0

    // Here, levels represent the numbers of bit arrays used for this hash table.
    for i in 0..<levels {
        let bitArray = keys.extracting(droppingFirst: Int(keyOffsets[i]))

        // Get the specific bit that this scalar hashes to in the bit array.
        let index = Int(hash(scalar, level: UInt32(sizes[i]), seed: UInt32(i)))

        let word = bitArray[index / 64]
        let mask = UInt64(1) << index % 64

        // If our scalar's bit is turned on in the bit array, it means we no longer
        // need to iterate the bit arrays to find where our scalar is located...
        // its in this one.
        if word & mask != 0 {
            // Our initial rank corresponds to our current level and there are ranks
            // within each bit array every 512 bits. Say our level (bit array)
            // contains 16 uint64 integers to represent all of the required bits.
            // There would be a total of 1024 bits, so our rankings for this level
            // would contain two values for precomputed counted bits for both halves
            // of this bit array (1024 / 512 = 2).
            let ranks = ranks.extracting(droppingFirst: Int(rankOffsets[i]))
            var rank = Int(ranks[index / 512])

            // Because ranks are provided every 512 bits (8 uint64s), we still need to
            // count the bits of the uints64s before us in our 8 uint64 sequence. So
            // for example, if we are bit 576, we are larger than 512, so there is a
            // provided rank for the first 8 uint64s, however we're in the second
            // 8 uint64 sequence and within said sequence we are the #2 uint64. This
            // loop will count the bits set for the first uint64 and terminate.
            for j in ((index / 64) & ~7)..<(index / 64) {
                rank += bitArray[j].nonzeroBitCount
            }

            // After counting the other bits set in the uint64s before, its time to
            // count our word itself and the bits before us.
            if index % 64 > 0 {
                rank += (word << (64 - (index % 64))).nonzeroBitCount
            }

            resultIndex = Int(valueOffsets[i]) + rank
            break
        }
    }

    return resultIndex
#endif
}

/// A scalar bit array is represented using a combination of quick look bit
/// arrays and specific bit arrays expanding these quick look arrays. There's
/// usually a few data structures accompanying these bit arrays like ranks, data
/// indices, and an actual data array.
///
/// The bit arrays are constructed to look somewhat like the following:
///
///     [quickLookSize, {uint64 * quickLookSize}, {5 * uint64}, {5 * uint64},
///      {5 * uint64}...]
///
/// where the number of {5 * uint64} (a specific bit array) is equal to the
/// number of bits turned on within the {uint64 * quickLookSize}. This can be
/// easily calculated using the passed in ranks arrays who looks like the
/// following:
///
///     [{uint16 * quickLookSize}, {5 * uint16}, {5 * uint16}, {5 * uint16}...]
///
/// which is the same exact scheme as the bit arrays. Ranks contain the number of
/// previously turned on bits according their respectful {}. For instance, each
/// chunk, {5 * uint16}, begins with 0x0 and continuously grows as the number of
/// bits within the chunk turn on. An example sequence of this looks like:
/// [0x0, 0x0, 0x30, 0x70, 0xB0] where the first uint64 obviously doesn't have a
/// previous uint64 to look at, so its rank is 0. The second uint64's rank will
/// be the number of bits turned on in the first uint64, which in this case is
/// also 0. The third uint64's rank is 0x30 meaning there were 48 bits turned on
/// from the first uint64 through the second uint64.
func getScalarBitArrayIdx(
    _ scalar: UInt32,
    _ bitArrays: Span<UInt64>,
    _ ranks: Span<UInt16>
) -> Int {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    // Chunk size indicates the number of scalars in a singular bit in our quick
    // look arrays. Currently, a chunk consists of 272 scalars being represented
    // in a bit. 0x110000 represents the maximum scalar value that Unicode will
    // never go over (or at least promised to never go over), 0x10FFFF, plus 1.
    // There are 64 bit arrays allocated for the quick look search and within
    // each bit array is an allocated 64 bits (8 bytes). Assuming the whole quick
    // search array is allocated and used, this would mean 512 bytes are used
    // solely for these arrays.
    let chunkSize: UInt32 = 0x110000 / 64 / 64

    // Our base is the specific bit in the context of all of the bit arrays that
    // holds our scalar. Considering there are 64 bit arrays of 64 bits, that
    // would mean there are 64 * 64 = 4096 total bits to represent all scalars.
    let base = scalar / chunkSize

    // Index is our specific bit array that holds our bit.
    let index = base / 64

    // Chunk bit is the specific bit within the bit array for our scalar.
    let chunkBit = base % 64

    // At the beginning our bit arrays is a number indicating the number of
    // actually implemented quick look bit arrays. We do this to save a little bit
    // of code size for bit arrays towards the end that usually contain no
    // properties, thus their bit arrays are most likely 0 or null.
    let quickLookSize = bitArrays[0]

    // If our chunk index is larger than the quick look indices, then it means
    // our scalar appears in chunks who are all 0 and trailing.
    if UInt64(index) > quickLookSize - 1 { return .max }

    // Our scalar actually exists in a quick look bit array that was implemented.
    let quickLook = bitArrays[Int(index) + 1]

    // If the quick look array has our chunk bit not set, that means all 272
    // (chunkSize) of the scalars being represented have no property and ours is
    // one of them.
    if (quickLook & (UInt64(1) << chunkBit)) == 0 { return .max }

    // Ok, our scalar failed the quick look check. Go lookup our scalar in the
    // chunk specific bit array. Ranks keeps track of the previous bit array's
    // number of non zero bits and is iterative.
    //
    // For example, [1, 3, 10] are bit arrays who have certain number of bits
    // turned on. The generated ranks array would look like [0, 1, 3] because
    // the first value, 1, does not have any previous bit array to look at so its
    // number of ranks are 0. 3 on the other hand will see its rank value as 1
    // because the previous value had 1 bit turned on. 10 will see 3 because it is
    // seeing both 1 and 3's number of turned on bits (3 has 2 bits on and
    // 1 + 2 = 3).
    var chunkRank = ranks[Int(index)]

    // If our specific bit within the chunk isn't the first bit, then count the
    // number of bits turned on preceding our chunk bit.
    if chunkBit != 0 {
        chunkRank += UInt16((quickLook << (64 - chunkBit)).nonzeroBitCount)
    }

    // Each bit that is turned on in the quick look arrays is given a bit array
    // that consists of 5 64 bit integers (5 * 64 = 320 which is enough to house
    // at least 272 specific bits dedicated to each scalar within a chunk). Our
    // specific chunk's array is located at:
    // 1 (quick look count)
    // +
    // quickLookSize (number of actually implemented quick look arrays)
    // +
    // chunkRank * 5 (where chunkRank is the total number of bits turned on
    // before ours and each chunk is given 5 uint64s)
    let chunkBA = bitArrays.extracting(droppingFirst: 1 + Int(quickLookSize) + (Int(chunkRank) * 5))

    // Our overall bit represents the bit within 0 - 271 (272 total, our
    // chunkSize) that houses our scalar.
    let scalarOverallBit = scalar - (base * chunkSize)

    // And our specific bit here represents the bit that houses our scalar inside
    // a specific uint64 in our overall bit array.
    let scalarSpecificBit = scalarOverallBit % 64

    // Our word here is the index into the chunk's bit array to grab the specific
    // uint64 who houses a bit representing our scalar.
    let scalarWord = scalarOverallBit / 64

    let chunkWord = chunkBA[Int(scalarWord)]

    // If our scalar specifically is not turned on within our chunk's bit array,
    // then we know for sure that our scalar does not inhibit this property.
    if chunkWord & (UInt64(1) << scalarSpecificBit) == 0 {
        return .max
    }

    // Otherwise, this scalar does have whatever property this scalar array is
    // representing. Our ranks also holds bit information for a chunk's bit array,
    // so each chunk is given 5 uint16 in our ranks to count its own bits.
    var scalarRank = Int(ranks[Int(quickLookSize) + (Int(chunkRank) * 5) + Int(scalarWord)])

    // Again, if our scalar isn't the first bit in its uint64, then count the
    // proceeding number of bits turned on in our uint64.
    if scalarSpecificBit != 0 {
        scalarRank += (chunkWord << (64 - scalarSpecificBit)).nonzeroBitCount
    }

    // In our last uint64 in our bit array, there is an index into our data index
    // array. Because we only need 272 bits for the scalars, any remaining bits
    // can be used for essentially whatever. 5 * 64 bits = 320 bits and we only
    // allocate 16 bits in the last uint64 for the remaining scalars
    // (4 * 64 bits = 256 + 16 = 272 (chunkSize)) leaving us with 48 spare bits.
    let chunkDataIdx = chunkBA[4] >> 16

    // Finally, our index (or rather whatever value is stored in our spare bits)
    // is simply the start of our chunk's index plus the specific rank for our
    // scalar.
    return Int(chunkDataIdx) + scalarRank
#endif
}

@c @used
func _swift_stdlib_isExtendedPictographic(_ scalar: UInt32) -> Bool {
    // Fast Path: U+A9 is the first scalar to be an extended pictographic.
    if scalar < 0xA9 { return false }

#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    let dataIdx = getScalarBitArrayIdx(scalar, unicodeEmojiData.span, unicodeEmojiDataRanks.span)

    // If we don't have an index into the data indices, then this scalar is not an
    // extended pictographic.
    if dataIdx == .max { return false }

    return true
#endif
}

@c @used
func _swift_stdlib_getGraphemeBreakProperty(_ scalar: UInt32) -> UInt8 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    var index = 1 // 0th element is a dummy element.
    while index < unicodeGraphemeBreakProperties.count {
        let entry = unicodeGraphemeBreakProperties[index]

        // Shift the enum and range count out of the value.
        let lower = (entry << 11) >> 11

        // Shift the enum out first, then shift out the scalar value.
        var upper = lower &+ ((entry << 3) >> 24)

        // Shift everything out.
        let enumValue = UInt8(entry >> 29)

        // Special case: extendedPictographic who used an extra bit for the range.
        if enumValue == 5 { upper = lower + ((entry << 2) >> 23) }

        if scalar < lower {
            index = 2 * index
        } else if scalar <= upper {
            return enumValue
        } else {
            index = 2 * index + 1
        }
    }

    // If we made it out here, then our scalar was not found in the grapheme
    // array (this occurs when a scalar doesn't map to any grapheme break
    // property). Return the max value here to indicate .any.
    return .max
#endif
}

@c @used
func _swift_stdlib_isInCB_Consonant(_ scalar: UInt32) -> Bool {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    let idx = getScalarBitArrayIdx(scalar, unicodeInCBConsonant.span, unicodeInCBConsonantRanks.span)
    if idx == .max { return false }
    return true
#endif
}

@c @used
func _swift_stdlib_getNormData(_ scalar: UInt32) -> UInt16 {
    // Fast Path: ASCII and some latiny scalars are very basic and have no
    // normalization properties.
    if scalar < 0xC0 { return 0 }

#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    let dataIdx = getScalarBitArrayIdx(scalar, unicodeNormData.span, unicodeNormDataRanks.span)

    // If we don't have an index into the data indices, then this scalar has no
    // normalization information.
    if dataIdx == .max { return 0 }

    let scalarDataIdx = unicodeNormDataDataIndices[dataIdx]
    return unicodeNormDataData[Int(scalarDataIdx)]
#endif
}

@_silgen_name("_swift_stdlib_nfd_decompositions") @used
var _swift_stdlib_nfd_decompositions: UnsafePointer<UInt8>? = nil

@c @used
func _swift_stdlib_getNfdDecompositions() -> UnsafePointer<UInt8> {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    fatalError()
#endif
}

@c @used
func _swift_stdlib_getDecompositionEntry(_ scalar: UInt32) -> UInt32 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    unicodeNfdDecompIndices[getMphIndex(
        for: scalar,
        levels: unicodeNfdDecompLevelCount,
        keys: unicodeNfdDecompKeysData.span,
        keyOffsets: unicodeNfdDecompKeysOffsets.span,
        ranks: unicodeNfdDecompRanksData.span,
        rankOffsets: unicodeNfdDecompRanksOffsets.span,
        valueOffsets: unicodeNfdDecompValueOffsets.span,
        sizes: unicodeNfdDecompSizes.span
    )]
#endif
}

@c @used
func _swift_stdlib_getComposition(_ x: UInt32, _ y: UInt32) -> UInt32 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    let offset = unicodeNfcCompDataOffsets[getMphIndex(
        for: y,
        levels: unicodeNfcCompLevelCount,
        keys: unicodeNfcCompKeysData.span,
        keyOffsets: unicodeNfcCompKeysOffsets.span,
        ranks: unicodeNfcCompRanksData.span,
        rankOffsets: unicodeNfcCompRanksOffsets.span,
        valueOffsets: unicodeNfcCompValueOffsets.span,
        sizes: unicodeNfcCompSizes.span
    )]

    @_transparent
    func at(_ index: Int) -> UInt32 {
        unicodeNfcCompData[index + Int(offset)]
    }

    let first = at(0)
    // Ensure that the first element in this array is equal to our y scalar.
    let realY = (first << 11) >> 11
    if y != realY { return .max }

    let count = Int(first >> 21)

    var low = 1
    var high = Int(count) - 1

    while high >= low {
        let index = low + (high - low) / 2
        let entry = at(index)

        let lower = (entry << 15) >> 15 // Shift the range count out of the scalar.

        let isNegative = entry >> 31
        var rangeCount = Int32(bitPattern: (entry << 1) >> 18)

        if isNegative != 0 { rangeCount.negate() }

        let composed = lower + UInt32(bitPattern: rangeCount)

        if x == lower { return composed }

        if x > lower {
            low = index + 1
            continue
        }

        if x < lower {
            high = index - 1
            continue
        }
    }

    // If we made it out here, then our scalar was not found in the composition
    // array.
    // Return the max here to indicate that we couldn't find one.
    return .max
#endif
}

@c @used
func _swift_stdlib_getWordBreakProperty(_ scalar: UInt32) -> UInt8 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    var index = 1 // 0th element is a dummy element.
    while index < unicodeWords.count {
        let entry = unicodeWords[index]

        // Shift the range count out of the value.
        let lower = (entry << 11) >> 11

        // Shift the enum out first, then shift out the scalar value.
        let upper = lower + (entry >> 21) - 1

        // If we want the left child of the current node in our virtual tree,
        // that's at index * 2, if we want the right child it's at (index * 2) + 1
        if scalar < lower {
            index = 2 * index
        } else if scalar <= upper {
            return unicodeWordsData[index]
        } else {
            index = 2 * index + 1
        }
    }

    // If we made it out here, then our scalar was not found in the word
    // array (this occurs when a scalar doesn't map to any word break
    // property). Return the max value here to indicate .any.
    return .max
#endif
}

@c @used
func _swift_stdlib_getBinaryProperties(_ scalar: UInt32) -> UInt64 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let lowerBoundIndex = 0
    let endIndex = binPropsCount
    let upperBoundIndex = endIndex - 1

    while upperBoundIndex >= lowerBoundIndex {
        let index = lowerBoundIndex + (upperBoundIndex - lowerBoundIndex) / 2

        let entry = _swift_stdlib_scalar_binProps[index]

        // Shift the ccc value out of the scalar.
        let lowerBoundScalar = (entry << 11) >> 11

        // If we're not at the end of the array, the range count is simply the
        // distance to the next element.
        let upperBoundScalar = if index != endIndex - 1 {
            let nextEntry = _swift_stdlib_scalar_binProps[index + 1]
            let nextLower = (nextEntry << 11) >> 11
            then upperBoundScalar = nextLower - 1
        } else {
            0x10FFFF // Otherwise, the range count is the distance to 0x10FFFF
        }

        // Shift everything out.
        let dataIndex = entry >> 21

        if scalar >= lowerBoundScalar && scalar <= upperBoundScalar {
            return _swift_stdlib_scalar_binProps_data[dataIndex]
        }

        if scalar > upperBoundScalar {
            lowerBoundIndex = index + 1
            continue
        }

        if scalar < lowerBoundScalar {
            upperBoundIndex = index - 1
            continue
        }
    }

    // If we make it out of this loop, then it means the scalar was not found at
    // all in the array. This should never happen because the array represents all
    // scalars from 0x0 to 0x10FFFF, but if somehow this branch gets reached,
    // return 0 to indicate no properties.
    return 0
#endif
}

@c @used
func _swift_stdlib_getNumericType(_ scalar: UInt32) -> UInt8 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    var lowerBoundIndex = 0
    let endIndex = numericTypeCount
    let upperBoundIndex = endIndex - 1

    while upperBoundIndex >= lowerBoundIndex {
        let idx = lowerBoundIndex + (upperBoundIndex - lowerBoundIndex) / 2

        let entry = _swift_stdlib_numeric_type[idx]

        let lowerBoundScalar = (entry << 11) >> 11
        let rangeCount = (entry << 3) >> 24
        let upperBoundScalar = lowerBoundScalar + rangeCount

        let numericType = UInt8(entry >> 29)

        if scalar >= lowerBoundScalar && scalar <= upperBoundIndex {
            return numericType
        }

        if scalar > upperBoundScalar {
            lowerBoundIndex = idx + 1
            continue
        }

        if scalar < lowerBoundScalar {
            upperBoundIndex = idx - 1
            continue
        }
    }

    // If we made it out here, then our scalar was not found in the composition
    // array.
    // Return the max here to indicate that we couldn't find one.
    return .max
#endif
}

@c @used
func _swift_stdlib_getNumericValue(_ scalar: UInt32) -> Double {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let levelCount = numericValuesLevelCount
    let scalarIdx = _swift_stdlib_getMphIdx(
        scalar, levelCount,
        _swift_stdlib_numeric_values_keys,
        _swift_stdlib_numeric_values_ranks,
        _swift_stdlib_numeric_values_sizes
    )
    let valueIDx = _swift_stdlib_numeric_values_indices[scalarIdx]
    return _swift_stdlib_numeric_values[valueIdx]
#endif
}

@c @used
func _swift_stdlib_getNameAlias(_ scalar: UInt32) -> UnsafePointer<CChar> {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let dataIdx = _swift_stdlib_getScalarBitArrayIdx(
        scalar,
        _swift_stdlib_nameAlias,
        _swift_stdlib_nameAlias_ranks
    )

    if dataIdx == .max {
        return nil
    } else {
        return _swift_stdlib_nameAlias_data[dataIdx]
    }
#endif
}

@c @used
func _swift_stdlib_getMapping(_ scalar: UInt32, _ mapping: UInt8) -> Int32 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let dataIdx = _swift_stdlib_getScalarBitArrayIdx(
        scalar,
        _swift_stdlib_mappings,
        _swift_stdlib_mappings_ranks
    )

    if dataIdx == .max {
        return 0
    }

    let mappings = _swift_stdlib_mappings_data_indices[dataIdx]

    let mappingIdx = switch mapping {
        case 0: (mappings & 0xFF    )       // Uppercase.
        case 1: (mappings & 0xFF00  ) >> 8  // Lowercase.
        case 2: (mappings & 0xFF0000) >> 16 // Titlecase.
        case _: 0 // Unknown.
    }

    if mappingIdx == 0xFF { return 0 }

    return _swift_stdlib_mappings_data[mappingIdx]
#endif
}

@c @used
func _swift_stdlib_getSpecialMapping(
    _ scalar: UInt32,
    _ mapping: UInt8,
    _ length: UnsafeMutablePointer<Int>
) -> UnsafePointer<UInt8>? {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let dataIdx = getScalarBitArrayIdx(
        scalar,
        _swift_stdlib_special_mappings,
        _swift_stdlib_special_mappings_ranks
    )

    if dataIdx == .max { return nil }

    let index = _swift_stdlib_special_mappings_data_indices[dataIdx]

    let uppercase = _swift_stdlib_special_mappings_data + index
    let lowercase = uppercase + 1 + uppercase.pointee
    let titlecase = lowercase + 1 + lowercase.pointee

    length.pointee = switch mapping {
        case 0: uppercase.pointee
        case 1: lowercase.pointee
        case 2: titlecase.pointee
        case _: nil // Unknown.
    }
#endif
}

@c @used
func _swift_stdlib_getScalarName(
    _ scalar: UInt32,
    _ buffer: UnsafeMutablePointer<UInt8>,
    _ capacity: Int
) -> Int {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let setOffset = _swift_stdlib_names_scalar_sets[scalar >> 7]

    if setOffset == .max {
        return 0
    }

    let scalarIndex = (setOffset << 7) + (scalar & ((1 << 7) - 1))
    let scalarOffset = _swift_stdlib_names_scalars[scalarIndex]

    // U+20 is the first scalar that Unicode defines a name for, so their offset
    // will the only valid 0.
    if scalarOffset == 0 && scalar != 0x20 {
        return 0
    }

    var nextScalarOffset: UInt32 = 0
    if scalarIndex != namesScalarsMaxIndex {
        var i = 1

        // Look for the next scalar who has a name and their position in the names
        // array. This tells us exactly how many bytes our name takes up.
        while nextScalarOffset == 0 {
            nextScalarOffset = _swift_stdlib_names_scalars[scalarIndex + i]
            i += 1
        }
    } else {
        // This is the last element in the array which represents the last scalar
        // name that Unicode defines (excluding variation selectors).
        nextScalarOffset = namesLastScalarOffset
    }

    let nameSize = nextScalarOffset - scalarOffset

    // The total number of initialized bytes in the name string.
    var c = 0

    // TODO: This code is very C, needs further swiftification.
    for i in 0..<nameSize {
        let wordIndex = UInt16(_swift_stdlib_names[scalarOffset + i])

        // If our word index is 0xFF, then it means our word index is larger than a
        // byte, so the next two bytes will compose the 16 bit index.
        if wordIndex == 0xFF {
            i += 1
            let firstPart = _swift_stdlib_names[scalarOffset + i]
            wordIndex = firstPart

            i += 1
            let secondPart = _swift_stdlib_names[scalarOffset + i]
            wordIndex |= secondPart << 8
        }

        let wordOffset = _swift_stdlib_word_indices[wordIndex]

        let word = _swift_stdlib_words + wordOffset

        // The last character in a word has the 7th bit set.
        while word.pointee < 0x80 {
            if c >= capacity { return c }

            buffer[c] = word.pointee
            word += 1
            c += 1
        }

        if c >= capacity { return c }

        let clean = word.pointee & 0x7F
        buffer[c] = clean
        c += 1

        if c >= capacity {
            return c
        }

        buffer[c] = 0x20 // Space ASCII.
        c += 1
    }

    // Remove the trailing space.
    c -= 1

    // The return value is the number of initialized bytes.
    return c
#endif
}

@c @used
func _swift_stdlib_getAge(_ scalar: UInt32) -> UInt16 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let lowerBoundIndex = 0
    let endIndex = ageCount
    let upperBoundIndex = endIndex - 1

    while upperBoundIndex >= lowerBoundIndex {
        let idx = lowerBoundIndex + (upperBoundIndex - lowerBoundIndex) / 2

        let entry = _swift_stdlib_ages[idx]

        let lowerBoundScalar = (entry << 43) >> 43
        let rangeCount = entry >> 32
        let upperBoundScalar = lowerBoundScalar + rangeCount

        let ageIdx = UInt8((entry << 32) >> 32 >> 21)

        if scalar >= lowerBoundScalar && scalar <= upperBoundScalar {
            return _swift_stdlib_ages_data[ageIdx]
        }

        if scalar > upperBoundScalar {
            lowerBoundIndex = idx + 1
            continue
        }

        if scalar < lowerBoundScalar {
            upperBoundIndex = idx - 1
            continue
        }
    }

    // If we made it out here, then our scalar was not found in the composition
    // array.
    // Return the max here to indicate that we couldn't find one.
    return .max
#endif
}

@c @used
func _swift_stdlib_getGeneralCategory(_ scalar: UInt32) -> UInt8 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let lowerBoundIndex = 0
    let endIndex = generalCategoryCount
    let upperBoundIndex = endIndex - 1

    while upperBoundIndex >= lowerBoundIndex {
        let idx = lowerBoundIndex + (upperBoundIndex - lowerBoundIndex) / 2

        let entry = _swift_stdlib_generalCategory[idx]

        let lowerBoundScalar = (entry << 43) >> 43
        let rangeCount = entry >> 32
        let upperBoundScalar = lowerBoundScalar + rangeCount

        let generalCategory = UInt8((entry << 32) >> 32 >> 21)

        if scalar >= lowerBoundScalar && scalar <= upperBoundScalar {
            return generalCategory
        }

        if scalar > upperBoundScalar {
            lowerBoundIndex = idx + 1
            continue
        }

        if scalar < lowerBoundScalar {
            upperBoundIndex = idx - 1
            continue
        }
    }

    // If we made it out here, then our scalar was not found in the composition
    // array.
    // Return the max here to indicate that we couldn't find one.
    return .max
#endif
}

@c @used
func _swift_stdlib_getScript(_ scalar: UInt32) -> UInt8 {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    var lowerBoundIndex = 0
    let endIndex = unicodeScripts.count
    var upperBoundIndex = endIndex - 1

    while upperBoundIndex >= lowerBoundIndex {
        let index = lowerBoundIndex + (upperBoundIndex - lowerBoundIndex) / 2

        let entry = unicodeScripts[index]

        // Shift the enum value out of the scalar.
        let lowerBoundScalar = (entry << 11) >> 11

        var upperBoundScalar: UInt32 = 0

        // If we're not at the end of the array, the range count is simply the
        // distance to the next element.
        if index != endIndex - 1 {
            let nextEntry = unicodeScripts[index + 1]

            let nextLower = (nextEntry << 11) >> 11

            upperBoundScalar = nextLower - 1
        } else {
            upperBoundScalar = 0x10FFFF
        }

        // Shift the scalar out and get the enum value.
        let script = UInt8(entry >> 21)

        if scalar >= lowerBoundScalar && scalar <= upperBoundScalar {
            return script
        }

        if scalar > upperBoundScalar {
            lowerBoundIndex = index + 1
            continue
        }

        if scalar < lowerBoundScalar {
            upperBoundIndex = index - 1
            continue
        }
    }

    // If we make it out of this loop, then it means the scalar was not found at
    // all in the array. This should never happen because the array represents all
    // scalars from 0x0 to 0x10FFFF, but if somehow this branch gets reached,
    // return 255 to indicate a failure.
    return .max
#endif
}

@c @used
func _swift_stdlib_getScriptExtensions(
    _ scalar: UInt32,
    _ count: UnsafeMutablePointer<UInt8>
) -> UnsafePointer<UInt8>? {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA || true
    abortUnicodeDisabled()
#else
    let dataIdx =  getScalarBitArrayIdx(scalar, unicodeScriptExtensions.span, unicodeScriptExtensionsRanks.span)

    // If we don't have an index into the data indices, then this scalar has no
    // script extensions
    if dataIdx == .max { return nil }

    let scalarDataIdx = unicodeScriptExtensionsDataIndices[dataIdx]
    unsafe count.pointee = UInt8(scalarDataIdx >> 11)

    return unicodeScriptExtensionsData + (scalarDataIdx & 0x7FF)
#endif
}

@c @used
func _swift_stdlib_getCaseMapping(
    _ scalar: UInt32,
    _ buffer: UnsafeMutablePointer<UInt32>
) {
#if !SWIFT_STDLIB_ENABLE_UNICODE_DATA
    abortUnicodeDisabled()
#else
    let mphIndex = getMphIndex(
        for: scalar,
        levels: unicodeCaseFoldLevelCount,
        keys: unicodeCaseKeysData.span,
        keyOffsets: unicodeCaseKeysOffsets.span,
        ranks: unicodeCaseRanksData.span,
        rankOffsets: unicodeCaseRanksOffsets.span,
        valueOffsets: unicodeCaseValueOffsets.span,
        sizes: unicodeCaseSizes.span
    )
    let caseValue = unicodeCase[mphIndex]
    let hashedScalar = UInt32((caseValue << 43) >> 43)

    // If our scalar is not the original one we hashed, then this scalar has no
    // case mapping. It maps to itself.
    if scalar != hashedScalar { unsafe buffer[0] = scalar; return }

    // If the top bit is NOT set, then this scalar simply maps to another scalar.
    // We have stored the distance to said scalar in this value.
    if caseValue & UInt64(0x1 << 63) == 0 {
        let distance = Int32((caseValue << 1) >> 22)
        let mappedScalar = UInt32(bitPattern: Int32(scalar) - distance)

        unsafe buffer[0] = mappedScalar
        return
    }

    // Our top bit WAS set which means this scalar maps to multiple scalars.
    // Lookup our mapping in the full mph.
    let fullMphIdx = getMphIndex(
        for: scalar,
        levels: unicodeCaseFullFoldLevelCount,
        keys: unicodeCaseFullKeysData.span,
        keyOffsets: unicodeCaseFullKeysOffsets.span,
        ranks: unicodeCaseFullRanksData.span,
        rankOffsets: unicodeCaseFullRanksOffsets.span,
        valueOffsets: unicodeCaseFullValueOffsets.span,
        sizes: unicodeCaseFullSizes.span
    )
    var fullCaseValue = unicodeCaseFull[fullMphIdx]

    // Count is either 2 or 3.
    let count = fullCaseValue >> 62

    for i in 0..<count {
        var distance = Int32(fullCaseValue & 0xFFFF)

        if fullCaseValue & 0x10000 != 0 {
            distance = -distance
        }

        fullCaseValue >>= 17

        let mappedScalar = UInt32(Int32(scalar) - distance)
        unsafe buffer[Int(i)] = mappedScalar
    }
#endif
}
