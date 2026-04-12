import Foundation
import SpriteKit

final class GameScene: SKScene {
    var gameState: GameState {
        didSet {
            renderScene()
        }
    }

    private var playerNode = SKShapeNode(circleOfRadius: 18)
    private var ghostNode = SKShapeNode(circleOfRadius: 20)
    private var doorNode = SKShapeNode(rectOf: CGSize(width: 90, height: 20), cornerRadius: 6)
    private var turretNodes: [SKShapeNode] = []
    private var itemNodes: [SKShapeNode] = []
    private var lastTickTime: TimeInterval = 0

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 390, height: 780))
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupBaseScene()
        renderScene()
    }

    private func setupBaseScene() {
        removeAllChildren()

        let background = SKShapeNode(rect: CGRect(x: 20, y: 80, width: size.width - 40, height: size.height - 160), cornerRadius: 16)
        background.fillColor = .darkGray
        background.strokeColor = .lightGray
        background.lineWidth = 3
        addChild(background)

        doorNode.fillColor = .brown
        doorNode.strokeColor = .white
        doorNode.position = CGPoint(x: size.width / 2, y: 120)
        addChild(doorNode)

        playerNode.fillColor = .systemBlue
        playerNode.strokeColor = .white
        addChild(playerNode)

        ghostNode.fillColor = .systemRed
        ghostNode.strokeColor = .white
        addChild(ghostNode)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTickTime == 0 {
            lastTickTime = currentTime
        }

        let delta = currentTime - lastTickTime
        if delta < 1.0 { return }
        lastTickTime = currentTime

        advanceGameOneSecond()
        renderScene()
    }

    private func advanceGameOneSecond() {
        guard gameState.gameStatus == .playing else { return }

        gameState.gameTime += 1

        if gameState.player.isSleeping {
            gameState.player.gold += 20
        }

        if gameState.player.doorHealth > 0 {
            gameState.player.doorHealth = max(0, gameState.player.doorHealth - gameState.ghost.attackPower * 0.2)
        }

        if gameState.player.doorHealth <= 0 {
            gameState.gameStatus = .lost
        }

        if !gameState.turrets.isEmpty {
            let damage = gameState.turrets.reduce(Float(0)) { $0 + $1.damage }
            gameState.ghost.health = max(0, gameState.ghost.health - damage * 0.2)
        }

        if gameState.ghost.health <= 0 {
            gameState.gameStatus = .won
        }

        if gameState.items.count < 2 && Bool.random() {
            let item = Item(
                id: UUID().uuidString,
                type: .goldBoost,
                position: Position(x: Float.random(in: 1...5), y: Float.random(in: 1...5)),
                duration: 10,
                expiresAt: Date().addingTimeInterval(15)
            )
            gameState.items.append(item)
        }

        gameState.items = gameState.items.filter { $0.expiresAt > Date() }
    }

    private func renderScene() {
        let roomMinX: CGFloat = 40
        let roomMaxX: CGFloat = size.width - 40
        let roomMinY: CGFloat = 140
        let roomMaxY: CGFloat = size.height - 120

        func mapPosition(_ position: Position) -> CGPoint {
            let x = roomMinX + CGFloat(position.x / 6.0) * (roomMaxX - roomMinX)
            let y = roomMinY + CGFloat(position.y / 6.0) * (roomMaxY - roomMinY)
            return CGPoint(x: x, y: y)
        }

        playerNode.position = mapPosition(gameState.player.position)
        ghostNode.position = mapPosition(gameState.ghost.position)
        ghostNode.fillColor = gameState.ghost.isFrozen ? .cyan : .systemRed

        turretNodes.forEach { $0.removeFromParent() }
        turretNodes.removeAll()
        for turret in gameState.turrets {
            let node = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 4)
            node.fillColor = .systemGreen
            node.strokeColor = .white
            node.position = mapPosition(turret.position)
            addChild(node)
            turretNodes.append(node)
        }

        itemNodes.forEach { $0.removeFromParent() }
        itemNodes.removeAll()
        for item in gameState.items {
            let node = SKShapeNode(circleOfRadius: 10)
            node.fillColor = .systemYellow
            node.strokeColor = .white
            node.position = mapPosition(item.position)
            node.name = item.id
            addChild(node)
            itemNodes.append(node)
        }
    }
}
