//
//  Haptics.swift
//  padtap Watch App
//

import Foundation
#if os(watchOS)
import WatchKit
#endif

enum HapticEvent {
    case point
    case game
    case set
    case match
    case undo
}

@MainActor
protocol HapticProviding {
    func play(_ event: HapticEvent)
}

struct WatchHapticProvider: HapticProviding {
    func play(_ event: HapticEvent) {
        #if os(watchOS)
        let type: WKHapticType

        switch event {
        case .point:
            type = .click
        case .game:
            type = .directionUp
        case .set:
            type = .success
        case .match:
            type = .notification
        case .undo:
            type = .directionDown
        }

        WKInterfaceDevice.current().play(type)
        #endif
    }
}
