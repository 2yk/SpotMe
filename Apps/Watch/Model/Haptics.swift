import WatchKit

enum Haptics {
    enum Event {
        case logged, restWarning, restOver, holdMark, exerciseDone
    }

    static func play(_ event: Event) {
        let type: WKHapticType = switch event {
        case .logged: .success
        case .restWarning: .notification
        case .restOver: .start
        case .holdMark: .directionUp
        case .exerciseDone: .success
        }
        WKInterfaceDevice.current().play(type)
    }
}
