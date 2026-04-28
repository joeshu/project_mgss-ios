import SwiftUI

struct ItemsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("原版化规则")) {
                    Text("核心循环调整为：睡觉发育 → 升级床和房门 → 建炮台 → 坚持到天亮或击退猛鬼。")
                    Text("金币来自睡觉，电力随床等级产出；猛鬼会逐步靠近房门并随时间成长。")
                }

                Section(header: Text("可用道具")) {
                    ForEach(Item.ItemType.allCases, id: \.self) { itemType in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName(itemType))
                                .font(.headline)
                            Text(getItemDescription(itemType))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("模拟使用") {
                                viewModel.useItem(itemType)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("道具与规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func displayName(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "加速鞋"
        case .goldBoost:
            return "双倍金币"
        case .doorRepair:
            return "维修包"
        case .freezeGhost:
            return "冰冻符"
        case .invincible:
            return "无敌护盾"
        case .barrier:
            return "房门屏障"
        case .slowTrap:
            return "减速陷阱"
        }
    }

    private func getItemDescription(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "移动速度提升，后续可接入玩家走位玩法。"
        case .goldBoost:
            return "金币获取速度提升 2 倍，持续 10 秒。"
        case .doorRepair:
            return "立即修复 500 点房门耐久。"
        case .freezeGhost:
            return "冻结猛鬼 8 秒，无法移动和攻击。"
        case .invincible:
            return "无敌状态，免疫所有伤害，持续 10 秒。"
        case .barrier:
            return "房门屏障，阻止猛鬼攻击，持续 6 秒。"
        case .slowTrap:
            return "陷阱触发，使猛鬼减速，持续 6 秒。"
        }
    }
}

struct ItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ItemsView(viewModel: GameViewModel())
    }
}
