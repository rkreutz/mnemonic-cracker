import CryptoSwift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class CheckMnemonicOperation {

    private let mnemonic: [String]
    private let wordList: [String: Int]
    private let wordCount: WordCount
    private let userPassword: String
    private let address: String?
    private let verbose: Bool
    private let group: DispatchGroup
    private weak var operationQueue: CancellableOperationQueue?
    var isCancelled = false

    init(mnemonic: [String], wordList: [String: Int], wordCount: WordCount, userPassword: String, address: String?, verbose: Bool, group: DispatchGroup, operationQueue: CancellableOperationQueue) {
        self.mnemonic = mnemonic
        self.wordList = wordList
        self.wordCount = wordCount
        self.userPassword = userPassword
        self.address = address
        self.verbose = verbose
        self.group = group
        self.operationQueue = operationQueue
        group.enter()
    }

    func start() {
        defer { group.leave() }
        guard !isCancelled else { return }
        let seed = try! mnemonic.flatMap { try wordList.bits(for: $0) }.joined(separator: "")
        guard seed.count == wordCount.dataLength + wordCount.checksumLength else { fatalError(ValidationError.invalidSeedLength.localizedDescription) }
        let checksum = String(seed.suffix(wordCount.checksumLength))
        let data = String(seed.prefix(wordCount.dataLength))
        let dataBytes = try! data.bitStringToBytes()
        if #available(macOS 10.15, *) {
            guard !isCancelled else { return }
            let sha256 = SHA2(variant: .sha256)
            let digest = Data(sha256.calculate(for: dataBytes.bytes))
            if String(digest.toBitArray().prefix(wordCount.checksumLength)) == checksum {
                if verbose || address == nil {
                    print(mnemonic.joined(separator: " "))
                }

                let password = mnemonic.joined(separator: " ").data(using: .utf8).unsafelyUnwrapped
                guard let salt = ("mnemonic" + userPassword).data(using: .utf8) else { fatalError(ValidationError.invalidSalt.localizedDescription) }

                guard !isCancelled else { return }
                let pbkdf = try! PKCS5.PBKDF2(
                    password: password.bytes,
                    salt: salt.bytes,
                    iterations: 2048,
                    keyLength: 64, variant: .sha2(.sha512)
                )

                let data = Data(try! pbkdf.calculate())

                guard !isCancelled else { return }

                guard
                    let hdWallet = HDNode.init(seed: data),
                    let metamaskNode = hdWallet.derive(path: HDNode.defaultPathMetamask),
                    let metamaskAddress = Utilities.publicToAddressString(metamaskNode.publicKey)
                else { fatalError(ValidationError.invalidHDNode.localizedDescription) }

                if verbose || address == nil {
                    print("Metamask address: \(metamaskAddress)")
                }

                if let address = address,
                   metamaskAddress.lowercased() == address.lowercased() {
                    print("Found candidate:")
                    print(mnemonic.joined(separator: " "))
                    print("Private key: \(metamaskNode.privateKey.unsafelyUnwrapped.toHexString())")
                    print(address)
                    operationQueue?.cancelAllOperations()
                } else if address == nil {
                    guard !isCancelled else { return }
                    group.enter()
                    URLSession.shared.dataTask(with: URL(string: "https://api.debank.com/hi/user/info?id=\(metamaskAddress)").unsafelyUnwrapped) { [group, mnemonic] data, _, _ in
                        defer { group.leave() }
                        guard
                            let data = data,
                            let dto = try? JSONDecoder().decode(DTO.self, from: data),
                            dto.data.user.usd_value > 0
                        else { return }
                        print("****** Address \(metamaskAddress) got \(dto.data.user.usd_value) USD")
                        print(mnemonic.joined(separator: " "))
                        print("Private key: \(metamaskNode.privateKey.unsafelyUnwrapped.toHexString())")
                    }.resume()
                }
            }
        } else {
            fatalError(ValidationError.pbkdf2DerivationError(nil).localizedDescription)
        }
    }
}

private extension Dictionary where Key == String, Value == Int {
    func bits(for word: String) throws -> String {
        guard let index = self[word] else { throw ValidationError.invalidWord }
        let binaryString = String(index, radix: 2)
        let paddingCount = 11 - binaryString.count
        return String(repeating: "0", count: paddingCount) + binaryString
    }
}

private extension String {
    func bitStringToBytes() throws -> Data {
        let length = 8
        guard count % length == 0 else {
            throw ValidationError.invalidByteConversion
        }
        var data = Data(capacity: count)

        for i in 0 ..< count / length {
            let startIdx = self.index(startIndex, offsetBy: i * length)
            let subArray = self[startIdx ..< self.index(startIdx, offsetBy: length)]
            let subString = String(subArray)
            guard let byte = UInt8(subString, radix: 2) else {
                throw ValidationError.invalidByteConversion
            }
            data.append(byte)
        }
        return data
    }
}

private extension Data {

    func toBitArray() -> String {
        var toReturn = [String]()
        for num in [UInt8](self) {
            toReturn.append(contentsOf: num.mnemonicBits())
        }

        return toReturn.joined(separator: "")
    }

}

private extension UInt8 {

    func mnemonicBits() -> [String] {
        let totalBitsCount = MemoryLayout<UInt8>.size * 8

        var bitsArray = [String](repeating: "0", count: totalBitsCount)

        for j in 0 ..< totalBitsCount {
            let bitVal: UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
            let check = self & bitVal

            if check != 0 {
                bitsArray[j] = "1"
            }
        }

        return bitsArray
    }
}

private struct DTO: Decodable {
    struct Data: Decodable {
        var user: User
    }
    struct User: Decodable {
        var usd_value: Double
    }
    var data: Data
}
