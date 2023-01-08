import Foundation

struct MnemonicSequence: Sequence {
    let partialMnemonic: [String]
    let wordList: [String: Int]
    let wordCount: WordCount
    let unsortedList: Bool

    var count: Int { underestimatedCount }
    var underestimatedCount: Int {
        let mnemonicIterations = partialMnemonic.reduce(1) { partialResult, word in
            if word == "?" {
                return partialResult * wordList.count
            } else if word.contains("|") {
                return partialResult * word.split(separator: "|").count
            } else {
                return partialResult
            }
        }

        if unsortedList {
            return mnemonicIterations * (1 ... partialMnemonic.count).reduce(1, *)
        } else {
            return mnemonicIterations
        }
    }


    struct Iterator: IteratorProtocol {

        var shouldPermuteWordList: Bool
        var wordLists: [[String]]
        var wordListPermutationIndexes: [Int]
        var wordListPermutation: Int
        var indexes: [Int]
        var upperBounds: [Int]
        var hasFinished = false

        init(_ mnemonic: MnemonicSequence) {
            self.shouldPermuteWordList = mnemonic.unsortedList
            self.indexes = [Int](repeating: 0, count: mnemonic.wordCount.rawValue)
            self.wordLists = mnemonic.partialMnemonic.map { word in
                if word == "?" {
                    return Array(mnemonic.wordList.keys).shuffled()
                } else if word.contains("|") {
                    return word.split(separator: "|").map(String.init)
                } else {
                    return [word]
                }
            }
            self.wordListPermutationIndexes = [Int](repeating: 0, count: mnemonic.wordCount.rawValue)
            self.wordListPermutation = 0
            self.upperBounds = mnemonic.partialMnemonic.map { word in
                if word == "?" {
                    return mnemonic.wordList.count
                } else if word.contains("|") {
                    return word.split(separator: "|").count
                } else {
                    return 1
                }
            }
        }

        mutating func next() -> [String]? {
            guard !hasFinished else { return nil }
            var words = [String](repeating: "", count: wordLists.count)
            for position in 0 ..< wordLists.count {
                words[position] = wordLists[position][indexes[position]]
            }

            var hasOverflow = true
            for position in (0 ..< indexes.count).reversed() {
                guard
                    upperBounds[position] > 1,
                    hasOverflow
                else { continue }
                if indexes[position] + 1 >= upperBounds[position] {
                    indexes[position] = 0
                } else {
                    indexes[position] += 1
                    hasOverflow = false
                }
            }

            // Based on https://www.baeldung.com/cs/array-generate-all-permutations#2-non-recursive-heaps-algorithm
            if hasOverflow && shouldPermuteWordList {
                while wordListPermutation < wordListPermutationIndexes.count {
                    if wordListPermutationIndexes[wordListPermutation] < wordListPermutation {
                        if wordListPermutation % 2 == 0 {
                            wordLists.swapAt(0, wordListPermutation)
                            upperBounds.swapAt(0, wordListPermutation)
                        } else {
                            wordLists.swapAt(wordListPermutationIndexes[wordListPermutation], wordListPermutation)
                            upperBounds.swapAt(wordListPermutationIndexes[wordListPermutation], wordListPermutation)
                        }
                        hasOverflow = false
                        for index in 0 ..< indexes.count {
                            indexes[index] = 0
                        }
                        wordListPermutationIndexes[wordListPermutation] += 1
                        wordListPermutation = 0
                        break
                    } else {
                        wordListPermutationIndexes[wordListPermutation] = 0
                        wordListPermutation += 1
                    }
                }
            }

            hasFinished = hasOverflow

            return words
        }
    }

    func makeIterator() -> Iterator {
        Iterator(self)
    }
}
