# multi-agent-image 视觉/图形输出接入 iOS 安全架构边界与集成策略

适用项目：ProjectMGSS（SwiftUI + SpriteKit，iOS 16+，XcodeGen）  
当前限制：Linux 环境不能执行 Xcode 构建；视觉源多为 raster image / prompt / style reference；必须原创安全，不复制原版。

## 1. 架构边界

### 1.1 可接入范围
- **SwiftUI 层**：只接入非玩法判定的背景、氛围装饰、面板纹理、按钮/卡片装饰、Logo/插画等。
- **SpriteKit 层**：只接入可替换的贴图表现，例如房间地面、走廊纹理、门/床/炮台/道具/幽影的原创图标或 sprite；游戏坐标、碰撞/范围、胜负逻辑仍由 `GameScene.swift` 的模型与几何计算决定。
- **Assets.xcassets**：作为所有 app 内置 raster 资源的唯一入口，禁止运行时从网络加载视觉资源。
- **Prompt / style reference**：只作为生成过程记录和审计材料，不进入 runtime bundle，除非以文档形式归档在 `Docs/ArtPrompts/`。

### 1.2 禁止事项
- 禁止使用或近似复刻《猛鬼宿舍》原版截图、角色、图标、UI 布局、字体商标、明显可识别 IP 元素。
- 禁止把 AI 输出直接替换为玩法判定依据：例如通过图片尺寸推导碰撞、射程、房间边界。
- 禁止单张超大背景覆盖所有机型后再靠缩放裁切；禁止无上限 sprite 数量或逐帧动态解码图片。
- 禁止在 `GameScene.update(_:)`、`renderScene()` 高频路径里重复创建 `SKTexture(imageNamed:)` 或 `UIImage(named:)`。

## 2. 资源目录与命名策略

项目 `project.yml` 已将 `Resources` 纳入资源目录；当前 `Resources/README.md` 提示图片应放入 `Assets.xcassets`，但仓库尚未建立该目录。

建议新增：

```text
Resources/
  Assets.xcassets/
    Contents.json
    VisualBackgroundDorm.imageset/
    VisualDecorPanelNoise.imageset/
    SpriteDoorOriginal.imageset/
    SpriteBedOriginal.imageset/
    SpriteTurretOriginal.imageset/
    SpriteGhostOriginal.imageset/
    SpritePickupGold.imageset/
Docs/
  VisualIntegration.md
  ArtPrompts/
    <asset-name>.md
```

命名约定：
- SwiftUI 背景/装饰：`VisualBackground*`、`VisualDecor*`。
- SpriteKit 贴图：`Sprite<Domain><Variant>`，例如 `SpriteDoorOriginal`。
- 只允许 ASCII 资源名，避免 CI / XcodeGen / Bundle 查找差异。
- 每个 imageset 必须包含 `1x/2x/3x`，或单个 PDF/vector；raster 优先 PNG/WebP 源归档，App 内建议 PNG。

## 3. SwiftUI 背景/装饰集成策略

当前 `GameView.swift` 背景为 `LinearGradient`，`SpriteView(scene:options: [.allowsTransparency])` 叠在其上。这是良好的回退结构。

推荐集成方式：

```swift
ZStack {
    LinearGradient(...).ignoresSafeArea() // 永久保留回退
    Image("VisualBackgroundDorm")
        .resizable()
        .scaledToFill()
        .opacity(0.55)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    SpriteView(scene: gameViewModel.gameScene, options: [.allowsTransparency])
        .ignoresSafeArea()
}
```

边界要求：
- 背景图只能提供氛围，不承载关键文字或按钮。
- 所有 SwiftUI 装饰图必须 `.accessibilityHidden(true)`，不能干扰 VoiceOver。
- 亮度和对比度需保证 HUD 白字/黄字可读；必要时增加 `.overlay(Color.black.opacity(0.25))`。
- 小屏折叠逻辑已经由 `PhoneMetrics` 和 `safeAreaInset` 控制，视觉图不能改变面板保留高度。

## 4. SpriteKit 图形集成策略

当前 `GameScene.swift` 主要使用 `SKShapeNode`：
- `playerNode`、`ghostNode`、`doorNode`、`bedNode`、`auraNode`、`ghostPressureRing` 为核心节点。
- 炮台、道具在 `renderScene()` 中重建。
- `setupBaseScene()` 在尺寸变化时重建底图。

### 4.1 推荐分层
- `zPosition 0...9`：棋盘、房间、走廊、地面纹理。
- `zPosition 10...19`：门、床、玩家、敌人、炮台、道具。
- `zPosition 20...29`：SpriteKit 内 callout / label（当前已用 20/21）。
- `zPosition 100+`：临时特效，如 laser、hit flash。

### 4.2 贴图加载
新增一个轻量资源门面，避免散落字符串：

```swift
enum VisualAsset {
    static let ghost = "SpriteGhostOriginal"
    static let door = "SpriteDoorOriginal"
    static let bed = "SpriteBedOriginal"
}
```

SpriteKit 中应：
- 在 `didMove(to:)` 或资源门面中预加载纹理；不要在每秒 update/render 中解码。
- 对少量动态对象可保留现有 `SKShapeNode` 作为回退，再在有纹理时叠加 `SKSpriteNode` 子节点。
- 对炮台/道具这类频繁重建节点，先做 texture cache：`private lazy var turretTexture = SKTexture(imageNamed: ...)`。

### 4.3 不改变玩法
- `mapPosition(_:)`、`boardRect()`、`dormRoomRect(for:)` 仍是唯一坐标来源。
- sprite 的 `size` 应匹配现有 shape 的视觉尺寸，例如门约 `110x22`、床约 `70x42`、敌人约 `44x44`。
- 贴图透明边距不得改变用户对位置/范围的理解；建议透明 padding <= 8%。

## 5. 性能与尺寸预算

### 5.1 资源尺寸建议
- 全屏背景：最长边不超过 2048 px；iPhone portrait 可用 1290x2796 或 1179x2556 但需压缩，优先 2 套而非 1 张 4K。
- 面板噪声/纹理：256x256 或 512x512，可平铺。
- Sprite 图标：
  - 小道具：64x64 @1x / 128x128 @2x / 192x192 @3x。
  - 角色/敌人/炮台：96x96 @1x / 192x192 @2x / 288x288 @3x。
  - 门/床等横向对象：按显示比例给 2x/3x，不超过 512 px 长边。

### 5.2 包体与内存预算
- 首批接入资源总压缩体积建议 <= 3 MB；单张 PNG <= 800 KB，背景 <= 1.5 MB。
- 运行时新增常驻纹理内存建议 <= 20 MB。
- `SpriteView(... .allowsTransparency)` 有额外混合成本；若背景完全改由 SpriteKit 承担，可评估取消透明，但当前更建议保留 SwiftUI gradient 回退。

### 5.3 渲染约束
- 避免粒子/大面积半透明叠加超过 3 层。
- 大背景不要放入 SpriteKit 高频 scene 内随尺寸反复重建；优先 SwiftUI 背景层。
- 如果将 corridor/room 替换为纹理，仍保留 `SKShapeNode` 边框，降低视觉资源失败风险。

## 6. 原创安全流程

每个 multi-agent-image 输出进入仓库前必须附带审计记录：

```text
asset: SpriteGhostOriginal
source: multi-agent-image run id / prompt id
prompt: 原创校园夜防主题幽影，不引用任何现有游戏角色
negative: no screenshots, no logo, no original MGSS ghost, no copied UI
reviewer: <name/date>
status: approved/rejected
notes: 与原版无可识别相似角色/图标/界面构图
```

验收原则：
- 主题可以是“校园夜间塔防/宿舍防线”，但角色轮廓、配色组合、UI 构图不能贴近原版。
- 风格参考只能描述抽象属性，如“暗色霓虹、低多边形、Q 版比例”，不能使用受保护作品名称作为直接风格锚点。
- 若来源不清、prompt 含原版截图/角色名、或结果有明显近似，应拒收并重新生成。

## 7. 回退策略

必须保持“无图也可玩”：
- SwiftUI 背景失败：保留现有 `LinearGradient`。
- SpriteKit 贴图失败：保留现有 `SKShapeNode`，sprite 仅作为子节点或替代层可隐藏。
- 道具/状态图标失败：保留现有符号文本（`$`, `+`, `*`, `◇` 等）。
- Xcode asset 缺失时不应 crash：统一通过 `UIImage(named:) != nil` 或在接入阶段用资源门面断言；Release 仍回退 shape。

建议实现：

```swift
#if DEBUG
private func assertAssetExists(_ name: String) {
    assert(UIImage(named: name) != nil, "Missing visual asset: \(name)")
}
#endif
```

Linux 当前不能验证 UIKit/Xcode 构建，因此静态检查和 macOS CI 构建需互补。

## 8. 静态验收清单

### 8.1 仓库结构
- [ ] `Resources/Assets.xcassets/Contents.json` 存在。
- [ ] 所有 imageset 有合法 `Contents.json`。
- [ ] 资源名只含 `[A-Za-z0-9_]`。
- [ ] 没有把 prompt/source PSD/巨型原图打入 app bundle；源文件如需保留放 `Docs/ArtPrompts/` 或外部制品库。

### 8.2 尺寸与体积
- [ ] 单张 raster 长边 <= 2048 px（背景例外需书面说明）。
- [ ] 单个 app 内图片 <= 1.5 MB，普通 sprite <= 300 KB。
- [ ] 首批新增资源总量 <= 3 MB。
- [ ] PNG 有 alpha 时才保留 alpha；无透明背景图转为无 alpha。

### 8.3 代码安全
- [ ] `GameView.swift` 保留 gradient fallback。
- [ ] `GameScene.swift` 不在 `update(_:)` 或循环内重复创建 `SKTexture(imageNamed:)`。
- [ ] Sprite 图像不改变 `boardRect()` / `mapPosition(_:)` / 胜负逻辑。
- [ ] 装饰 `Image` 均 `.accessibilityHidden(true)`。
- [ ] 没有远程图片 URL / 下载逻辑。

### 8.4 原创合规
- [ ] 每个资源有 prompt/source 审计记录。
- [ ] negative prompt 明确排除原版截图、logo、角色、UI。
- [ ] 人工确认不构成可识别复刻。

### 8.5 可用静态命令（Linux）

```bash
# 列出 asset 目录
find Resources -maxdepth 3 -type f | sort

# 检查可疑远程图片/运行时下载
grep -R "http\|URLSession\|Data(contentsOf:" -n Sources Resources || true

# 检查 SpriteKit 高频路径是否直接加载 texture
grep -R "SKTexture(imageNamed:" -n Sources/ProjectMGSS

# 统计资源大小
find Resources -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.webp' \) -printf '%s %p\n' | sort -nr
```

macOS CI 还需执行：`xcodegen && xcodebuild ...`，并在真机/模拟器检查小屏、横屏、VoiceOver、低电量模式帧率。

## 9. 分阶段落地建议

1. **Phase A：资源骨架**  
   建立 `Assets.xcassets`、资源命名、审计文档模板；不改玩法代码。
2. **Phase B：SwiftUI 背景**  
   接入一张原创暗色宿舍氛围背景，保留 gradient fallback；验证 HUD 可读性。
3. **Phase C：SpriteKit 静态贴图**  
   先替换/叠加门、床、炮台、道具；保留 shape 边框和符号。
4. **Phase D：角色与特效**  
   接入原创幽影/玩家剪影和少量 hit/laser 贴图；控制 alpha 层数和 texture cache。
5. **Phase E：静态验收 + macOS 构建**  
   Linux 做结构/命名/大小/代码扫描；macOS CI 做 XcodeGen、构建、截图验收。
