import ComposableArchitecture
import Foundation

/// In-memory career. Tests keep one of these and never touch the Application Support file.
actor CareerBox {
    private var stored: Career?

    func load() -> Career? { stored }

    func save(_ career: Career) {
        stored = career
    }

    func exists() -> Bool { stored != nil }
}

/// One file, `career.json`, in Application Support. The URL is resolved when a call runs.
private actor CareerDisk {
    private let urlOverride: URL?

    init(url: URL?) {
        urlOverride = url
    }

    func load() -> Career? {
        switch read() {
        case let .career(career):
            return career
        case let .incompatible(url):
            try? FileManager.default.removeItem(at: url)
            return nil
        case .missing, .unreadable:
            return nil
        }
    }

    func save(_ career: Career) {
        guard let url = try? fileURL(), let data = try? JSONEncoder().encode(career) else { return }
        let directory = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }
    }

    func exists() -> Bool {
        switch read() {
        case .career:
            return true
        case let .incompatible(url):
            try? FileManager.default.removeItem(at: url)
            return false
        case .missing, .unreadable:
            return false
        }
    }

    /// A file that is not the current career is deleted. Continue then has nothing to open.
    private func read() -> Read {
        guard let url = try? fileURL() else { return .unreadable }
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url) else { return .unreadable }
        do {
            return .career(try JSONDecoder().decode(Career.self, from: data))
        } catch is DecodingError {
            return .incompatible(url)
        } catch {
            return .unreadable
        }
    }

    private enum Read {
        case missing
        case unreadable
        case career(Career)
        case incompatible(URL)
    }

    private func fileURL() throws -> URL {
        if let urlOverride { return urlOverride }
        return try CareerLocation.liveURL()
    }
}

enum CareerLocation {
    /// The only career file. It lives in the app's Application Support directory.
    static let fileName = "career.json"

    static func liveURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }
}

private let testCareerBox = CareerBox()

@DependencyClient
struct CareerStore: Sendable {
    var load: @Sendable () async -> Career? = { await testCareerBox.load() }
    var save: @Sendable (_ career: Career) async -> Void = { await testCareerBox.save($0) }
    var exists: @Sendable () async -> Bool = { await testCareerBox.exists() }
}

extension CareerStore: DependencyKey {
    static let liveValue: CareerStore = {
        let disk = CareerDisk(url: nil)
        return CareerStore(
            load: { await disk.load() },
            save: { await disk.save($0) },
            exists: { await disk.exists() }
        )
    }()

    static let testValue = CareerStore.inMemory(testCareerBox)
    static let previewValue = CareerStore.inMemory()
}

extension CareerStore {
    static func inMemory(_ box: CareerBox = CareerBox()) -> CareerStore {
        CareerStore(
            load: { await box.load() },
            save: { await box.save($0) },
            exists: { await box.exists() }
        )
    }

    /// A career file at `url`. Tests pass a temporary URL.
    static func file(at url: URL) -> CareerStore {
        let disk = CareerDisk(url: url)
        return CareerStore(
            load: { await disk.load() },
            save: { await disk.save($0) },
            exists: { await disk.exists() }
        )
    }
}

extension DependencyValues {
    var careerStore: CareerStore {
        get { self[CareerStore.self] }
        set { self[CareerStore.self] = newValue }
    }
}
