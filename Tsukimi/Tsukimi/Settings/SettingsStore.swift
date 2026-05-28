import Combine
import Foundation

final class SettingsStore: ObservableObject {
    let storageSettingsChanged = PassthroughSubject<Void, Never>()

    @Published var showShelfAfterCapture: Bool {
        didSet { defaults.set(showShelfAfterCapture, forKey: Key.showShelfAfterCapture) }
    }

    @Published var autoHideShelf: Bool {
        didSet { defaults.set(autoHideShelf, forKey: Key.autoHideShelf) }
    }

    @Published var autoHideDelay: TimeInterval {
        didSet { defaults.set(autoHideDelay, forKey: Key.autoHideDelay) }
    }

    @Published var maxUnpinnedScreenshots: Int {
        didSet {
            defaults.set(maxUnpinnedScreenshots, forKey: Key.maxUnpinnedScreenshots)
            storageSettingsChanged.send()
        }
    }

    @Published var deleteUnpinnedAfterHours: Int {
        didSet {
            defaults.set(deleteUnpinnedAfterHours, forKey: Key.deleteUnpinnedAfterHours)
            storageSettingsChanged.send()
        }
    }

    @Published var copyImageOnCapture: Bool {
        didSet { defaults.set(copyImageOnCapture, forKey: Key.copyImageOnCapture) }
    }

    var unpinnedLifetime: TimeInterval {
        TimeInterval(deleteUnpinnedAfterHours * 60 * 60)
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        showShelfAfterCapture = defaults.object(forKey: Key.showShelfAfterCapture) as? Bool ?? true
        autoHideShelf = defaults.object(forKey: Key.autoHideShelf) as? Bool ?? true
        autoHideDelay = defaults.object(forKey: Key.autoHideDelay) as? TimeInterval ?? 8
        maxUnpinnedScreenshots = defaults.object(forKey: Key.maxUnpinnedScreenshots) as? Int ?? 25
        deleteUnpinnedAfterHours = defaults.object(forKey: Key.deleteUnpinnedAfterHours) as? Int ?? 24
        copyImageOnCapture = defaults.object(forKey: Key.copyImageOnCapture) as? Bool ?? false
    }

    private enum Key {
        static let showShelfAfterCapture = "showShelfAfterCapture"
        static let autoHideShelf = "autoHideShelf"
        static let autoHideDelay = "autoHideDelay"
        static let maxUnpinnedScreenshots = "maxUnpinnedScreenshots"
        static let deleteUnpinnedAfterHours = "deleteUnpinnedAfterHours"
        static let copyImageOnCapture = "copyImageOnCapture"
    }
}
