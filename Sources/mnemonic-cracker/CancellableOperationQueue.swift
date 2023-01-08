import Foundation

final class CancellableOperationQueue {

    private(set) var isCancelled = false

    func cancelAllOperations() {
        isCancelled = true
    }
}
