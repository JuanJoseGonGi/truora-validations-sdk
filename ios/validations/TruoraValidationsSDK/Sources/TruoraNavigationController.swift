import UIKit

/// Navigation controller that locks the SDK flow to portrait orientation,
/// regardless of the host app's supported orientations.
final class TruoraNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
