import UIKit

/// Induce physical feedback with a given style.
@available(iOS 14.3, *)
func induceHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impact = UIImpactFeedbackGenerator(style: style)
    impact.impactOccurred()
}
