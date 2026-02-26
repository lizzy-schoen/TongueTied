import SpriteKit

class MainMenuScene: SKScene {

    private var themeButton: SKShapeNode!
    private var screenNameLabel: SKLabelNode!
    private var buttonStrokes: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)
        buildTitle()
        buildMenuButtons()
        buildThemeButton()
        buildScreenNameDisplay()
    }

    // MARK: - Layout

    private func buildTitle() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "TongueTied"
        title.fontSize = 38
        title.fontColor = ColorTheme.current.previewColor
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        addChild(title)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text = "learn by touch"
        sub.fontSize = 16
        sub.fontColor = UIColor(white: 0.6, alpha: 1)
        sub.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        addChild(sub)
    }

    private func buildMenuButtons() {
        let buttons: [(String, String, CGFloat)] = [
            ("Levels",       "btn_levels",      0.52),
            ("Don't Stop",   "btn_dontstop",    0.42),
            ("Leaderboard",  "btn_leaderboard", 0.32),
        ]

        for (text, name, yFrac) in buttons {
            let w: CGFloat = 220
            let h: CGFloat = 50
            let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
            let bg = SKShapeNode(rect: rect, cornerRadius: 12)
            bg.fillColor = UIColor(white: 1, alpha: 0.08)
            bg.strokeColor = ColorTheme.current.previewColor.withAlphaComponent(0.5)
            bg.lineWidth = 1.5
            bg.position = CGPoint(x: size.width / 2, y: size.height * yFrac)
            bg.name = name
            bg.zPosition = 1
            buttonStrokes.append(bg)
            addChild(bg)

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = text
            label.fontSize = 20
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.name = name
            bg.addChild(label)
        }
    }

    private func buildThemeButton() {
        let top = size.height - 60
        themeButton = SKShapeNode(circleOfRadius: 14)
        themeButton.fillColor = ColorTheme.current.previewColor
        themeButton.strokeColor = UIColor(white: 0.5, alpha: 0.8)
        themeButton.lineWidth = 2
        themeButton.position = CGPoint(x: 40, y: top)
        themeButton.zPosition = 50
        addChild(themeButton)
    }

    private func buildScreenNameDisplay() {
        screenNameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        screenNameLabel.fontSize = 14
        screenNameLabel.fontColor = UIColor(white: 0.5, alpha: 1)
        screenNameLabel.position = CGPoint(x: size.width / 2, y: 80)
        screenNameLabel.name = "btn_screenname"
        updateScreenNameText()
        addChild(screenNameLabel)
    }

    private func updateScreenNameText() {
        if let name = ScreenNameManager.current, !name.isEmpty {
            screenNameLabel.text = "\(name)  ✎"
        } else {
            screenNameLabel.text = "Tap to set name"
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        // Theme button
        if hypot(loc.x - themeButton.position.x, loc.y - themeButton.position.y) < 25 {
            cycleTheme()
            return
        }

        let tapped = atPoint(loc)
        let name = tapped.name ?? tapped.parent?.name

        switch name {
        case "btn_levels":
            let scene = LevelSelectScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))

        case "btn_dontstop":
            let scene = GameScene(size: size)
            scene.scaleMode = .aspectFill
            scene.gameMode = .dontStop
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))

        case "btn_leaderboard":
            let scene = LeaderboardScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))

        case "btn_screenname":
            guard let v = view else { return }
            ScreenNameManager.promptForScreenName(from: v) { [weak self] in
                self?.updateScreenNameText()
            }

        default: break
        }
    }

    private func cycleTheme() {
        ColorTheme.cycleNext()
        themeButton.fillColor = ColorTheme.current.previewColor
        for btn in buttonStrokes {
            btn.strokeColor = ColorTheme.current.previewColor.withAlphaComponent(0.5)
        }
    }
}
