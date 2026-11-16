import Testing
import UIKit
@testable import Overlays

@MainActor
struct ToastStoreTests {

    @Test(arguments: [
        "Cancelled",
        "Canceled",
        "The operation couldn’t be completed. (Swift.CancellationError error 1.)",
        "The operation couldn’t be completed. (NSURLErrorDomain error -999.)"
    ])
    func cancellationErrorsAreNotStored(message: String) {
        let store = ToastStore()

        store.show(message, style: .error, duration: 0)

        #expect(store.toasts.isEmpty)
    }

    @Test func ordinaryErrorsAreStored() {
        let store = ToastStore()

        store.show("Couldn’t load addresses", style: .error, duration: 0)

        #expect(store.toasts.map(\.message) == ["Couldn’t load addresses"])
    }

    @Test(arguments: [
        "The operation couldn’t be completed. (NSURLErrorDomain error -9990.)",
        "The operation couldn’t be completed. (NSURLErrorDomain error -9999.)"
    ])
    func nearbyURLLoadingErrorCodesAreStored(message: String) {
        let store = ToastStore()

        store.show(message, style: .error, duration: 0)

        #expect(store.toasts.map(\.message) == [message])
    }

    @Test func nonErrorCancellationCopyIsStored() {
        let store = ToastStore()

        store.show("Cancelled", style: .info, duration: 0)

        #expect(store.toasts.map(\.message) == ["Cancelled"])
    }

    @Test func aFourthToastDropsTheOldestAndKeepsTheRestInOrder() {
        let store = ToastStore()

        for message in ["one", "two", "three", "four"] {
            store.show(message, duration: 0)
        }

        #expect(store.toasts.map(\.message) == ["two", "three", "four"])
    }

    @Test func placementsTrimIndependently() {
        let store = ToastStore()

        for message in ["one", "two", "three", "four"] {
            store.show(message, duration: 0)
        }
        store.show("pinned", placement: .bottom, duration: 0)

        #expect(store.toasts.filter { $0.placement == .top }.map(\.message) == ["two", "three", "four"])
        #expect(store.toasts.filter { $0.placement == .bottom }.map(\.message) == ["pinned"])
    }

    @Test func eachToastExpiresOnItsOwnClock() async throws {
        let store = ToastStore()

        store.show("first", duration: 0.4)
        try await Task.sleep(for: .milliseconds(200))
        store.show("second", duration: 0.4)

        try await Task.sleep(for: .milliseconds(300))          // 0.5 s after the first
        #expect(store.toasts.map(\.message) == ["second"])

        try await Task.sleep(for: .milliseconds(400))          // 0.9 s after the first, 0.7 after the second
        #expect(store.toasts.isEmpty)
    }

    @Test func theStackDropsEachToastWhenItsOwnClockExpires() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let store = ToastStore()
        let host = ToastHost(store: store)
        root.view.addSubviews(host)
        host.pinEdgesToSuperview()
        window.layoutIfNeeded()

        store.show("first", duration: 0.4)
        try await Task.sleep(for: .milliseconds(200))
        store.show("second", duration: 0.4)

        try await Task.sleep(for: .milliseconds(300))
        window.layoutIfNeeded()
        let firstCheck = visibleToastCount(in: host)
        #expect(firstCheck == 1, "the first toast was still visible after its own expiry")

        try await Task.sleep(for: .milliseconds(700))
        window.layoutIfNeeded()
        #expect(visibleToastCount(in: host) == 0)
    }

    private func visibleToastCount(in host: ToastHost) -> Int {
        host.subviews
            .compactMap { $0 as? ToastStackView }
            .reduce(0) { $0 + $1.capsuleFrames(in: host).count }
    }
}
