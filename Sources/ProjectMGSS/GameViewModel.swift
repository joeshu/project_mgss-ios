import Foundation
import Combine
import SpriteKit

@MainActor
class GameViewModel: ObservableObject {
    @Published var player: Player
    @Published var ghost: Ghost
    @Published var turrets: [Turret]
    @Published var items: [Item]
    @Published var gameTime: Int
    @Published var gameStatus: GameStatus
    @Published var playerGold: Int
    @Published var playerElectricity: Int
    @Published var doorHealth: Float
    @Published var doorMaxHealth: Float
    @Published var phase: GamePhase
    @Published var selectedRoom: DormRoom
    @Published var wave: Int
    @Published var lastFeedback: String?

    let gameScene: GameScene
    let availableRooms = DormRoom.allCases

    init() {
        let initialRoom = DormRoom.rightLower
        let initialPlayer = Player(room: initialRoom)
        let initialGhost = Ghost()
        let initialTurrets: [Turret] = []
        let initialItems: [Item] = []
        let initialGameTime = 0
        let initialGameStatus = GameStatus.playing
        let initialPhase = GamePhase.choosingRoom
        let initialWave = 1

        self.player = initialPlayer
        self.ghost = initialGhost
        self.turrets = initialTurrets
        self.items = initialItems
        self.gameTime = initialGameTime
        self.gameStatus = initialGameStatus
        self.playerGold = initialPlayer.gold
        self.playerElectricity = initialPlayer.electricity
        self.doorHealth = initialPlayer.doorHealth
        self.doorMaxHealth = initialPlayer.doorMaxHealth
        self.phase = initialPhase
        self.selectedRoom = initialRoom
        self.wave = initialWave
        self.lastFeedback = "推荐右下房开局：炮台位清晰，适合首局发育。"

        let initialState = GameState(
            player: initialPlayer,
            ghost: initialGhost,
            turrets: initialTurrets,
            items: initialItems,
            gameTime: initialGameTime,
            gameStatus: initialGameStatus,
            phase: initialPhase,
            selectedRoom: initialRoom,
            wave: initialWave
        )
        self.gameScene = GameScene(gameState: initialState)
        self.gameScene.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.applyGameState(state)
            }
        }
    }

    func startGame() {
        let room = selectedRoom
        player = Player(room: room)
        ghost = Ghost(type: .normal, pressurePhase: .early, wave: 1, roomRisk: room.risk)
        turrets = []
        items = []
        gameTime = 0
        gameStatus = .playing
        phase = .choosingRoom
        wave = 1
        playerGold = player.gold
        playerElectricity = player.electricity
        doorHealth = player.doorHealth
        doorMaxHealth = player.doorMaxHealth
        setFeedback("已重开：默认保留 \(room.name)，确认后开始夜晚。")
        updateGameState()
    }

    func chooseRoom(_ room: DormRoom) {
        selectedRoom = room
        player = Player(room: room)
        playerGold = player.gold
        playerElectricity = player.electricity
        doorHealth = player.doorHealth
        doorMaxHealth = player.doorMaxHealth
        turrets = []
        items = []
        ghost = Ghost(type: .normal, pressurePhase: .early, wave: 1, roomRisk: room.risk)
        gameTime = 0
        wave = 1
        gameStatus = .playing
        phase = .choosingRoom
        setFeedback("已选择 \(room.name)：风险 \(room.risk)，收益 +\(room.rewardBonus)，门体加成 +\(Int(room.doorBonus))。")
        updateGameState()
    }

    func beginNightDefense() {
        guard gameStatus == .playing else { return }
        phase = .nightDefense
        player.isSleeping = true
        ghost = Ghost(type: .normal, pressurePhase: .early, wave: wave, roomRisk: selectedRoom.risk)
        setFeedback("夜晚开始：睡觉发育，注意四阶段压力和门耐久。")
        updateGameState()
    }

    func toggleSleep() {
        guard phase == .nightDefense else { return }
        player.isSleeping.toggle()
        setFeedback(player.isSleeping ? "进入睡觉发育：金币和电力持续增长。" : "已醒来布防：及时修门、升门或补炮台。")
        updateGameState()
    }

    func exitGame() {
        startGame()
    }

    func addTurret(at position: Position? = nil, cost: Int = 160, range: Float = 4.0, damage: Float = 45.0) {
        guard phase == .nightDefense else {
            setFeedback("先确认入住宿舍，再建造炮台。")
            return
        }
        guard playerGold >= cost else {
            setFeedback("金币不足：建造炮台需要 \(cost) 金币。")
            return
        }

        if turrets.count >= selectedRoom.turretSlots.count {
            upgradeTurret()
            return
        }

        let slotIndex = min(turrets.count, selectedRoom.turretSlots.count - 1)
        let turretPosition = position ?? selectedRoom.turretSlots[max(0, slotIndex)]
        let turret = Turret(position: turretPosition, range: range, damage: damage)
        turrets.append(turret)
        playerGold -= cost
        setFeedback("已在门前建造炮台，优先覆盖走廊入口。")
        updateGameState()
    }

    func upgradeTurret() {
        guard phase == .nightDefense else {
            setFeedback("先确认入住宿舍，再升级炮台。")
            return
        }
        guard !turrets.isEmpty else {
            setFeedback("门前还没有炮台，先建造一座基础炮台。")
            return
        }
        guard let targetIndex = turrets.indices.min(by: { turrets[$0].level < turrets[$1].level }) else { return }
        let nextLevel = turrets[targetIndex].level + 1
        let goldCost = 150 * nextLevel
        let electricityCost = 4 * nextLevel
        guard playerGold >= goldCost, playerElectricity >= electricityCost else {
            setFeedback("资源不足：炮台升级需要 \(goldCost) 金币 + \(electricityCost) 电力。")
            return
        }

        playerGold -= goldCost
        playerElectricity -= electricityCost
        turrets[targetIndex].level = nextLevel
        turrets[targetIndex].damage += 28.0
        turrets[targetIndex].range += 0.18
        turrets[targetIndex].cooldown = max(0.62, turrets[targetIndex].cooldown - 0.06)
        setFeedback("炮台升级到 Lv.\(nextLevel)，门口火力提升。")
        updateGameState()
    }

    func upgradeBed() {
        let nextLevel = player.bedLevel + 1
        let cost = 120 * nextLevel
        guard player.bedLevel < 5 else {
            setFeedback("床铺已满级，继续把资源投入门和炮台。")
            return
        }
        guard playerGold >= cost else {
            setFeedback("金币不足：升级床铺需要 \(cost) 金币。")
            return
        }

        playerGold -= cost
        player.bedLevel = nextLevel
        setFeedback("床铺升到 Lv.\(nextLevel)，金币/电力发育加快。")
        updateGameState()
    }

    func upgradeDoor() {
        let nextLevel = player.doorLevel + 1
        let goldCost = 180 * nextLevel
        let electricityCost = 6 * max(1, nextLevel - 1)
        guard player.doorLevel < 6 else {
            setFeedback("房门已满级，保持维修即可。")
            return
        }
        guard playerGold >= goldCost, playerElectricity >= electricityCost else {
            setFeedback("资源不足：升级房门需要 \(goldCost) 金币 + \(electricityCost) 电力。")
            return
        }

        playerGold -= goldCost
        playerElectricity -= electricityCost
        player.doorLevel = nextLevel
        doorMaxHealth = max(700.0, 900.0 + selectedRoom.doorBonus) + Float(nextLevel - 1) * 560.0
        doorHealth = min(doorMaxHealth, doorHealth + 560.0)
        player.doorMaxHealth = doorMaxHealth
        player.doorHealth = doorHealth
        setFeedback("房门加固到 Lv.\(nextLevel)，最大耐久提升。")
        updateGameState()
    }

    func repairDoor() {
        let repairCost = 90
        guard doorHealth < doorMaxHealth else {
            setFeedback("房门耐久已满，暂时不需要维修。")
            return
        }
        guard playerGold >= repairCost else {
            setFeedback("金币不足：修复房门需要 \(repairCost) 金币。")
            return
        }

        let repairAmount: Float = 350.0 + Float(player.doorLevel) * 100.0
        doorHealth = min(doorMaxHealth, doorHealth + repairAmount)
        playerGold -= repairCost
        player.doorHealth = doorHealth
        setFeedback("房门已维修，当前耐久 \(Int(doorHealth))/\(Int(doorMaxHealth))。")
        updateGameState()
    }

    func useItem(_ type: Item.ItemType) {
        let now = Date()
        switch type {
        case .doorRepair:
            doorHealth = min(doorMaxHealth, doorHealth + 500.0)
            player.doorHealth = doorHealth
        case .freezeGhost:
            ghost.isFrozen = true
            ghost.frozenUntil = now.addingTimeInterval(8)
        case .goldBoost, .speedUp, .invincible, .barrier, .slowTrap:
            let duration = type == .barrier || type == .slowTrap ? 6 : 10
            player.activeEffects.append(ActiveEffect(type: type, expiresAt: now.addingTimeInterval(TimeInterval(duration))))
        }
        updateGameState()
    }

    private func applyGameState(_ state: GameState) {
        player = state.player
        ghost = state.ghost
        turrets = state.turrets
        items = state.items
        gameTime = state.gameTime
        gameStatus = state.gameStatus
        phase = state.phase
        selectedRoom = state.selectedRoom
        wave = state.wave
        playerGold = state.player.gold
        playerElectricity = state.player.electricity
        doorHealth = state.player.doorHealth
        doorMaxHealth = state.player.doorMaxHealth
    }

    func updateGameState() {
        player.gold = playerGold
        player.electricity = playerElectricity
        player.doorHealth = doorHealth
        player.doorMaxHealth = doorMaxHealth
        player.position = selectedRoom.playerPosition
        player.isDoorBroken = doorHealth <= 0
        ghost.health = max(ghost.health, 0)

        gameScene.gameState = GameState(
            player: player,
            ghost: ghost,
            turrets: turrets,
            items: items,
            gameTime: gameTime,
            gameStatus: gameStatus,
            phase: phase,
            selectedRoom: selectedRoom,
            wave: wave
        )
    }

    private func setFeedback(_ message: String) {
        lastFeedback = message
    }
}
