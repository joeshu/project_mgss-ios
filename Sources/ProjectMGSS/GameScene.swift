import Foundation
import SpriteKit

class GameScene: SKScene {
    var gameState: GameState
    var lastUpdateTime: TimeInterval = 0
    
    // 游戏逻辑更新频率
    let updateInterval: TimeInterval = 0.016 // ~60fps
    
    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 600, height: 600))
        backgroundColor = .darkGray
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupScene()
    }
    
    private func setupScene() {
        // 绘制房间边界
        let borderRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let border = SKShapeNode(rect: borderRect, cornerRadius: 0)
        border.strokeColor = .white
        border.lineWidth = 4
        addChild(border)
        
        // 绘制房门位置
        let doorPos = CGPoint(x: size.width / 2, y: size.height - 50)
        let door = SKSpriteNode(imageNamed: "door")
        door.position = doorPos
        door.size = CGSize(width: 100, height: 50)
        addChild(door)
        
        // 绘制玩家
        drawPlayer()
        
        // 绘制猛鬼
        drawGhost()
        
        // 绘制防御塔
        drawTurrets()
        
        // 绘制道具
        drawItems()
    }
    
    private func drawPlayer() {
        let playerNode = SKSpriteNode(color: .blue, size: CGSize(width: 40, height: 40))
        playerNode.position = CGPoint(x: gameState.player.position.x, y: gameState.player.position.y)
        playerNode.name = "player"
        addChild(playerNode)
        
        // 睡觉效果
        if gameState.player.isSleeping {
            let sleepEffect = SKSpriteNode(imageNamed: "sleep")
            sleepEffect.position = playerNode.position
            sleepEffect.zPosition = -1
            addChild(sleepEffect)
        }
    }
    
    private func drawGhost() {
        let ghostNode = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        ghostNode.position = CGPoint(x: gameState.ghost.position.x, y: gameState.ghost.position.y)
        ghostNode.name = "ghost"
        addChild(ghostNode)
        
        // 冻结效果
        if gameState.ghost.isFrozen {
            let frozenEffect = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 60))
            frozenEffect.position = ghostNode.position
            frozenEffect.zPosition = -1
            frozenEffect.alpha = 0.5
            addChild(frozenEffect)
        }
    }
    
    private func drawTurrets() {
        gameState.turrets.forEach { turret in
            let turretNode = SKSpriteNode(color: .green, size: CGSize(width: 30, height: 30))
            turretNode.position = CGPoint(x: turret.position.x, y: turret.position.y)
            turretNode.name = "turret-\(turret.position.x)-\(turret.position.y)"
            addChild(turretNode)
            
            // 绘制射程
            let rangeNode = SKShapeNode(circleOfRadius: CGFloat(turret.range))
            rangeNode.strokeColor = .green.withAlphaComponent(0.3)
            rangeNode.lineWidth = 1
            rangeNode.position = turretNode.position
            addChild(rangeNode)
        }
    }
    
    private func drawItems() {
        gameState.items.forEach { item in
            let itemNode = SKSpriteNode(color: .yellow, size: CGSize(width: 25, height: 25))
            itemNode.position = CGPoint(x: item.position.x, y: item.position.y)
            itemNode.name = "item-\(item.id)"
            addChild(itemNode)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if deltaTime < updateInterval { return }
        
        updateGameLogic(deltaTime)
        redrawScene()
    }
    
    private func updateGameLogic(_ deltaTime: TimeInterval) {
        guard gameState.gameStatus == .playing else { return }
        
        // 更新游戏时间
        gameState.gameTime += 1
        
        // 玩家睡觉获得金币
        if gameState.player.isSleeping {
            gameState.player.gold += 1
        }
        
        // 更新活跃效果
        updateActiveEffects()
        
        // 更新猛鬼 AI
        updateGhostAI()
        
        // 更新防御塔
        updateTurrets()
        
        // 生成道具
        spawnItems()
    }
    
    private func updateActiveEffects() {
        let now = Date()
        gameState.player.activeEffects = gameState.player.activeEffects.filter { $0.expiresAt > now }
        
        // 检查道具效果
        if let freezeItem = gameState.player.activeEffects.first(where: { $0.type == .freezeGhost }) {
            gameState.ghost.isFrozen = freezeItem.expiresAt > now
        }
    }
    
    private func updateGhostAI() {
        guard !gameState.ghost.isFrozen else { return }
        
        let ghost = gameState.ghost
        let player = gameState.player
        let doorPos = CGPoint(x: size.width / 2, y: size.height - 50)
        let doorInteractionDist: CGFloat = 40
        
        // 计算距离
        let dx = Float(ghost.position.x) - Float(player.position.x)
        let dy = Float(ghost.position.y) - Float(player.position.y)
        let dist = sqrt(dx * dx + dy * dy)
        
        if dist < 20 {
            // 捕获玩家
            gameState.gameStatus = .lost
            return
        }
        
        if ghost.state == .chasing {
            // 追踪玩家
            let moveStep = ghost.speed * deltaTime
            ghost.position.x += (Float(dx) / dist) * moveStep
            ghost.position.y += (Float(dy) / dist) * moveStep
        } else if ghost.state == .attacking {
            // 攻击房门
            let dxDoor = Float(doorPos.x) - ghost.position.x
            let dyDoor = Float(doorPos.y) - ghost.position.y
            let distDoor = sqrt(dxDoor * dxDoor + dyDoor * dyDoor)
            
            if distDoor < doorInteractionDist {
                // 攻击房门
                if !gameState.player.activeEffects.contains(where: { $0.type == .barrier }) {
                    let damage = ghost.attackPower * deltaTime
                    gameState.player.doorHealth -= damage
                    
                    if gameState.player.doorHealth <= 0 {
                        gameState.player.doorHealth = 0
                        gameState.player.isDoorBroken = true
                        gameState.gameStatus = .lost
                    }
                }
            } else {
                // 移动向房门
                let moveStep = ghost.speed * deltaTime
                ghost.position.x += (Float(dxDoor) / distDoor) * moveStep
                ghost.position.y += (Float(dyDoor) / distDoor) * moveStep
            }
        }
    }
    
    private func updateTurrets() {
        let ghostPos = CGPoint(x: gameState.ghost.position.x, y: gameState.ghost.position.y)
        
        gameState.turrets.forEach { turret in
            let turretPos = CGPoint(x: turret.position.x, y: turret.position.y)
            let dx = Float(ghostPos.x) - turret.position.x
            let dy = Float(ghostPos.y) - turret.position.y
            let dist = sqrt(dx * dx + dy * dy)
            
            if dist <= turret.range {
                // 射击
                if Date().timeIntervalSince(turret.lastShot) >= turret.cooldown {
                    gameState.ghost.health -= turret.damage
                    turret.lastShot = Date()
                    
                    if gameState.ghost.health <= 0 {
                        gameState.gameStatus = .won
                    }
                }
            }
        }
    }
    
    private func spawnItems() {
        let now = Date()
        
        // 限制道具数量
        if gameState.items.count < 3 && Double.random(in: 0...1) < 0.005 {
            let types: [Item.ItemType] = [.speedUp, .goldBoost, .doorRepair, .freezeGhost, .invincible, .barrier, .slowTrap]
            let type = types.randomElement()!
            
            let item = Item(
                id: UUID().uuidString,
                type: type,
                position: Position(
                    x: Float.random(in: 1...5),
                    y: Float.random(in: 1...5)
                ),
                duration: 10,
                expiresAt: now.addingTimeInterval(15)
            )
            
            gameState.items.append(item)
        }
        
        // 清理过期道具
        gameState.items = gameState.items.filter { $0.expiresAt > now }
        
        // 检测玩家拾取
        let playerPos = gameState.player.position
        gameState.items = gameState.items.filter { item in
            let dx = Float(playerPos.x) - item.position.x
            let dy = Float(playerPos.y) - item.position.y
            let dist = sqrt(dx * dx + dy * dy)
            
            if dist < 0.5 {
                applyItemEffect(item)
                return false
            }
            return true
        }
    }
    
    private func applyItemEffect(_ item: Item) {
        switch item.type {
        case .doorRepair:
            gameState.player.doorHealth = min(gameState.player.doorMaxHealth, gameState.player.doorHealth + 500)
        case .freezeGhost:
            gameState.player.activeEffects.append(ActiveEffect(type: .freezeGhost, expiresAt: Date().addingTimeInterval(TimeInterval(item.duration))))
        case .barrier:
            gameState.player.activeEffects.append(ActiveEffect(type: .barrier, expiresAt: Date().addingTimeInterval(TimeInterval(item.duration))))
        default:
            gameState.player.activeEffects.append(ActiveEffect(type: item.type, expiresAt: Date().addingTimeInterval(TimeInterval(item.duration))))
        }
    }
    
    private func redrawScene() {
        // 清除所有节点
        let nodesToRemove = children.filter { $0.name != nil }
        nodesToRemove.forEach { $0.removeFromParent() }
        
        // 重新绘制
        setupScene()
    }
}
