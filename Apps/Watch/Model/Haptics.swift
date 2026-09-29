import WatchKit

enum Haptics {
    enum Event {
        case logged, restWarning, restOver, holdMark, exerciseDone
        /// − or + on the set screen.
        case step
    }

    static func play(_ event: Event) {
        let type: WKHapticType = switch event {
        case .logged: .success
        case .restWarning: .notification
        case .restOver: .start
        case .holdMark: .directionUp
        case .exerciseDone: .success
        case .step: .click
        }
        WKInterfaceDevice.current().play(type)
    }
}
