import Testing
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
}
