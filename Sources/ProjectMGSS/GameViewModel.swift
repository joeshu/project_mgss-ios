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

    let gameScene: GameScene
    let availableRooms = DormRoom.allCases

    init() {
        let initialRoom = DormRoom.leftLower
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
        ghost = Ghost()
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
        ghost = Ghost()
        gameTime = 0
        wave = 1
        gameStatus = .playing
        phase = .choosingRoom
        updateGameState()
    }

    func beginNightDefense() {
        guard gameStatus == .playing else { return }
        phase = .nightDefense
        player.isSleeping = true
        updateGameState()
    }

    func toggleSleep() {
        guard phase == .nightDefense else { return }
        player.isSleeping.toggle()
        updateGameState()
    }

    func exitGame() {
        startGame()
    }

    func addTurret(at position: Position? = nil, cost: Int = 160, range: Float = 4.0, damage: Float = 45.0) {
        guard phase == .nightDefense else { return }
        guard playerGold >= cost else { return }

        let slotIndex = min(turrets.count, selectedRoom.turretSlots.count - 1)
        let turretPosition = position ?? selectedRoom.turretSlots[max(0, slotIndex)]
        let turret = Turret(position: turretPosition, range: range, damage: damage)
        turrets.append(turret)
        playerGold -= cost
        updateGameState()
    }

    func upgradeBed() {
        let nextLevel = player.bedLevel + 1
        let cost = 120 * nextLevel
        guard playerGold >= cost, player.bedLevel < 5 else { return }

        playerGold -= cost
        player.bedLevel = nextLevel
        updateGameState()
    }

    func upgradeDoor() {
        let nextLevel = player.doorLevel + 1
        let goldCost = 180 * nextLevel
        let electricityCost = 6 * max(1, nextLevel - 1)
        guard playerGold >= goldCost, playerElectricity >= electricityCost, player.doorLevel < 6 else { return }

        playerGold -= goldCost
        playerElectricity -= electricityCost
        player.doorLevel = nextLevel
        doorMaxHealth = max(700.0, 900.0 + selectedRoom.doorBonus) + Float(nextLevel - 1) * 560.0
        doorHealth = min(doorMaxHealth, doorHealth + 560.0)
        player.doorMaxHealth = doorMaxHealth
        player.doorHealth = doorHealth
        updateGameState()
    }

    func repairDoor() {
        let repairCost = 90
        guard playerGold >= repairCost else { return }

        let repairAmount: Float = 350.0 + Float(player.doorLevel) * 100.0
        doorHealth = min(doorMaxHealth, doorHealth + repairAmount)
        playerGold -= repairCost
        player.doorHealth = doorHealth
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
}
