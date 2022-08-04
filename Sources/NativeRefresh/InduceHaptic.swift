import UIKit

/// Induce physical feedback with a given style.

func induceHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impact = UIImpactFeedbackGenerator(style: style)
    impact.impactOccurred()
}
