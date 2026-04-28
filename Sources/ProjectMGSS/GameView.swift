import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                SpriteView(scene: gameViewModel.gameScene)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    statusPanel
                    Spacer()
                    actionPanel
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                gameViewModel.startGame()
            }
            .overlay(alignment: .center) {
                if gameViewModel.gameStatus != .playing {
                    resultOverlay
                }
            }
        }
    }

    private var statusPanel: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("猛鬼宿舍")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("金币: \(gameViewModel.playerGold)  电力: \(gameViewModel.playerElectricity)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("床 Lv.\(gameViewModel.player.bedLevel)  门 Lv.\(gameViewModel.player.doorLevel)")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text("时间: \(gameViewModel.gameTime)s")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(gameViewModel.player.isSleeping ? "睡觉发育中" : "醒着操作")
                        .font(.caption)
                        .foregroundColor(gameViewModel.player.isSleeping ? .green : .orange)
                    Text("炮台: \(gameViewModel.turrets.count)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("房门 \(Int(gameViewModel.doorHealth))/\(Int(gameViewModel.doorMaxHealth))")
                    .font(.caption2)
                    .foregroundColor(.white)
                ProgressView(value: Double(gameViewModel.doorHealth), total: Double(max(gameViewModel.doorMaxHealth, 1)))
                    .tint(.orange)
                Text("猛鬼 \(Int(gameViewModel.ghost.health))/\(Int(gameViewModel.ghost.maxHealth))")
                    .font(.caption2)
                    .foregroundColor(.white)
                ProgressView(value: Double(gameViewModel.ghost.health), total: Double(max(gameViewModel.ghost.maxHealth, 1)))
                    .tint(.red)
            }
        }
        .padding(12)
        .background(.black.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: { gameViewModel.toggleSleep() }) {
                    Label(gameViewModel.player.isSleeping ? "醒来" : "睡觉", systemImage: gameViewModel.player.isSleeping ? "sun.max.fill" : "bed.double.fill")
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
            }

            NavigationLink(destination: ItemsView(viewModel: gameViewModel)) {
                Label("道具与规则", systemImage: "gift.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(12)
        .background(.black.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var resultOverlay: some View {
        VStack(spacing: 16) {
            Text(gameViewModel.gameStatus == .won ? "守住宿舍！" : "房门被攻破")
                .font(.title2.bold())
            Text(gameViewModel.gameStatus == .won ? "你坚持到了天亮或击退了猛鬼。" : "升级床、房门和炮台后再试一次。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("重新开始") {
                gameViewModel.startGame()
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundColor(.white)
        .padding(24)
        .background(.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding()
    }
}

#Preview {
    GameView()
}
