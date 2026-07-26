# Product Requirement Document (PRD) - Splitwise iOS Native App

---

## 1. 产品概述与目标 (Overview & Objectives)

### 1.1 产品简介
Splitwise iOS 原生应用是一款专注于**多人群组与好友 AA 记账、智能债务简化与账单结算**的 iOS 应用程序。旨在解决合租房客、旅行同伴、情侣、聚会好友等场景下“谁付了钱、谁欠多少钱、如何最少转账次数结清”的痛点。

### 1.2 目标用户群体 (Target Audience)
- **合租房客 (Roommates)**：房租、水电网费、公共日常用品平摊。
- **旅行/度假人群 (Travelers)**：机票、酒店、餐饮、景点门票等多币种平摊。
- **情侣/夫妻 (Couples)**：日常生活开销共同记录与结算。
- **团队/聚会组织者 (Events/Parties)**：活动开销快速拆分与小票扫描管理。

---

## 2. 核心功能需求规格 (Functional Requirements)

### 2.1 群组管理 (Group Management)
- **群组类型**：支持旅行 (Trip)、房屋/合租 (Home)、情侣 (Couple)、其他 (Other)。
- **成员邀请与管理**：支持通过姓名、邮箱添加成员，灵活设置群组默认结算货币（USD, CNY, EUR 等）。
- **债务极简优化开关 (Simplify Group Debts)**：支持按群组开启/关闭算法极简欠款匹配。

### 2.2 账单添加与 5 大 AA 分摊模式 (Expense & 5 Split Engines)
用户记录账单时，可选择以下 5 种精确分摊模式：

| 分摊模式 | 符号 | 规则描述 | 校验逻辑 |
| :--- | :--- | :--- | :--- |
| **Equal (等额平摊)** | `=/=` | 全员均匀平摊总额 | 自动处理 0.01 尾数舍入 |
| **Exact (指定金额)** | `$` | 为每位成员手动输入具体金额 | 必须满足：∑成员金额 = 账单总额 |
| **Percentage (百分比)** | `%` | 输入每人分摊比例 | 必须满足：∑成员比例 = 100% |
| **Shares (权重/份数)** | `1x` | 按份数比例分配 (e.g. A占2份, B占1份) | 按权重公式计算个人金额 |
| **Itemized (逐项小票)** | `🧾` | 结合 Vision OCR，按消费条目指定归属 | 关联各品类价格并自动加总 |

### 2.3 智能债务简化引擎 (Debt Simplification Engine)
- 自动汇总群组所有账单与历史支付记录，计算每位成员的**净余额 (Net Balance = 总支出 - 总应付)**。
- 基于图论最小流匹配算法，自动算出所需最少转账笔数的平账方案。
- 提供对比视图：显示“原始复杂欠款列表” vs “智能极简转账方案”。

### 2.4 结清与平账 (Settle Up)
- 记录成员之间的还款支付（支持现金、微信支付、支付宝、PayPal、Venmo、Zelle、银行转账）。
- 提交平账后自动更新双方净余额与群组整体账目。

### 2.5 Vision OCR 小票智能识别 (Receipt Scanning)
- 允许拍摄或从相册选择小票图片。
- 基于 Apple Vision 框架自动识别小票名称、总金额及具体商品清单，一键填充至账单添加界面。

### 2.6 统计图表与报表导出 (Analytics & Statement Export)
- **Swift Charts 可视化**：分类支出饼图/环形图、每月消费趋势折线图、群组消费对比柱状图。
- **PDF & CSV 导出**：一键生成格式化的 PDF 打印报表与 Excel/Numbers 兼容的 CSV 电子表格，并唤起系统分享。

---

## 3. 商业变现模型 (Business Model & StoreKit 2)

应用采用 **Freemium 免费 + Splitwise Pro 订阅制**：

### 3.1 免费版 vs Pro 版权益对比

| 功能特性 | 免费版 (Free) | Splitwise Pro 会员 |
| :--- | :---: | :---: |
| 基础群组与好友 AA 记账 | ✅ 支持 | ✅ 支持 |
| 基础分摊模式 (等额/指定金额) | ✅ 支持 | ✅ 支持 |
| Vision OCR 小票识别扫描 | ❌ 不支持 / 试用 | ✅ 无限次识别 |
| 高级小票品类拆分 (Itemized) | ❌ 不支持 | ✅ 完全解锁 |
| 实时多币种汇率换算 | ❌ 仅限手动 | ✅ 自动实时换算 |
| 债务极简算法开关 | ❌ 仅默认模式 | ✅ 自由开关与深度图表 |
| PDF & CSV 打印报表导出 | ❌ 不支持 | ✅ 无限制导出 |
| 广告体验 | 包含广告预留 | 🚫 100% 纯净无广告 |

### 3.2 定价策略 (Pricing)
- **Pro 月度订阅 (Monthly)**：$2.99 / 月（含 7 天免费试用）
- **Pro 年度订阅 (Annual)**：$29.99 / 年（享受 16% 折扣优惠）

---

## 4. 非功能性需求与提交规范 (Non-Functional & Compliance)

1. **系统兼容性**：最低部署目标为 **iOS 17.0+** / iPadOS 17.0+。
2. **设备适配**：全面支持 iPhone (Compact Width) 与 iPad (Regular Width) 响应式自适应。
3. **性能指标**：应用启动时间 $< 1.0s$，图表渲染帧率控制在 60fps/120fps (ProMotion)。
4. **App Store Connect (ASC) 审核要求**：
   - 包含完整的隐私权限声明 (`Info.plist` 显式声明 NSCamera, NSPhotoLibrary, NSFaceID)。
   - StoreKit 2 具备真实的交易结果恢复机制 (`restorePurchases`) 与使用条款说明。
   - 零编译警告与报错。
