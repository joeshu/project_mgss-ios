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

    let gameScene: GameScene

    init() {
        let initialPlayer = Player()
        let initialGhost = Ghost()
        let initialTurrets: [Turret] = []
        let initialItems: [Item] = []
        let initialGameTime = 0
        let initialGameStatus = GameStatus.playing

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

        let initialState = GameState(
            player: initialPlayer,
            ghost: initialGhost,
            turrets: initialTurrets,
            items: initialItems,
            gameTime: initialGameTime,
            gameStatus: initialGameStatus
        )
        self.gameScene = GameScene(gameState: initialState)
        self.gameScene.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.applyGameState(state)
            }
        }
    }

    func startGame() {
        player = Player()
        ghost = Ghost()
        turrets = []
        items = []
        gameTime = 0
        gameStatus = .playing
        playerGold = player.gold
        playerElectricity = player.electricity
        doorHealth = player.doorHealth
        doorMaxHealth = player.doorMaxHealth
        updateGameState()
    }

    func toggleSleep() {
        player.isSleeping.toggle()
        updateGameState()
    }

    func exitGame() {
        startGame()
    }

    func addTurret(at position: Position, cost: Int = 160, range: Float = 4.0, damage: Float = 45.0) {
        guard playerGold >= cost else { return }

        let turret = Turret(position: position, range: range, damage: damage)
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
        doorMaxHealth = 900.0 + Float(nextLevel - 1) * 550.0
        doorHealth = min(doorMaxHealth, doorHealth + 550.0)
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
        player.isDoorBroken = doorHealth <= 0
        ghost.health = max(ghost.health, 0)

        gameScene.gameState = GameState(
            player: player,
            ghost: ghost,
            turrets: turrets,
            items: items,
            gameTime: gameTime,
            gameStatus: gameStatus
        )
    }
}
