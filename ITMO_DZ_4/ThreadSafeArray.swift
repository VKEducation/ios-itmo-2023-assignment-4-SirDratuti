import Foundation

class RWLock {
    private var lock = pthread_rwlock_t()

    public init() {
        guard pthread_rwlock_init(&lock, nil) == 0 else {
            fatalError("can't create rwlock")
        }
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    @discardableResult
    func writeLock() -> Bool {
        pthread_rwlock_wrlock(&lock) == 0
    }

    @discardableResult
    func readLock() -> Bool {
        pthread_rwlock_rdlock(&lock) == 0
    }

    @discardableResult
    func unlock() -> Bool {
        pthread_rwlock_unlock(&lock) == 0
    }
}

class ThreadSafeArray<T> {
    private var array: [T] = []
    private let rwLock = RWLock()

    func index(after index: Index) -> Index {
        return array.index(after: index)
    }

    func append(_ newElement: Element) {
        rwLock.writeLock()
        defer { rwLock.unlock() }
        array.append(newElement)
    }

    func remove(at index: Index) -> Element {
        rwLock.writeLock()
        defer { rwLock.unlock() }
        return array.remove(at: index)
    }

    func dropFirst() -> Element {
        remove(at: 0)
    }
}

extension ThreadSafeArray: RandomAccessCollection {
    typealias Index = Int
    typealias Element = T

    var startIndex: Index {
        rwLock.readLock()
        defer { rwLock.unlock() }
        return array.startIndex
    }

    var endIndex: Index {
        rwLock.readLock()
        defer { rwLock.unlock() }
        return array.endIndex
    }

    subscript(index: Index) -> Element {
        get {
            rwLock.readLock()
            defer { rwLock.unlock() }
            return array[index]
        }

        set {
            rwLock.writeLock()
            defer { rwLock.unlock() }
            array[index] = newValue
        }
    }
}
