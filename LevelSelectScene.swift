import SpriteKit

class LevelSelectScene: SKScene {

    private var themeButton: SKShapeNode!
    private var cardStrokes: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)
        buildHeader()
        buildLevelGrid()
        buildThemeButton()
        buildBackButton()
    }

    // MARK: - Layout

    private func buildHeader() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Select Level"
        title.fontSize = 24
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(title)

        let total = ScoreManager.totalBestScore()
        let totalLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        totalLabel.text = "Total: \(total)"
        totalLabel.fontSize = 16
        totalLabel.fontColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 0.8)
        totalLabel.position = CGPoint(x: size.width / 2, y: size.height - 110)
        addChild(totalLabel)
    }

    private func buildLevelGrid() {
        let highestCompleted = ScoreManager.highestCompletedLevel()
        let cols = 2
        let cardW = size.width * 0.40
        let cardH: CGFloat = 120
        let spacingX: CGFloat = 15
        let spacingY: CGFloat = 15
        let totalW = CGFloat(cols) * cardW + CGFloat(cols - 1) * spacingX
        let startX = (size.width - totalW) / 2 + cardW / 2
        let startY = size.height - 180

        for (i, level) in Level.all.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (cardW + spacingX)
            let y = startY - CGFloat(row) * (cardH + spacingY)

            let isUnlocked = level.number == 1 || highestCompleted >= level.number - 1
            let best = ScoreManager.highScore(for: level.number)
            let passed = best >= level.targetScore

            buildCard(level: level, at: CGPoint(x: x, y: y),
                      width: cardW, height: cardH,
                      unlocked: isUnlocked, best: best, passed: passed)
        }
    }

    private func buildCard(level: Level, at pos: CGPoint,
                           width: CGFloat, height: CGFloat,
                           unlocked: Bool, best: Int, passed: Bool) {
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        let card = SKShapeNode(rect: rect, cornerRadius: 8)
        card.position = pos
        card.name = "level_\(level.number)"
        card.zPosition = 1

        if unlocked {
            card.fillColor = UIColor(white: 1, alpha: 0.08)
            card.strokeColor = ColorTheme.current.previewColor.withAlphaComponent(0.4)
        } else {
            card.fillColor = UIColor(white: 1, alpha: 0.03)
            card.strokeColor = UIColor(white: 1, alpha: 0.15)
        }
        card.lineWidth = 1.5
        cardStrokes.append(card)
        addChild(card)

        // Level number
        let numLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        numLabel.text = "\(level.number)"
        numLabel.fontSize = 28
        numLabel.fontColor = unlocked ? .white : UIColor(white: 0.4, alpha: 1)
        numLabel.position = CGPoint(x: 0, y: 20)
        numLabel.name = "level_\(level.number)"
        card.addChild(numLabel)

        // Level name
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        nameLabel.text = level.name
        nameLabel.fontSize = 13
        nameLabel.fontColor = unlocked ? UIColor(white: 0.85, alpha: 1) : UIColor(white: 0.35, alpha: 1)
        nameLabel.position = CGPoint(x: 0, y: -5)
        nameLabel.name = "level_\(level.number)"
        card.addChild(nameLabel)

        // High score or lock
        let infoLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        infoLabel.fontSize = 12
        infoLabel.position = CGPoint(x: 0, y: -28)
        infoLabel.name = "level_\(level.number)"
        if !unlocked {
            infoLabel.text = "🔒"
            infoLabel.fontColor = UIColor(white: 0.4, alpha: 1)
        } else if best > 0 {
            infoLabel.text = (passed ? "✓ " : "") + "\(best)"
            infoLabel.fontColor = passed
                ? UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1)
                : UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 0.7)
        } else {
            infoLabel.text = "—"
            infoLabel.fontColor = UIColor(white: 0.4, alpha: 1)
        }
        card.addChild(infoLabel)
    }

    private func buildBackButton() {
        let back = SKLabelNode(fontNamed: "AvenirNext-Medium")
        back.text = "< Menu"
        back.fontSize = 16
        back.fontColor = UIColor(white: 0.7, alpha: 1)
        back.position = CGPoint(x: size.width - 50, y: size.height - 60)
        back.horizontalAlignmentMode = .center
        back.name = "btn_back"
        back.zPosition = 50
        addChild(back)
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

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        if hypot(loc.x - themeButton.position.x, loc.y - themeButton.position.y) < 25 {
            cycleTheme()
            return
        }

        let tapped = atPoint(loc)
        let name = tapped.name ?? tapped.parent?.name ?? tapped.parent?.parent?.name

        if name == "btn_back" {
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))
            return
        }

        if let name, name.hasPrefix("level_"),
           let num = Int(name.replacingOccurrences(of: "level_", with: "")) {
            let highestCompleted = ScoreManager.highestCompletedLevel()
            guard num == 1 || highestCompleted >= num - 1 else { return }

            let scene = GameScene(size: size)
            scene.scaleMode = .aspectFill
            scene.gameMode = .level(number: num)
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))
        }
    }

    private func cycleTheme() {
        ColorTheme.cycleNext()
        themeButton.fillColor = ColorTheme.current.previewColor
        for card in cardStrokes {
            if card.strokeColor.cgColor.alpha > 0.2 {
                card.strokeColor = ColorTheme.current.previewColor.withAlphaComponent(0.4)
            }
        }
    }
}
