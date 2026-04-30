import Foundation
import SpriteKit

private enum MGSSScenePalette {
    static let boardFill = SKColor(red: 0.055, green: 0.050, blue: 0.105, alpha: 0.98)
    static let boardStroke = SKColor(red: 0.48, green: 0.34, blue: 0.78, alpha: 0.88)
    static let corridorFill = SKColor(red: 0.105, green: 0.090, blue: 0.175, alpha: 1.0)
    static let corridorStroke = SKColor(red: 0.34, green: 0.28, blue: 0.50, alpha: 1.0)
    static let roomFill = SKColor(red: 0.095, green: 0.088, blue: 0.155, alpha: 0.94)
    static let selectedRoomFill = SKColor(red: 0.235, green: 0.175, blue: 0.118, alpha: 1.0)
    static let selected = SKColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 0.98)
    static let utility = SKColor(red: 0.45, green: 0.92, blue: 1.0, alpha: 1.0)
    static let danger = SKColor(red: 0.94, green: 0.10, blue: 0.14, alpha: 1.0)
    static let warning = SKColor(red: 1.0, green: 0.62, blue: 0.18, alpha: 1.0)
    static let safe = SKColor(red: 0.45, green: 1.0, blue: 0.62, alpha: 1.0)
}

final class GameScene: SKScene {
    var gameState: GameState {
        didSet { renderScene() }
    }

    var onStateChange: ((GameState) -> Void)?

    private let surviveSeconds = 180
    private var playerNode = SKShapeNode(circleOfRadius: 17)
    private var ghostNode = SKShapeNode()
    private var doorNode = SKShapeNode(rectOf: CGSize(width: 110, height: 24), cornerRadius: 6)
    private var bedNode = SKShapeNode(rectOf: CGSize(width: 74, height: 44), cornerRadius: 9)
    private var auraNode = SKShapeNode(circleOfRadius: 31)
    private var ghostPressureRing = SKShapeNode(circleOfRadius: 34)
    private var threatPathNode = SKShapeNode()
    private var turretNodes: [SKNode] = []
    private var itemNodes: [SKNode] = []
    private var labelNodes: [SKNode] = []
    private var dynamicBaseNodes: [SKNode] = []
    private var lastTickTime: TimeInterval = 0

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 390, height: 780))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.backgroundColor = .clear
        setupBaseScene()
        renderScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        setupBaseScene()
        renderScene()
    }

    private func setupBaseScene() {
        removeAllChildren()
        dynamicBaseNodes.removeAll()

        let playRect = boardRect()
        addIsoDormBackdrop(in: playRect)
        addIsoCorridor(in: playRect)
        addRoomGrid(in: playRect)
        if gameState.phase == .nightDefense {
            addBuildSlotHints(in: playRect)
        }

        doorNode.strokeColor = MGSSScenePalette.warning.withAlphaComponent(0.65)
        doorNode.lineWidth = 1.5
        doorNode.alpha = 0.01
        addChild(doorNode)

        bedNode.strokeColor = MGSSScenePalette.utility.withAlphaComponent(0.50)
        bedNode.lineWidth = 1.2
        bedNode.alpha = 0.01
        addChild(bedNode)

        threatPathNode.strokeColor = MGSSScenePalette.danger.withAlphaComponent(0.42)
        threatPathNode.lineWidth = 3
        threatPathNode.glowWidth = 5
        threatPathNode.zPosition = 6
        addChild(threatPathNode)

        auraNode.fillColor = SKColor(red: 0.18, green: 0.75, blue: 1.0, alpha: 0.10)
        auraNode.strokeColor = MGSSScenePalette.utility.withAlphaComponent(0.45)
        auraNode.lineWidth = 2
        auraNode.zPosition = 7
        addChild(auraNode)

        playerNode.fillColor = .systemBlue
        playerNode.strokeColor = .white
        playerNode.lineWidth = 2
        addChild(playerNode)

        ghostNode.path = originalGhostPath()
        ghostNode.fillColor = .systemRed
        ghostNode.strokeColor = SKColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        ghostNode.lineWidth = 3
        ghostNode.glowWidth = 4
        ghostNode.zPosition = 12
        ghostNode.removeAllChildren()
        addGhostFaceDetails(to: ghostNode)
        addChild(ghostNode)

        ghostPressureRing.fillColor = .clear
        ghostPressureRing.strokeColor = MGSSScenePalette.danger.withAlphaComponent(0.62)
        ghostPressureRing.lineWidth = 3
        ghostPressureRing.glowWidth = 8
        addChild(ghostPressureRing)
    }

    private func boardRect() -> CGRect {
        let compact = size.height < 720 || size.width < 380
        let landscape = size.width > size.height
        let topReserve: CGFloat = landscape ? 82 : (compact ? 214 : 236)
        let bottomReserve: CGFloat = landscape ? 76 : (compact ? 172 : 194)
        let minY = max(58, bottomReserve)
        let visibleMaxY = max(minY + 160, size.height - topReserve)
        let clampedMaxY = min(size.height - 24, visibleMaxY)
        return CGRect(
            x: compact ? 12 : 18,
            y: minY,
            width: max(40, size.width - (compact ? 24 : 36)),
            height: max(160, clampedMaxY - minY)
        )
    }

    private func addRoomGrid(in rect: CGRect) {
        for room in DormRoom.allCases {
            let roomRect = dormRoomRect(for: room)
            let isSelected = room.id == gameState.selectedRoom.id
            addIsoDormRoom(room, roomRect: roomRect, isSelected: isSelected)
        }
    }

    private func addCorridorTiles(in rect: CGRect) {
        let centerX = rect.midX
        let tileCount = 8
        for index in 0..<tileCount {
            let tile = SKShapeNode(rectOf: CGSize(width: 70, height: 18), cornerRadius: 5)
            tile.fillColor = SKColor(red: 0.16, green: 0.13, blue: 0.23, alpha: index % 2 == 0 ? 0.85 : 0.55)
            tile.strokeColor = SKColor(red: 0.36, green: 0.29, blue: 0.48, alpha: 0.45)
            tile.lineWidth = 1
            tile.position = CGPoint(x: centerX, y: rect.minY + 68 + CGFloat(index) * max(30, rect.height / 9))
            addChild(tile)
            dynamicBaseNodes.append(tile)
        }
    }

    private func addCorridorCenterGuide(in rect: CGRect) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 48))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 48))
        let guide = SKShapeNode(path: path)
        guide.strokeColor = MGSSScenePalette.utility.withAlphaComponent(0.16)
        guide.lineWidth = 1
        addChild(guide)
        dynamicBaseNodes.append(guide)
    }

    private func addBuildSlotHints(in rect: CGRect) {
        let occupied = Set(gameState.turrets.map { "\($0.position.x)-\($0.position.y)" })
        for slot in gameState.selectedRoom.turretSlots.prefix(3) {
            let key = "\(slot.x)-\(slot.y)"
            let isOccupied = occupied.contains(key)
            let base = SKShapeNode(path: isoDiamondPath(width: 44, height: 22))
            base.position = mapPosition(slot)
            base.fillColor = isOccupied ? MGSSScenePalette.safe.withAlphaComponent(0.26) : SKColor(red: 0.06, green: 0.12, blue: 0.14, alpha: 0.64)
            base.strokeColor = (isOccupied ? MGSSScenePalette.safe : MGSSScenePalette.utility).withAlphaComponent(0.72)
            base.lineWidth = 1.5
            base.glowWidth = isOccupied ? 3 : 1
            base.zPosition = 7
            addChild(base)
            dynamicBaseNodes.append(base)

            if !isOccupied {
                let bolt = makeLabel("+", size: 14, color: MGSSScenePalette.utility.withAlphaComponent(0.92))
                bolt.position = CGPoint(x: base.position.x, y: base.position.y + 1)
                bolt.zPosition = 8
                addChild(bolt)
                dynamicBaseNodes.append(bolt)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTickTime == 0 { lastTickTime = currentTime }
        let delta = currentTime - lastTickTime
        if delta < 1.0 { return }
        lastTickTime = currentTime

        advanceGameOneSecond()
        onStateChange?(gameState)
        renderScene()
    }

    private func advanceGameOneSecond() {
        guard gameState.gameStatus == .playing, gameState.phase == .nightDefense else { return }

        let now = Date()
        gameState.gameTime += 1
        gameState.player.position = gameState.selectedRoom.playerPosition
        gameState.player.activeEffects = gameState.player.activeEffects.filter { $0.expiresAt > now }
        if gameState.ghost.isFrozen && gameState.ghost.frozenUntil <= now { gameState.ghost.isFrozen = false }

        let hasGoldBoost = hasEffect(.goldBoost)
        let hasBarrier = hasEffect(.barrier) || hasEffect(.invincible)
        let hasSlowTrap = hasEffect(.slowTrap)

        if gameState.player.isSleeping {
            let baseGoldIncome = 12 + gameState.player.bedLevel * 10 + gameState.selectedRoom.rewardBonus
            let goldIncome = hasGoldBoost ? baseGoldIncome * 2 : baseGoldIncome
            gameState.player.gold += goldIncome
            gameState.player.electricity += max(1, gameState.player.bedLevel / 2)
        }

        if gameState.gameTime % 30 == 0 {
            gameState.wave += 1
            gameState.ghost.attackPower += Float(7 + gameState.selectedRoom.risk)
            gameState.ghost.speed += 0.08
            gameState.ghost.maxHealth += Float(70 + gameState.selectedRoom.risk * 10)
            gameState.ghost.health = min(gameState.ghost.maxHealth, gameState.ghost.health + 80)
        }

        moveGhostTowardRoomDoor(slowed: hasSlowTrap)
        updateGhostState()

        if (gameState.ghost.state == .attacking || gameState.ghost.state == .enraged) && !gameState.ghost.isFrozen && !hasBarrier {
            let armorReduction = min(Float(gameState.player.doorLevel - 1) * 0.07, 0.35)
            let rageMultiplier: Float = gameState.ghost.state == .enraged ? 1.22 : 1.0
            let damage = gameState.ghost.attackPower * rageMultiplier * (1.0 - armorReduction)
            gameState.player.doorHealth = max(0, gameState.player.doorHealth - damage)
        }

        fireTurrets(now: now)

        if gameState.player.doorHealth <= 0 {
            gameState.player.isDoorBroken = true
            gameState.gameStatus = .lost
        }

        if gameState.ghost.health <= 0 || gameState.gameTime >= surviveSeconds {
            gameState.gameStatus = .won
        }

        maybeSpawnItem(now: now)
        gameState.items = gameState.items.filter { $0.expiresAt > now }
    }

    private func moveGhostTowardRoomDoor(slowed: Bool) {
        guard !gameState.ghost.isFrozen else { return }
        let target = gameState.selectedRoom.doorPosition
        let step = max(0.03, gameState.ghost.speed / (slowed ? 122.0 : 82.0))
        let dx = target.x - gameState.ghost.position.x
        let dy = target.y - gameState.ghost.position.y
        gameState.ghost.position.x += max(-step, min(step, dx))
        gameState.ghost.position.y += max(-step, min(step, dy))
    }

    private func updateGhostState() {
        if gameState.ghost.position.distance(to: gameState.selectedRoom.doorPosition) <= 0.18 {
            gameState.ghost.state = gameState.gameTime > 120 ? .enraged : .attacking
        } else if gameState.gameTime < 16 {
            gameState.ghost.state = .scouting
        } else {
            gameState.ghost.state = .approaching
        }
    }

    private func fireTurrets(now: Date) {
        for index in gameState.turrets.indices {
            let turret = gameState.turrets[index]
            guard turret.position.distance(to: gameState.ghost.position) <= turret.range else { continue }
            guard now.timeIntervalSince(turret.lastShot) >= turret.cooldown else { continue }

            let damage = turret.damage + Float(turret.level - 1) * 18.0
            gameState.ghost.health = max(0, gameState.ghost.health - damage)
            gameState.turrets[index].lastShot = now
            renderLaser(from: mapPosition(turret.position), to: mapPosition(gameState.ghost.position))
        }
    }

    private func maybeSpawnItem(now: Date) {
        guard gameState.items.count < 3 else { return }
        guard Int.random(in: 1...100) <= 18 else { return }

        let type = Item.ItemType.allCases.randomElement() ?? .goldBoost
        let slot = gameState.selectedRoom.turretSlots.randomElement() ?? gameState.selectedRoom.playerPosition
        let item = Item(id: UUID().uuidString, type: type, position: slot, duration: 10, expiresAt: now.addingTimeInterval(16))
        gameState.items.append(item)
    }

    private func hasEffect(_ type: Item.ItemType) -> Bool {
        gameState.player.activeEffects.contains { $0.type == type && $0.expiresAt > Date() }
    }

    private func renderScene() {
        playerNode.position = mapPosition(gameState.player.position)
        auraNode.position = playerNode.position
        auraNode.isHidden = !gameState.player.isSleeping || gameState.phase == .choosingRoom
        updateThreatPath()
        ghostNode.position = mapPosition(gameState.ghost.position)
        ghostNode.fillColor = gameState.ghost.isFrozen ? .cyan : MGSSScenePalette.danger
        ghostNode.isHidden = gameState.phase == .choosingRoom
        ghostNode.setScale(gameState.ghost.state == .enraged ? 1.18 : (isBreakingDoor ? 1.08 : 1.0))
        ghostNode.alpha = gameState.ghost.isFrozen ? 0.72 : 1.0
        ghostPressureRing.position = ghostNode.position
        ghostPressureRing.isHidden = gameState.ghost.isFrozen || gameState.phase == .choosingRoom || !isBreakingDoor
        ghostPressureRing.setScale(isBreakingDoor ? 1.24 : 1.0)
        ghostPressureRing.alpha = isBreakingDoor ? 0.72 : 0.0
        doorNode.position = mapPosition(gameState.selectedRoom.doorPosition)
        doorNode.fillColor = doorColor()
        doorNode.setScale(isBreakingDoor ? 1.05 : 1.0)
        bedNode.position = mapPosition(gameState.selectedRoom.playerPosition)
        bedNode.fillColor = bedColor()

        turretNodes.forEach { $0.removeFromParent() }
        turretNodes.removeAll()
        for turret in gameState.turrets {
            let turretNode = makeIsoTurretNode(for: turret)
            turretNode.position = mapPosition(turret.position)
            addChild(turretNode)
            turretNodes.append(turretNode)
        }

        itemNodes.forEach { $0.removeFromParent() }
        itemNodes.removeAll()
        for item in gameState.items {
            let node = makePickupNode(for: item)
            node.position = mapPosition(item.position)
            node.name = item.id
            addChild(node)
            itemNodes.append(node)
        }

        renderStatusLabels()
    }

    private var isBreakingDoor: Bool {
        gameState.ghost.state == .attacking || gameState.ghost.state == .enraged
    }

    private func renderLaser(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let laser = SKShapeNode(path: path)
        laser.strokeColor = MGSSScenePalette.utility.withAlphaComponent(0.82)
        laser.lineWidth = 3
        laser.glowWidth = 5
        addChild(laser)
        laser.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
    }

    private func renderStatusLabels() {
        labelNodes.forEach { $0.removeFromParent() }
        labelNodes.removeAll()

        let statusText: String
        switch gameState.gameStatus {
        case .playing:
            if gameState.phase == .choosingRoom {
                statusText = "选房阶段：角色入住房间后不可自由移动"
            } else {
                statusText = isBreakingDoor ? "第 \(gameState.wave) 波 · 破门警报！" : "第 \(gameState.wave) 波 · \(phaseName()) · \(max(0, surviveSeconds - gameState.gameTime))s"
            }
        case .won:
            statusText = "胜利：天亮了"
        case .lost:
            statusText = "失败：寝室失守"
        }

        if gameState.phase == .choosingRoom || gameState.gameStatus != .playing {
            let calloutY = gameState.phase == .choosingRoom ? boardRect().maxY - 52 : boardRect().maxY - 24
            addCallout(text: statusText, at: CGPoint(x: size.width / 2, y: calloutY), tint: MGSSScenePalette.selected)
        }

        if gameState.phase == .nightDefense {
            addTinyLabel("床", at: CGPoint(x: bedNode.position.x, y: bedNode.position.y), tint: MGSSScenePalette.utility)
            addTinyLabel("门", at: CGPoint(x: doorNode.position.x, y: doorNode.position.y), tint: doorTipColor())
        }

        if gameState.phase == .nightDefense {
            addCallout(
                text: gameState.ghost.isFrozen ? "夜影冻结" : ghostStatusText(),
                at: CGPoint(x: ghostNode.position.x, y: ghostNode.position.y + 32),
                tint: gameState.ghost.isFrozen ? MGSSScenePalette.utility : MGSSScenePalette.danger
            )

            let playerText = gameState.player.isSleeping ? "玩家睡觉" : "玩家醒着"
            addCallout(
                text: playerText,
                at: CGPoint(x: playerNode.position.x, y: playerNode.position.y + 32),
                tint: MGSSScenePalette.utility
            )

            let tipOffset: CGFloat = gameState.selectedRoom.id == DormRoom.leftUpper.id || gameState.selectedRoom.id == DormRoom.leftLower.id ? 52 : -52
            addCallout(
                text: doorTipText(),
                at: CGPoint(x: doorNode.position.x + tipOffset, y: doorNode.position.y + 28),
                tint: doorTipColor()
            )
        }
    }

    private func addCallout(text: String, at position: CGPoint, tint: SKColor) {
        let width = min(size.width - 38, max(54, CGFloat(text.count) * 8.2 + 16))
        let bubble = SKShapeNode(rectOf: CGSize(width: width, height: 22), cornerRadius: 8)
        bubble.position = position
        bubble.fillColor = SKColor.black.withAlphaComponent(0.68)
        bubble.strokeColor = tint.withAlphaComponent(0.82)
        bubble.lineWidth = 1.2
        bubble.zPosition = 20
        addChild(bubble)
        labelNodes.append(bubble)

        let label = makeLabel(text, size: 10, color: tint)
        label.position = CGPoint(x: position.x, y: position.y - 1)
        label.zPosition = 21
        addChild(label)
        labelNodes.append(label)
    }

    private func addTinyLabel(_ text: String, at position: CGPoint, tint: SKColor) {
        let label = makeLabel(text, size: 9, color: tint)
        label.position = CGPoint(x: position.x, y: position.y - 1)
        label.zPosition = 22
        addChild(label)
        labelNodes.append(label)
    }

    private func ghostStatusText() -> String {
        switch gameState.ghost.state {
        case .scouting: return "夜影巡查"
        case .approaching: return "夜影接近"
        case .attacking: return "夜影破门"
        case .enraged: return "夜影狂暴"
        }
    }

    private func phaseName() -> String {
        if gameState.gameTime < 45 { return "发育期" }
        if gameState.gameTime < 110 { return "守门期" }
        return "反击期"
    }

    private func doorTipText() -> String {
        if gameState.phase == .choosingRoom { return "待入住" }
        if isBreakingDoor { return "门被攻击" }
        if gameState.turrets.isEmpty { return "缺炮台" }
        return "门口防守"
    }

    private func doorTipColor() -> SKColor {
        if isBreakingDoor { return SKColor(red: 1.0, green: 0.30, blue: 0.22, alpha: 1.0) }
        if gameState.turrets.isEmpty { return MGSSScenePalette.utility }
        return MGSSScenePalette.safe
    }

    private func makePickupNode(for item: Item) -> SKNode {
        let container = SKNode()
        let pill = SKShapeNode(rectOf: CGSize(width: 40, height: 22), cornerRadius: 8)
        pill.fillColor = color(for: item.type).withAlphaComponent(0.88)
        pill.strokeColor = .white.withAlphaComponent(0.82)
        pill.lineWidth = 1.4
        container.addChild(pill)
        let label = makeLabel(symbol(for: item.type), size: 8.5, color: .white)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -1)
        container.addChild(label)
        return container
    }

    private func addIsoDormBackdrop(in rect: CGRect) {
        let outer = SKShapeNode(rect: rect, cornerRadius: 20)
        outer.fillColor = MGSSScenePalette.boardFill
        outer.strokeColor = MGSSScenePalette.boardStroke
        outer.lineWidth = 3
        outer.zPosition = 0
        addChild(outer)
        dynamicBaseNodes.append(outer)

        let vignette = SKShapeNode(rect: rect.insetBy(dx: 8, dy: 8), cornerRadius: 16)
        vignette.fillColor = SKColor(red: 0.02, green: 0.018, blue: 0.045, alpha: 0.42)
        vignette.strokeColor = SKColor(red: 0.72, green: 0.58, blue: 0.96, alpha: 0.14)
        vignette.lineWidth = 1.2
        vignette.zPosition = 0.4
        addChild(vignette)
        dynamicBaseNodes.append(vignette)

        let title = makeLabel("2.5D 夜舍防线", size: 11, color: MGSSScenePalette.selected.withAlphaComponent(0.90))
        title.position = CGPoint(x: rect.midX, y: rect.maxY - 22)
        title.zPosition = 22
        addChild(title)
        dynamicBaseNodes.append(title)
    }

    private func addIsoCorridor(in rect: CGRect) {
        let corridorWidth = min(112, rect.width * 0.30)
        let corridorRect = CGRect(x: rect.midX - corridorWidth / 2, y: rect.minY + 34, width: corridorWidth, height: rect.height - 72)
        let floor = SKShapeNode(path: isoSlabPath(rect: corridorRect, depth: 18))
        floor.fillColor = MGSSScenePalette.corridorFill
        floor.strokeColor = MGSSScenePalette.corridorStroke
        floor.lineWidth = 2.4
        floor.zPosition = 1
        addChild(floor)
        dynamicBaseNodes.append(floor)

        let leftWall = SKShapeNode(path: sideWallPath(topLeft: CGPoint(x: corridorRect.minX, y: corridorRect.maxY), bottomLeft: CGPoint(x: corridorRect.minX, y: corridorRect.minY), depth: 16, outward: -1))
        leftWall.fillColor = SKColor(red: 0.045, green: 0.040, blue: 0.088, alpha: 0.96)
        leftWall.strokeColor = MGSSScenePalette.corridorStroke.withAlphaComponent(0.70)
        leftWall.lineWidth = 1
        leftWall.zPosition = 0.8
        addChild(leftWall)
        dynamicBaseNodes.append(leftWall)

        let rightWall = SKShapeNode(path: sideWallPath(topLeft: CGPoint(x: corridorRect.maxX, y: corridorRect.maxY), bottomLeft: CGPoint(x: corridorRect.maxX, y: corridorRect.minY), depth: 16, outward: 1))
        rightWall.fillColor = SKColor(red: 0.034, green: 0.032, blue: 0.070, alpha: 0.98)
        rightWall.strokeColor = MGSSScenePalette.corridorStroke.withAlphaComponent(0.62)
        rightWall.lineWidth = 1
        rightWall.zPosition = 0.8
        addChild(rightWall)
        dynamicBaseNodes.append(rightWall)

        for index in 0..<5 {
            let y = corridorRect.minY + 42 + CGFloat(index) * max(34, corridorRect.height / 5.8)
            let seam = SKShapeNode(path: isoDiamondPath(width: corridorWidth - 24, height: 16))
            seam.position = CGPoint(x: rect.midX, y: y)
            seam.fillColor = SKColor(red: 0.13, green: 0.11, blue: 0.20, alpha: 0.36)
            seam.strokeColor = SKColor(red: 0.44, green: 0.35, blue: 0.58, alpha: 0.30)
            seam.lineWidth = 1
            seam.zPosition = 1.2
            addChild(seam)
            dynamicBaseNodes.append(seam)
        }
    }

    private func addIsoDormRoom(_ room: DormRoom, roomRect: CGRect, isSelected: Bool) {
        let depth: CGFloat = isSelected ? 22 : 16
        let floor = SKShapeNode(path: isoSlabPath(rect: roomRect, depth: depth))
        floor.fillColor = isSelected ? MGSSScenePalette.selectedRoomFill : MGSSScenePalette.roomFill
        floor.strokeColor = isSelected ? MGSSScenePalette.selected : SKColor(red: 0.24, green: 0.20, blue: 0.35, alpha: 0.82)
        floor.lineWidth = isSelected ? 3 : 1.4
        floor.glowWidth = isSelected ? 3 : 0
        floor.zPosition = isSelected ? 4 : 2
        addChild(floor)
        dynamicBaseNodes.append(floor)

        let backWall = SKShapeNode(path: backWallPath(rect: roomRect, height: isSelected ? 28 : 22))
        backWall.fillColor = isSelected ? SKColor(red: 0.18, green: 0.13, blue: 0.17, alpha: 0.95) : SKColor(red: 0.07, green: 0.065, blue: 0.12, alpha: 0.94)
        backWall.strokeColor = isSelected ? MGSSScenePalette.selected.withAlphaComponent(0.55) : SKColor.white.withAlphaComponent(0.10)
        backWall.lineWidth = 1
        backWall.zPosition = floor.zPosition + 0.2
        addChild(backWall)
        dynamicBaseNodes.append(backWall)

        let side = SKShapeNode(path: roomSideWallPath(rect: roomRect, room: room, depth: depth))
        side.fillColor = SKColor(red: 0.040, green: 0.036, blue: 0.078, alpha: 0.96)
        side.strokeColor = SKColor.white.withAlphaComponent(isSelected ? 0.18 : 0.08)
        side.lineWidth = 1
        side.zPosition = floor.zPosition + 0.1
        addChild(side)
        dynamicBaseNodes.append(side)

        let bed = makeIsoBedNode(selected: isSelected)
        bed.position = mapPosition(room.playerPosition)
        bed.zPosition = 6
        addChild(bed)
        dynamicBaseNodes.append(bed)

        let door = makeIsoDoorNode(selected: isSelected, damaged: isSelected && isBreakingDoor)
        door.position = mapPosition(room.doorPosition)
        door.zPosition = 7
        addChild(door)
        dynamicBaseNodes.append(door)

        let name = makeLabel(isSelected ? "入住 · \(room.name)" : room.name, size: 10.2, color: isSelected ? MGSSScenePalette.selected : SKColor.white.withAlphaComponent(0.56))
        name.position = CGPoint(x: roomRect.midX, y: roomRect.maxY - 16)
        name.zPosition = 11
        addChild(name)
        dynamicBaseNodes.append(name)
    }

    private func makeIsoBedNode(selected: Bool) -> SKNode {
        let node = SKNode()
        let base = SKShapeNode(path: isoSlabPath(rect: CGRect(x: -34, y: -16, width: 68, height: 32), depth: 10))
        base.fillColor = SKColor(red: 0.10, green: selected ? 0.50 : 0.34, blue: selected ? 0.86 : 0.58, alpha: 0.96)
        base.strokeColor = MGSSScenePalette.utility.withAlphaComponent(selected ? 0.82 : 0.42)
        base.lineWidth = 1.2
        node.addChild(base)
        let pillow = SKShapeNode(path: isoDiamondPath(width: 22, height: 12))
        pillow.position = CGPoint(x: -18, y: 8)
        pillow.fillColor = SKColor.white.withAlphaComponent(selected ? 0.86 : 0.48)
        pillow.strokeColor = .clear
        pillow.zPosition = 1
        node.addChild(pillow)
        let blanket = SKShapeNode(path: isoDiamondPath(width: 34, height: 18))
        blanket.position = CGPoint(x: 12, y: -3)
        blanket.fillColor = MGSSScenePalette.utility.withAlphaComponent(selected ? 0.34 : 0.18)
        blanket.strokeColor = .clear
        blanket.zPosition = 1
        node.addChild(blanket)
        return node
    }

    private func makeIsoDoorNode(selected: Bool, damaged: Bool) -> SKNode {
        let node = SKNode()
        let frame = SKShapeNode(rectOf: CGSize(width: 50, height: 30), cornerRadius: 4)
        frame.fillColor = SKColor(red: 0.24, green: 0.12, blue: 0.055, alpha: 0.98)
        frame.strokeColor = damaged ? MGSSScenePalette.danger : MGSSScenePalette.warning.withAlphaComponent(selected ? 0.92 : 0.55)
        frame.lineWidth = damaged ? 3 : 1.8
        frame.glowWidth = damaged ? 5 : (selected ? 2 : 0)
        node.addChild(frame)
        let plank = SKShapeNode(rectOf: CGSize(width: 38, height: 20), cornerRadius: 3)
        plank.fillColor = doorColor()
        plank.strokeColor = SKColor.black.withAlphaComponent(0.42)
        plank.lineWidth = 1
        plank.zPosition = 1
        node.addChild(plank)
        let ratio = max(0, min(1, gameState.player.doorHealth / max(gameState.player.doorMaxHealth, 1)))
        let hpBack = SKShapeNode(rectOf: CGSize(width: 44, height: 4), cornerRadius: 2)
        hpBack.position = CGPoint(x: 0, y: 23)
        hpBack.fillColor = SKColor.black.withAlphaComponent(0.72)
        hpBack.strokeColor = .clear
        hpBack.zPosition = 2
        node.addChild(hpBack)
        let hp = SKShapeNode(rectOf: CGSize(width: 44 * CGFloat(ratio), height: 4), cornerRadius: 2)
        hp.position = CGPoint(x: -22 + 22 * CGFloat(ratio), y: 23)
        hp.fillColor = damaged ? MGSSScenePalette.danger : MGSSScenePalette.safe
        hp.strokeColor = .clear
        hp.zPosition = 3
        node.addChild(hp)
        return node
    }

    private func addGhostFaceDetails(to node: SKNode) {
        let shadow = SKShapeNode(path: isoDiamondPath(width: 52, height: 18))
        shadow.position = CGPoint(x: 0, y: -25)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.34)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        node.addChild(shadow)

        for x in [-7, 7] {
            let eye = SKShapeNode(circleOfRadius: 3.2)
            eye.position = CGPoint(x: CGFloat(x), y: 8)
            eye.fillColor = SKColor.white
            eye.strokeColor = MGSSScenePalette.danger.withAlphaComponent(0.65)
            eye.lineWidth = 1
            eye.zPosition = 2
            node.addChild(eye)
        }

        let slash = SKShapeNode(rectOf: CGSize(width: 18, height: 3), cornerRadius: 1.5)
        slash.position = CGPoint(x: 0, y: -2)
        slash.fillColor = SKColor.black.withAlphaComponent(0.54)
        slash.strokeColor = .clear
        slash.zPosition = 2
        node.addChild(slash)
    }

    private func makeIsoTurretNode(for turret: Turret) -> SKNode {
        let node = SKNode()
        let growth = CGFloat(turret.level * 3)
        let base = SKShapeNode(path: isoDiamondPath(width: 36 + growth, height: 22 + growth * 0.55))
        base.fillColor = SKColor(red: 0.08, green: 0.20, blue: 0.18, alpha: 0.96)
        base.strokeColor = MGSSScenePalette.utility.withAlphaComponent(0.90)
        base.lineWidth = 1.8
        base.glowWidth = 2
        node.addChild(base)
        let body = SKShapeNode(rectOf: CGSize(width: 24 + growth * 0.45, height: 18 + growth * 0.35), cornerRadius: 6)
        body.fillColor = turret.damage > 70 ? MGSSScenePalette.utility : MGSSScenePalette.safe
        body.strokeColor = SKColor.white.withAlphaComponent(0.72)
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: 6)
        body.zPosition = 1
        node.addChild(body)
        let barrel = SKShapeNode(rectOf: CGSize(width: 9, height: 28 + growth * 0.4), cornerRadius: 3)
        barrel.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0)
        barrel.strokeColor = SKColor.white.withAlphaComponent(0.74)
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: 9, y: 18)
        barrel.zRotation = -0.55
        barrel.zPosition = 2
        node.addChild(barrel)
        let level = makeLabel("Lv\(turret.level)", size: 8, color: .white)
        level.position = CGPoint(x: 0, y: -20)
        level.zPosition = 3
        node.addChild(level)
        node.zPosition = 9
        return node
    }

    private func isoSlabPath(rect: CGRect, depth: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + depth * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX - depth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY - depth * 0.42))
        path.addLine(to: CGPoint(x: rect.minX + depth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + depth * 0.2))
        path.closeSubpath()
        return path
    }

    private func isoDiamondPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -height / 2))
        path.addLine(to: CGPoint(x: -width / 2, y: 0))
        path.closeSubpath()
        return path
    }

    private func backWallPath(rect: CGRect, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + 12, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.maxX - 12, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.maxX - 24, y: rect.maxY - height))
        path.addLine(to: CGPoint(x: rect.minX + 24, y: rect.maxY - height))
        path.closeSubpath()
        return path
    }

    private func sideWallPath(topLeft: CGPoint, bottomLeft: CGPoint, depth: CGFloat, outward: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: topLeft)
        path.addLine(to: CGPoint(x: topLeft.x + outward * depth, y: topLeft.y - depth * 0.42))
        path.addLine(to: CGPoint(x: bottomLeft.x + outward * depth, y: bottomLeft.y - depth * 0.42))
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }

    private func roomSideWallPath(rect: CGRect, room: DormRoom, depth: CGFloat) -> CGPath {
        let leftSide = room.id == DormRoom.leftUpper.id || room.id == DormRoom.leftLower.id
        let x = leftSide ? rect.minX : rect.maxX
        return sideWallPath(topLeft: CGPoint(x: x, y: rect.maxY - 3), bottomLeft: CGPoint(x: x, y: rect.minY + 6), depth: depth, outward: leftSide ? -1 : 1)
    }

    private func updateThreatPath() {
        let path = CGMutablePath()
        let from = mapPosition(gameState.ghost.position)
        let to = mapPosition(gameState.selectedRoom.doorPosition)
        path.move(to: from)
        path.addLine(to: to)
        threatPathNode.path = path
        threatPathNode.isHidden = gameState.phase == .choosingRoom || gameState.ghost.isFrozen
        threatPathNode.alpha = isBreakingDoor ? 0.82 : 0.32
    }

    private func originalGhostPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 25))
        path.addCurve(to: CGPoint(x: 24, y: 2), control1: CGPoint(x: 16, y: 24), control2: CGPoint(x: 25, y: 14))
        path.addLine(to: CGPoint(x: 18, y: -22))
        path.addLine(to: CGPoint(x: 5, y: -12))
        path.addLine(to: CGPoint(x: -2, y: -24))
        path.addLine(to: CGPoint(x: -10, y: -12))
        path.addLine(to: CGPoint(x: -22, y: -22))
        path.addLine(to: CGPoint(x: -24, y: 2))
        path.addCurve(to: CGPoint(x: 0, y: 25), control1: CGPoint(x: -24, y: 15), control2: CGPoint(x: -15, y: 24))
        path.closeSubpath()
        return path
    }

    private func dormRoomRect(for room: DormRoom) -> CGRect {
        let board = boardRect()
        let roomW = min((board.width - 112) / 2, 128)
        let roomH = min(max(82, board.height * 0.22), 122)
        let leftX = board.midX - 46 - roomW
        let rightX = board.midX + 46
        let lowerY = board.minY + 44
        let upperY = max(lowerY + roomH + 30, board.midY + 10)
        switch room.id {
        case DormRoom.rightLower.id:
            return CGRect(x: rightX, y: lowerY, width: roomW, height: roomH)
        case DormRoom.leftUpper.id:
            return CGRect(x: leftX, y: upperY, width: roomW, height: roomH)
        case DormRoom.rightUpper.id:
            return CGRect(x: rightX, y: upperY, width: roomW, height: roomH)
        default:
            return CGRect(x: leftX, y: lowerY, width: roomW, height: roomH)
        }
    }

    private func mapPosition(_ position: Position) -> CGPoint {
        let playRect = boardRect().insetBy(dx: 28, dy: 26)
        let x = playRect.minX + CGFloat(position.x / 6.0) * playRect.width
        let y = playRect.minY + CGFloat(position.y / 6.0) * playRect.height
        return CGPoint(x: x, y: y)
    }

    private func doorColor() -> SKColor {
        if gameState.player.doorHealth <= 0 { return .darkGray }
        let healthRatio = gameState.player.doorHealth / max(gameState.player.doorMaxHealth, 1)
        if healthRatio < 0.25 { return SKColor(red: 0.85, green: 0.18, blue: 0.12, alpha: 1.0) }
        if healthRatio < 0.55 { return SKColor(red: 0.88, green: 0.48, blue: 0.10, alpha: 1.0) }
        return SKColor(red: 0.45, green: 0.25, blue: 0.12, alpha: 1.0)
    }

    private func bedColor() -> SKColor {
        let level = min(gameState.player.bedLevel, 5)
        let blue = 0.36 + CGFloat(level) * 0.08
        return SKColor(red: 0.10, green: 0.45, blue: min(0.95, blue), alpha: 1.0)
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    private func color(for type: Item.ItemType) -> SKColor {
        switch type {
        case .speedUp: return MGSSScenePalette.utility
        case .goldBoost: return MGSSScenePalette.selected
        case .doorRepair: return MGSSScenePalette.safe
        case .freezeGhost: return MGSSScenePalette.utility
        case .invincible: return MGSSScenePalette.safe
        case .barrier: return MGSSScenePalette.warning
        case .slowTrap: return MGSSScenePalette.utility
        }
    }

    private func symbol(for type: Item.ItemType) -> String {
        switch type {
        case .speedUp: return "加速"
        case .goldBoost: return "金币"
        case .doorRepair: return "修门"
        case .freezeGhost: return "冰冻"
        case .invincible: return "护盾"
        case .barrier: return "屏障"
        case .slowTrap: return "减速"
        }
    }
}
