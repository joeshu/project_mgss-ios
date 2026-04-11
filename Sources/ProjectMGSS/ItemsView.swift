import SwiftUI

struct ItemsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    let items: [Item.ItemType]
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        self.items = [.speedUp, .goldBoost, .doorRepair, .freezeGhost, .invincible, .barrier, .slowTrap]
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { itemType in
                    Section(header: Text(itemType.rawValue)) {
                        Text(getItemDescription(itemType))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("道具说明")
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
    
    private func getItemDescription(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "移动速度提升 2 倍，持续 10 秒"
        case .goldBoost:
            return "金币获取速度提升 2 倍，持续 10 秒"
        case .doorRepair:
            return "立即修复 500 点房门耐久"
        case .freezeGhost:
            return "冻结猛鬼 10 秒，无法移动和攻击"
        case .invincible:
            return "无敌状态，免疫所有伤害，持续 10 秒"
        case .barrier:
            return "房门护盾，阻止猛鬼攻击，持续 5 秒"
        case .slowTrap:
            return "陷阱触发，使猛鬼减速 50%，持续 5 秒"
        }
    }
}

struct ItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ItemsView(viewModel: GameViewModel())
    }
}
