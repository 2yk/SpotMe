import SwiftUI

/// Apple's words for the 1 to 10 scale and the colour of each.
struct EffortBand {
    let word: String
    let color: Color

    init(_ effort: Int) {
        switch effort {
        case ...3: (word, color) = ("Easy", Theme.mint)
        case 4...6: (word, color) = ("Moderate", Theme.volt)
        case 7...8: (word, color) = ("Hard", Theme.ember)
        default: (word, color) = ("All Out", Theme.red)
        }
    }
}
