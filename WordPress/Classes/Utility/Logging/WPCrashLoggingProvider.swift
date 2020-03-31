import Foundation
import AutomatticTracks

fileprivate let UserOptedOutKey = "crashlytics_opt_out"

class WPCrashLoggingProvider: CrashLoggingDataProvider {

    var sentryDSN: String = ApiCredentials.sentryDSN()

    var buildType: String = BuildConfiguration.current.rawValue

    var userHasOptedOut: Bool {
        return UserDefaults.standard.bool(forKey: UserOptedOutKey)
    }

    var currentUser: TracksUser? {

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }

        return TracksUser(userID: account.userID.stringValue, email: account.email, username: account.username)
    }

    var loggingUploadDelegate: EventLoggingDelegate {
        return self
    }
}

extension WPCrashLoggingProvider: EventLoggingDelegate {
    var shouldUploadLogFiles: Bool {
        return
            !ProcessInfo.processInfo.isLowPowerModeEnabled
            && ReachabilityUtils.isInternetReachable()
    }
}

struct EventLoggingDataProvider: EventLoggingDataSource {

    init(previousSessionLogUrl url: URL?) {
        self.previousSessionLogPath = url
    }

    let loggingEncryptionKey: String = "6/Urz0lhTD4POD3KZuKnvsanDyKinPASDbw3mmQVFj0="

    let previousSessionLogPath: URL?

    static func fromDDFileLogger(_ logger: DDFileLogger) -> EventLoggingDataSource {
        let logFileData = logger.logFileManager.sortedLogFileInfos

        guard logFileData.count >= 2 else {
            return EventLoggingDataProvider(previousSessionLogUrl: nil)
        }

        // Index 0 would be the current log, so index 1 belongs to the previous session
        let previousLog = logger.logFileManager.sortedLogFileInfos[1]

        return EventLoggingDataProvider(previousSessionLogUrl: URL(fileURLWithPath: previousLog.filePath))

    }
}
