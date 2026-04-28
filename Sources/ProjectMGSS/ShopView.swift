import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("发育设施")) {
                    Button(action: {
                        viewModel.upgradeBed()
                    }) {
                        shopRow(
                            title: "升级床铺 Lv.\(viewModel.player.bedLevel) → Lv.\(min(viewModel.player.bedLevel + 1, 5))",
                            subtitle: "睡觉时金币和电力产出提升，更接近原版发育节奏",
                            price: "\(120 * (viewModel.player.bedLevel + 1)) 金币"
                        )
                    }
                    .disabled(viewModel.player.bedLevel >= 5 || viewModel.playerGold < 120 * (viewModel.player.bedLevel + 1))
                }

                Section(header: Text("防御塔")) {
                    Button(action: {
                        viewModel.addTurret(at: Position(x: 2.0, y: 3.2), cost: 160, range: 4.0, damage: 45.0)
                    }) {
                        shopRow(title: "基础炮台", subtitle: "攻击力 45 | 射程 4.0 | 适合前期", price: "160 金币")
                    }
                    .disabled(viewModel.playerGold < 160)

                    Button(action: {
                        viewModel.addTurret(at: Position(x: 4.0, y: 3.2), cost: 420, range: 4.8, damage: 95.0)
                    }) {
                        shopRow(title: "强力炮台", subtitle: "攻击力 95 | 射程 4.8 | 中后期主力", price: "420 金币")
                    }
                    .disabled(viewModel.playerGold < 420)
                }

                Section(header: Text("房门升级")) {
                    Button(action: {
                        viewModel.upgradeDoor()
                    }) {
                        shopRow(
                            title: "升级房门 Lv.\(viewModel.player.doorLevel) → Lv.\(min(viewModel.player.doorLevel + 1, 6))",
                            subtitle: "提升最大耐久并降低猛鬼伤害",
                            price: "\(180 * (viewModel.player.doorLevel + 1)) 金币 + \(6 * max(1, viewModel.player.doorLevel)) 电力"
                        )
                    }
                    .disabled(
                        viewModel.player.doorLevel >= 6 ||
                        viewModel.playerGold < 180 * (viewModel.player.doorLevel + 1) ||
                        viewModel.playerElectricity < 6 * max(1, viewModel.player.doorLevel)
                    )

                    Button(action: {
                        viewModel.repairDoor()
                    }) {
                        shopRow(title: "修复房门", subtitle: "恢复耐久，等级越高修复越多", price: "90 金币")
                    }
                    .disabled(viewModel.playerGold < 90)
                }
            }
            .navigationTitle("宿舍商店")
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

    private func shopRow(title: String, subtitle: String, price: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(price)
                .font(.headline)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(viewModel: GameViewModel())
    }
}
