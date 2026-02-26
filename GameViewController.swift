import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill

        skView.presentScene(scene)
        skView.isMultipleTouchEnabled = true

        skView.showsFPS = false
        skView.showsNodeCount = false

        // Keep the screen awake during gameplay
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
}
