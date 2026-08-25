import Foundation

@MainActor
protocol ActivityObserver: AnyObject {
    func onUserActive()
    func onUserInactive()
}
