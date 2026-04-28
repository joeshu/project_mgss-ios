import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.05, blue: 0.12), Color(red: 0.13, green: 0.08, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        shopHeader
                        shopSection(title: "先发育", subtitle: "宿舍防守节奏：床越高，睡觉经济越快。") {
                            shopCard(
                                icon: "🛏️",
                                title: "升级床铺 Lv.\(viewModel.player.bedLevel) → Lv.\(min(viewModel.player.bedLevel + 1, 5))",
                                subtitle: "提升睡觉金币和电力产出，建议优先升级。",
                                price: "\(120 * (viewModel.player.bedLevel + 1)) 金币",
                                tint: .green,
                                disabled: viewModel.player.bedLevel >= 5 || viewModel.playerGold < 120 * (viewModel.player.bedLevel + 1),
                                action: viewModel.upgradeBed
                            )
                        }

                        shopSection(title: "再守门", subtitle: "门是失败线，猛鬼开始破门时优先补耐久。") {
                            shopCard(
                                icon: "🚪",
                                title: "升级房门 Lv.\(viewModel.player.doorLevel) → Lv.\(min(viewModel.player.doorLevel + 1, 6))",
                                subtitle: "提升最大耐久，并减少猛鬼破门伤害。",
                                price: "\(180 * (viewModel.player.doorLevel + 1)) 金币 + \(6 * max(1, viewModel.player.doorLevel)) 电力",
                                tint: .orange,
                                disabled: viewModel.player.doorLevel >= 6 || viewModel.playerGold < 180 * (viewModel.player.doorLevel + 1) || viewModel.playerElectricity < 6 * max(1, viewModel.player.doorLevel),
                                action: viewModel.upgradeDoor
                            )

                            shopCard(
                                icon: "🔨",
                                title: "修复房门",
                                subtitle: "立即恢复耐久，等级越高修复越多。",
                                price: "90 金币",
                                tint: .yellow,
                                disabled: viewModel.playerGold < 90 || viewModel.doorHealth >= viewModel.doorMaxHealth,
                                action: viewModel.repairDoor
                            )
                        }

                        shopSection(title: "最后反击", subtitle: "炮台负责消耗猛鬼血量，形成守门反杀路线。") {
                            shopCard(
                                icon: "🟢",
                                title: "基础炮台",
                                subtitle: "攻击力 45 | 射程 4.0 | 适合前期补伤害。",
                                price: "160 金币",
                                tint: .blue,
                                disabled: viewModel.playerGold < 160,
                                action: { viewModel.addTurret(at: Position(x: 2.0, y: 3.2), cost: 160, range: 4.0, damage: 45.0) }
                            )

                            shopCard(
                                icon: "🔷",
                                title: "强力炮台",
                                subtitle: "攻击力 95 | 射程 4.8 | 中后期核心输出。",
                                price: "420 金币",
                                tint: .cyan,
                                disabled: viewModel.playerGold < 420,
                                action: { viewModel.addTurret(at: Position(x: 4.0, y: 3.2), cost: 420, range: 4.8, damage: 95.0) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("宿舍商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var shopHeader: some View {
        HStack(spacing: 10) {
            resourcePill("🪙", "\(viewModel.playerGold)")
            resourcePill("⚡", "\(viewModel.playerElectricity)")
            resourcePill("🚪", "\(Int(viewModel.doorHealth))/\(Int(viewModel.doorMaxHealth))")
        }
        .padding(12)
        .background(.black.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func resourcePill(_ icon: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
            Text(value)
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.white.opacity(0.10))
        .clipShape(Capsule())
    }

    private func shopSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.66))
            }
            content()
        }
    }

    private func shopCard(icon: String, title: String, subtitle: String, price: String, tint: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(icon)
                    .font(.title2)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.68))
                    Text(price)
                        .font(.caption.bold())
                        .foregroundColor(disabled ? .gray : .yellow)
                }
                Spacer()
            }
            .padding(13)
            .background(.black.opacity(disabled ? 0.22 : 0.46))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(disabled ? .gray.opacity(0.28) : tint.opacity(0.70), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .disabled(disabled)
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(viewModel: GameViewModel())
    }
}
