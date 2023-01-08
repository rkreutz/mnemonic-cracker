import ArgumentParser

enum WordCount: Int, CaseIterable, ExpressibleByArgument {
    case wc12 = 12
    case wc15 = 15
    case wc18 = 18
    case wc21 = 21
    case wc24 = 24

    var dataLength: Int {
        rawValue / 3 * 32
    }

    var checksumLength: Int {
        rawValue / 3
    }
}
