import ArgumentParser
import Foundation

@main
struct MnemonicCracker: ParsableCommand {

    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "mnemonic-cracker",
            abstract: "A simple tool to try and find a mnemonic phrase from a partial phrase.",
            usage: "mnemonic-cracker [--unsorted-list] [-a 0xaddress] [-v] [-p mnemonicPassword] [-l english] partial phrase can|provide|alternatives ? ? ? ? ? ? ? ? ?",
            discussion: """
            This tool will try to brute force a mnemonic phrase given a partial mnemonic phrase.

            If used along with an address, using the -a flag, it will try to find a mnemonic that matches the given address (defaulting to MetaMask's first address).

            If no address is provided, will try to check for address with non-zero balances.

            Supports mnemonic phrases of 12/15/18/21/24 words using English BIP-39 list of words.

            Must provide all words in the partial phrase, for positions which you don't know the word use "?" and the tool will brute force using all the words in the list.
            If there are a few words which you believe might be part of the final mnemonic phrase you may specify a list of them with a | separator for the position in which you believe they are in.
            If the provided words are not in the correct position, i.e. you don't know the order of the words, you may use the flag --unsorted-list to permute all possible sequences.
            """,
            shouldDisplay: true,
            helpNames: .shortAndLong
        )
    }

    @Option(name: .shortAndLong, help: "Ethereum address you'd hope to find")
    var address: String?

    @Option(name: .shortAndLong, help: "Passphrase for the mneumonic seed generation")
    var password: String = ""

    @Argument(help: "The partial mnemonic phrase you have, with a ? for words you do not know. You may specify alternatives for a given position with | separated like: razor|blade (will try both combinations)")
    var partialMnemonic: [String]

    @Flag(name: .long, help: "If the partial mnemonic phrase is not in the correct order, i.e. the words provided are not in the correct position.")
    var unsortedList: Bool = false

    @Flag(name: .shortAndLong)
    var verbose: Bool = false

    @Option(name: .shortAndLong, help: "Language of the mnemonic phrase, options are: \(Language.allCases.map { $0.rawValue }.joined(separator: ","))")
    var language: Language = .english

    mutating func run() throws {
        guard let wordCount = WordCount(rawValue: partialMnemonic.count) else { throw ValidationError.invalidWordCount }
        let wordList = language.wordList
        let dispatchGroup = DispatchGroup()
        let orchestrationQueue = DispatchQueue(label: "orchestration", qos: .background)
        let processingQueue = DispatchQueue(label: "processing", qos: .userInitiated, attributes: .concurrent)
        let operationQueue = CancellableOperationQueue()

        let start = Date()
        dispatchGroup.enter()
        orchestrationQueue.async { [verbose, address, password, partialMnemonic, unsortedList] in
            defer { dispatchGroup.leave() }

            let sequence = MnemonicSequence(
                partialMnemonic: partialMnemonic,
                wordList: wordList,
                wordCount: wordCount,
                unsortedList: unsortedList
            )

            print("Iterating over \(sequence.count) combinations")

            for mnemonic in sequence {
                guard !operationQueue.isCancelled else { return }
                let operation = CheckMnemonicOperation(
                    mnemonic: mnemonic,
                    wordList: wordList,
                    wordCount: wordCount,
                    userPassword: password,
                    address: address,
                    verbose: verbose,
                    group: dispatchGroup,
                    operationQueue: operationQueue
                )

                processingQueue.async { operation.start() }
            }
        }
        dispatchGroup.wait()
        let end = Date()
        print("Took: \(end.timeIntervalSince(start)) seconds")
    }
}
