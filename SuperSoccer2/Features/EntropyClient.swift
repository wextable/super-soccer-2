import ComposableArchitecture
import Foundation

@DependencyClient
struct EntropyClient: Sendable {
    var nextSeed: @Sendable () -> UInt64 = { 0 }
}

extension EntropyClient: DependencyKey {
    static let liveValue = EntropyClient(
        nextSeed: {
            var generator = SystemRandomNumberGenerator()
            return generator.next()
        }
    )
}

extension DependencyValues {
    var entropy: EntropyClient {
        get { self[EntropyClient.self] }
        set { self[EntropyClient.self] = newValue }
    }
}
