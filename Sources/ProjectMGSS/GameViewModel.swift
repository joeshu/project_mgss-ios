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
