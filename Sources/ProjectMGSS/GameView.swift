import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                SpriteView(scene: gameViewModel.gameScene)
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("猛鬼宿舍")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("金币: \(gameViewModel.playerGold)")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("房门: \(Int(gameViewModel.doorHealth))/\(Int(gameViewModel.doorMaxHealth))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            Text("游戏时间: \(gameViewModel.gameTime)")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text(gameViewModel.player.isSleeping ? "正在发育" : "准备中")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding()
                    .background(.black.opacity(0.35))
                    .cornerRadius(12)

                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: { gameViewModel.toggleSleep() }) {
                            Label(gameViewModel.player.isSleeping ? "醒来" : "睡觉", systemImage: gameViewModel.player.isSleeping ? "moon.fill" : "moon")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(gameViewModel.player.isSleeping ? .yellow : .gray)

                        NavigationLink(destination: ShopView(viewModel: gameViewModel)) {
                            Label("商店", systemImage: "cart.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        NavigationLink(destination: ItemsView(viewModel: gameViewModel)) {
                            Label("道具", systemImage: "gift.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                    .padding()
                    .background(.black.opacity(0.35))
                    .cornerRadius(12)
                }
                .padding()
            }
            .onAppear {
                gameViewModel.startGame()
            }
        }
    }
}

#Preview {
    GameView()
}
