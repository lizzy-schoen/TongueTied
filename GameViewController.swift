import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        skView.isMultipleTouchEnabled = true
        skView.showsFPS = false
        skView.showsNodeCount = false

        // Keep the screen awake during gameplay
        UIApplication.shared.isIdleTimerDisabled = true

        if ScreenNameManager.needsInitialPrompt {
            // Show a blank scene while the name prompt is up
            let blank = SKScene(size: skView.bounds.size)
            blank.backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)
            blank.scaleMode = .aspectFill
            skView.presentScene(blank)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, let skView = self.view as? SKView else { return }
                ScreenNameManager.promptForScreenName(from: skView) { [weak self] in
                    self?.presentMainMenu()
                }
            }
        } else {
            presentMainMenu()
        }
    }

    private func presentMainMenu() {
        guard let skView = view as? SKView else { return }
        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene, transition: .fade(withDuration: 0.4))
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
}
