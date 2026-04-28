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
    @Published var doorHealth: Float
    @Published var doorMaxHealth: Float

    let gameScene: GameScene

    init() {
        self.player = Player()
        self.ghost = Ghost()
        self.turrets = []
        self.items = []
        self.gameTime = 0
        self.gameStatus = .playing
        self.playerGold = 0
        self.doorHealth = 1000.0
        self.doorMaxHealth = 1000.0

        let initialState = GameState(
            player: self.player,
            ghost: self.ghost,
            turrets: self.turrets,
            items: self.items,
            gameTime: self.gameTime,
            gameStatus: self.gameStatus
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
        playerGold = 0
        doorHealth = 1000.0
        doorMaxHealth = 1000.0
        updateGameState()
    }

    func toggleSleep() {
        player.isSleeping.toggle()
        updateGameState()
    }

    func exitGame() {
        startGame()
    }

    func addTurret(at position: Position, cost: Int = 500, range: Float = 5.0, damage: Float = 50.0) {
        guard playerGold >= cost else { return }

        let turret = Turret(position: position, range: range, damage: damage)
        turrets.append(turret)
        playerGold -= cost
        updateGameState()
    }

    func repairDoor() {
        let repairCost = 300
        guard playerGold >= repairCost else { return }

        let repairAmount: Float = 500.0
        doorHealth = min(doorMaxHealth, doorHealth + repairAmount)
        playerGold -= repairCost
        player.doorHealth = doorHealth
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
        doorHealth = state.player.doorHealth
        doorMaxHealth = state.player.doorMaxHealth
    }

    func updateGameState() {
        player.gold = playerGold
        player.doorHealth = doorHealth
        player.doorMaxHealth = doorMaxHealth
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
