import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                        priorityBanner
                        shopSection(title: "① 先发育", subtitle: "优先升级床铺，让睡觉经济滚起来。") {
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

                        shopSection(title: "② 再守门", subtitle: "门是失败线，破门警报出现时先修门/升门。") {
                            shopCard(
                                icon: "🚪",
                                title: "升级房门 Lv.\(viewModel.player.doorLevel) → Lv.\(min(viewModel.player.doorLevel + 1, 6))",
                                subtitle: "提升最大耐久，并减少夜影破门伤害。",
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

                        shopSection(title: "③ 最后反击", subtitle: "炮台自动落在所选房间门口插槽，人物不用移动。") {
                            shopCard(
                                icon: "🟢",
                                title: "基础炮台",
                                subtitle: "攻击力 45 | 射程 4.0 | 优先覆盖当前房门。",
                                price: "160 金币",
                                tint: .blue,
                                disabled: viewModel.playerGold < 160,
                                action: { viewModel.addTurret(cost: 160, range: 4.0, damage: 45.0) }
                            )

                            shopCard(
                                icon: "🔷",
                                title: "强力炮台",
                                subtitle: "攻击力 95 | 射程 4.8 | 中后期核心输出。",
                                price: "420 金币",
                                tint: .cyan,
                                disabled: viewModel.playerGold < 420,
                                action: { viewModel.addTurret(cost: 420, range: 4.8, damage: 95.0) }
                            )
                        }
                    }
                     .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("宿舍商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(minWidth: 52, minHeight: 44)
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

    private var priorityBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: priorityIcon)
                .foregroundColor(priorityTint)
                .font(.headline)
            VStack(alignment: .leading, spacing: 3) {
                Text(priorityTitle)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(prioritySubtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.70))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(priorityTint.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(priorityTint.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var priorityTitle: String {
        if viewModel.doorHealth / max(viewModel.doorMaxHealth, 1) < 0.35 { return "优先级：救门" }
        if viewModel.player.bedLevel < 3 { return "优先级：升床发育" }
        if viewModel.turrets.count < 2 { return "优先级：补门前炮台" }
        return "优先级：强化整条防线"
    }

    private var prioritySubtitle: String {
        if viewModel.doorHealth / max(viewModel.doorMaxHealth, 1) < 0.35 { return "当前门耐久偏低，先修门或升级门，购买后不会重开。" }
        if viewModel.player.bedLevel < 3 { return "床等级越高，睡觉收益越快，更接近“先发育再防守”的节奏。" }
        if viewModel.turrets.count < 2 { return "至少两座炮台覆盖门口，才能稳定消耗敌人血量。" }
        return "继续补门、床和炮台等级，准备后半夜狂暴阶段。"
    }

    private var priorityIcon: String {
        if viewModel.doorHealth / max(viewModel.doorMaxHealth, 1) < 0.35 { return "exclamationmark.shield.fill" }
        if viewModel.player.bedLevel < 3 { return "bed.double.fill" }
        if viewModel.turrets.count < 2 { return "scope" }
        return "checkmark.seal.fill"
    }

    private var priorityTint: Color {
        if viewModel.doorHealth / max(viewModel.doorMaxHealth, 1) < 0.35 { return .red }
        if viewModel.player.bedLevel < 3 { return .green }
        if viewModel.turrets.count < 2 { return .cyan }
        return .yellow
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
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(viewModel: GameViewModel())
    }
}
