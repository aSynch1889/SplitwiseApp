# Splitwise App Design Tokens Specification

本文档记录了 Splitwise iOS 原生应用程序的核心设计令牌（Design Tokens），包括色彩体系、字体规格、间距与圆角规则、图标集以及组件样式。

---

## 🎨 1. 色彩令牌 (Color Tokens)

### 1.1 品牌与状态色彩 (Brand & State Colors)

| Token 名称 | 颜色 Preview | RGB / HEX | 含义 / 使用场景 |
| :--- | :--- | :--- | :--- |
| `brandTeal` | <span style="color:#1CC29F;">■</span> `#1CC29F` | `RGB(28, 194, 159)` | 主品牌色（按钮、选中态、导航栏图标） |
| `brandTealDark` | <span style="color:#14967A;">■</span> `#14967A` | `RGB(20, 150, 122)` | 深色/按下态品牌色 |
| `owedGreen` | <span style="color:#2EC4B6;">■</span> `#2EC4B6` | `RGB(46, 196, 182)` | 应收金额 / 他人欠你钱 (You are owed) |
| `owesOrange` | <span style="color:#FF6B6B;">■</span> `#FF6B6B` | `RGB(255, 107, 107)` | 应付金额 / 你欠他人钱 (You owe) |

### 1.2 动态主题背景色 (Adaptive Backgrounds)

| Token 名称 | Light Mode | Dark Mode | 使用场景 |
| :--- | :--- | :--- | :--- |
| `viewBackground` | `UIColor.systemGroupedBackground` | 系统分组背景 | 全局页面底层背景色 |
| `cardBackground` | `UIColor.secondarySystemGroupedBackground` | 系统二级分组背景 | 账单卡片、成员列表容器 |

### 1.3 渐变色令牌 (Gradients)

| Token 名称 | 色值范围 | 使用场景 |
| :--- | :--- | :--- |
| `proGoldGradient` | `LinearGradient([.orange, .yellow])` | Splitwise Pro 会员皇冠图标与高亮 Banner |

---

## 🔤 2. 字体与排版令牌 (Typography Tokens)

| Token 名称 | 字体规格 | 权重 (Weight) | 适用场景 |
| :--- | :--- | :--- | :--- |
| `displayAmount` | `.system(size: 32-34, design: .rounded)` | `.bold` | 首页/账单详情大字号金额显示 |
| `titleLarge` | `Font.title2` | `.bold` | 页面顶栏标题、群组大名 |
| `headline` | `Font.headline` | `.semibold` | 区块标题、列表卡片主名 |
| `subheadline` | `Font.subheadline` | `.medium` | 辅助文字、支付方式、副标题 |
| `caption` | `Font.caption` | `.regular` | 时间戳、备注说明、成员人数 |
| `badgeText` | `Font.caption2` | `.bold` | "you owe", "you are owed" 状态角标 |

---

## 📐 3. 布局与圆角令牌 (Layout & Radius Tokens)

### 3.1 圆角 (Corner Radius)

| Token 名称 | 数值 | 适用元素 |
| :--- | :--- | :--- |
| `radiusSmall` | `6pt` / `8pt` | 标签角标、币种 Picker 按钮、提示框 |
| `radiusMedium` | `10pt` / `12pt` | 账单卡片、操作按钮、输入框容器 |
| `radiusLarge` | `14pt` / `16pt` | 概览大卡片、Header 提示框、PDF 导出预览 |
| `radiusPill` | `20pt` / `30pt` | 悬浮添加账单按钮 (FAB)、Segment 选择器 |

### 3.2 尺寸与间距 (Size & Spacing)

| Token 名称 | 数值 | 描述 |
| :--- | :--- | :--- |
| `avatarSmall` | `24pt` | 迷你分类图标 / 个人小头像 |
| `avatarMedium` | `40pt` / `44pt` | 账单列表中间的分类 Icon 尺寸 |
| `avatarLarge` | `48pt` / `60pt` / `72pt` | 个人中心、群组 Header 封面大图标 |
| `paddingCompact` | `8pt` | 控件内部内边距 |
| `paddingStandard` | `12pt` / `14pt` | 卡片内部 padding |
| `paddingSection` | `16pt` / `20pt` | 页面边框左右留白 |

---

## 🏷 4. 图标令牌 (Iconography Tokens)

采用 Apple 原生 **SF Symbols** 图标集：

### 4.1 群组类型 (Group Types)
- ✈️ **Trip**: `airplane`
- 🏠 **Home**: `house.fill`
- 💖 **Couple**: `heart.fill`
- 📁 **Other**: `folder.fill`

### 4.2 账单分类 (Expense Categories)
- 🍔 **Food & Drink**: `fork.knife`
- ⚡️ **Utilities**: `bolt.fill`
- 🚗 **Transportation**: `car.fill`
- 🎬 **Entertainment**: `film.fill`
- 🏠 **Rent**: `house.fill`
- 🛍 **Shopping**: `bag.fill`
- 💰 **General**: `dollarsign.circle.fill`

---

## 🧾 5. 分摊模式令牌 (Split Method Tokens)

| 模式 | 符号 | Raw Value | 逻辑规则 |
| :--- | :--- | :--- | :--- |
| **Equal** | `=/=` | `"Equal"` | 均摊总额，处理尾数 0.01 舍入 |
| **Exact** | `$` | `"Exact"` | 指定每人固定金额（实时校验总额） |
| **Percentage** | `%` | `"Percentage"` | 按百分比分配（校验总计 100%） |
| **Shares** | `1x` | `"Shares"` | 按份数权重分配 (e.g. 1x, 2x) |
| **Itemized** | `🧾` | `"Itemized"` | 逐项小票分摊 (Vision OCR 自动解析) |

---

## 🌐 6. 国际化与币种令牌 (Localization & Currencies)

### 6.1 支持语言
- **English**: `en` (默认源语言)
- **简体中文**: `zh-Hans`
- **繁体中文**: `zh-Hant`

### 6.2 常用币种符号表

| Currency Code | Symbol | Sample Format |
| :--- | :--- | :--- |
| **USD** | `$` | `$120.00` |
| **CNY** | `¥` | `¥120.00` |
| **EUR** | `€` | `€120.00` |
| **GBP** | `£` | `£120.00` |
| **JPY** | `¥` | `¥120` |
| **TWD** | `NT$` | `NT$120.00` |
