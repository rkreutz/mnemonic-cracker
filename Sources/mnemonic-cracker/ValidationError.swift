import Foundation

enum ValidationError: Error {
    case invalidWordCount
    case invalidSeedLength
    case invalidWord
    case invalidByteConversion
    case invalidSalt
    case pbkdf2DerivationError(Int32??)
    case invalidHDNode
}
