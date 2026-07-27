# SplitwiseApp 深度问题分析与解决方案

> 评估日期：2026-07-27  
> 评估范围：源码、产品逻辑、数据层、变现、国际化、工程与体验  
> 目标：系统性列出当前仍存在的问题，并给出可落地的修复方案（按优先级排序）

---

## 1. 执行摘要

本应用是一套 **离线优先的 SwiftUI + SwiftData 账单分摊 Demo/原型**，UI 覆盖面较全（群组、好友、分摊、结清、图表、导出、StoreKit 壳），但距离「可上线、可商用、可审核通过」仍有明显差距。

| 维度 | 当前水平 | 结论 |
|------|----------|------|
| 核心记账 UI | 中高 | 主流程基本可走通 |
| 业务正确性 | 低–中 | 当前用户 ID、多币种、分摊校验存在硬伤 |
| Pro/付费墙 | 低 | 默认 Mock Pro，几乎无真实门禁 |
| 协同/账号 | 缺失 | 无登录、无云同步、邀请文案误导 |
| 合规与品牌 | 高风险 | 商标名、隐私政策、订阅合规均未就绪 |
| 工程化 | 低 | 无测试、无 CI、无崩溃保护策略 |
| 国际化 | 极低 | 208 个 key 中仅约 9 个有简体中文 |

**建议发布策略：** 先完成 P0/P1 修复与品牌重命名，再以「本地 AA 记账工具」定位提交；不要以「官方 Splitwise 复刻」叙事上架。

---

## 2. 问题分级说明

| 级别 | 含义 |
|------|------|
| **P0 阻断** | 核心数据错误 / 审核必挂 / 法律风险，上线前必须修 |
| **P1 严重** | 明显功能缺陷或虚假宣传，会显著伤害信任或转化 |
| **P2 重要** | 体验与可维护性问题，首发可妥协但应排期 |
| **P3 优化** | 体验打磨、性能与扩展性 |

---

## 3. P0 阻断级问题

### 3.1 `currentUserId` 与真实用户严重脱节（核心余额全错）

**现象**

- `AppState.currentUserId` 在 `init` 时默认为 `UUID()`（每次冷启动可能是新随机 ID）。
- 样例数据与业务以 `User.isCurrentUser == true` 标识「我」。
- 大量 UI 用 `appState.currentUserId` 判断「You」、计算群组/好友净余额（`GroupListView`、`FriendDetailView`、`FriendsListView`、`GroupDetailView` 等）。

**后果**

- 首页「总体欠/被欠」、群组列表余额徽章、好友间净额 **几乎恒为 0 或错误**。
- 「Paid By / You」展示可能指错人。
- 这是**产品级致命 Bug**，比 UI 问题更严重。

**解决方案**

1. 启动时从 SwiftData 解析当前用户，并写回 `AppState`：
   ```swift
   // 伪代码
   if let me = try context.fetch(FetchDescriptor<User>(
       predicate: #Predicate { $0.isCurrentUser }
   )).first {
       appState.currentUserId = me.id
   }
   ```
2. 或彻底去掉 `AppState.currentUserId`，全局统一用 `isCurrentUser` / 注入的 `currentUser`。
3. 将 `currentUserId` 持久化到 `UserDefaults`，并与 `User.id` 保持一致。
4. 增加单元测试：样例数据下整体净余额、群组余额与手工验算一致。

---

### 3.2 品牌与商标：直接使用「Splitwise」命名

**现象**

- `CFBundleName`、启动页、导航、Pro 文案、PDF 元数据、StoreKit 商品名均使用 **Splitwise / Splitwise Pro**。
- Bundle ID：`com.splitwise.ios.app`。
- README 写「完整复刻 Splitwise」。

**后果**

- 商标侵权与 App Store 4.1（抄袭/混淆）高风险。
- 即使功能做完，品牌不过关也会被拒或被下架。

**解决方案**

1. **立即重命名产品**（建议原创名，如 BillFlow / SplitNest / FairShare 等，并做商标检索）。
2. 全量替换显示名、Bundle ID、StoreKit Product ID、PDF 作者字段、本地化字符串。
3. 营销文案改为「灵感来自常见 AA 场景」，禁止「官方复刻 / 兼容 Splitwise」表述。
4. 应用图标、颜色体系避免高度仿官方品牌识别。

---

### 3.3 Pro 默认开启 + 模拟器 Mock 开关上线可见

**现象**

```swift
// ProSubscriptionManager
public var isMockPro: Bool = true  // 默认 true → isPro 恒为 true
```

- 订阅页暴露 `Simulator Mock Pro Mode` Toggle。
- 产品拉取失败时 `purchasePlan` 直接 `isMockPro = true`。
- 全项目几乎**没有**基于 `isPro` 的功能门禁（导出/OCR/图表/债务简化均免费可用）。

**后果**

- 商业模型失效；审核员可免费使用全部「Pro」能力。
- 若宣称付费权益，属于**误导性 IAP**（Guideline 3.1.x / 2.3.x）。
- Mock 开关上架会被视为未完成/测试构建。

**解决方案**

1. Release 构建强制：
   ```swift
   #if DEBUG
   var isMockPro = false // 仅 DEBUG 面板可开
   #else
   var isMockPro = false // 永远 false，且 UI 不展示
   #endif
   ```
2. 为 OCR、导出、高级图表、债务简化开关、Itemized 等实现统一 `ProGate`。
3. 非 Pro 点击进入标准 Paywall（权益对比 + 购买 + 恢复）。
4. 购买失败时展示错误，**禁止**自动 Mock 解锁。
5. ASC 中配置真实订阅组、价格、本地化、税务与沙盒账号测试。

---

### 3.4 订阅合规要素缺失（法律链接与动态价格）

**现象**

- 仅有一句静态免责声明，**无可点击** Privacy Policy / Terms of Use / EULA 链接。
- 价格硬编码 `$2.99 / month`、`$29.99 / year`，未使用 `Product.displayPrice`。
- 未展示订阅时长、续费规则、试用期的完整法定披露（部分地区强制）。

**解决方案**

1. 上线前准备可公网访问的：
   - Privacy Policy URL  
   - Terms of Use / EULA URL  
2. 订阅页必须用 `product.displayPrice`、`subscriptionPeriod`、introductory offer 动态文案。
3. 提供 **Restore Purchases**（已有）并在失败时有明确 Toast/Alert。
4. App 描述、截图、ASC 订阅元数据与 App 内文案一致。
5. Account/About 增加法律入口；设置 `ITSAppUsesNonExemptEncryption` 等导出合规声明。

---

### 3.5 隐私声明与真实能力不一致

| 声明 | 实际实现 | 风险 |
|------|----------|------|
| `NSCameraUsageDescription` | 仅有 `PhotosPicker`，无相机拍摄 | 未使用权限 + 描述夸大 |
| `NSFaceIDUsageDescription` | Face ID Toggle 无 `LocalAuthentication` | 虚假权限 / 功能欺诈感 |
| `NSPhotoLibraryUsageDescription` | 使用 PhotosPicker | 基本合理，但文案可更准确 |
| Push Notifications Toggle | 无 APNs 注册 | 空开关误导用户 |

**解决方案**

1. **不做就删**：移除 Face ID / Camera / Push 的 Info.plist 与 UI，或完整实现。
2. 若要做相册 OCR：保留 Photos；若要拍照：接入 `UIImagePickerController` / `AVCapture` 并真请求相机。
3. 若要做锁屏：用 `LAContext` 在 `scenePhase == .active` 时鉴权，失败则遮罩。
4. 隐私清单（Privacy Nutrition Labels）与实际数据收集一致：当前为本地存储，应声明「不收集」或仅「设备上处理」。

---

### 3.6 债务计算不支持多币种混合

**现象**

- `DebtSimplifier` 直接对 `expense.amount` / `settlement.amount` 做加减，**不看 currency**。
- 用户可在账单级选不同币种；群组有 `defaultCurrency`。
- 图表 `totalSpent` 亦直接 `sum(amount)`，跨币种数字无意义。

**后果**

- 东京旅行（USD）+ 房租（USD）尚可；一旦混入 JPY/CNY，余额与「简化债务」错误。
- 「实时汇率」实为 `CurrencyFormatter` 内写死静态表，且未接入余额引擎。

**解决方案**

1. 引擎层统一：所有金额先换算到 **群组基准币种** 再算净额。
2. 换算源：
   - 短期：App 内手动汇率表 + 时间戳标注「非实时」。
   - 中期：接入公开汇率 API，并缓存；失败回退上次缓存。
3. UI 明确展示：余额币种、换算提示、无法换算时的错误态。
4. 禁止在未换算时跨币种相加（断言/过滤 + 单元测试）。

---

## 4. P1 严重问题

### 4.1 无账号体系，但文案承诺「邀请加入 Splitwise」

**现象**

- `AddFriendView` 提示可发邮件邀请好友加入，实际只本地 `insert User`。
- 无登录、无多人实时同步、无冲突合并。

**解决方案（二选一）**

| 路线 | 做法 |
|------|------|
| **A. 诚实的本地工具** | 删除「邀请加入」文案；改为「添加本地联系人/参与方」；分享用导出 PDF/链接文本 |
| **B. 真协同产品** | 账号（Sign in with Apple）、云库（CloudKit/自建后端）、邀请链接、权限与冲突解决 |

首发建议 **路线 A**，显著降低范围与审核复杂度。

---

### 4.2 Freemium 与 PRD 不一致

**PRD 承诺**：OCR、Itemized、汇率、导出、图表、债务简化开关为 Pro；免费含广告预留。  
**代码现实**：无 Paywall 门禁、无广告、Mock Pro 默认开。

**解决方案**

1. 实现单一权限源：`FeatureFlag` / `ProEntitlement`。
2. 免费版明确可用：Equal/Exact 分摊、基础群组好友、简单余额。
3. 锁功能时用一致的 `ProBadge` + 订阅 Sheet。
4. 若暂不做广告，**删除**「100% Ad-Free」卖点，避免虚假对比。

---

### 4.3 分摊逻辑与校验不完整

**现象（`AddExpenseView` / `SplitOptionsView`）**

- 切换金额/群组时 `recalculateSplits()` 常重置为 **Equal**，可能覆盖用户在 Options 里配置的 Exact/%/Shares。
- Exact 模式是否强制「分摊合计 = 总额」需在 UI 层严格校验（Save 前）。
- Percentage 需强制合计 100%。
- Itemized OCR 结果与成员归属未完成「逐项指派」闭环时，易产生金额不一致。
- 角分（0.01）舍入在 Equal 模式未做「差额补到最后一人」的稳健策略（部分场景有，需统一）。

**解决方案**

1. 拆分「默认初始化 splits」与「用户已自定义 splits」状态；仅在成员集合变化时重算。
2. Save 按钮 `disabled` 条件绑定校验函数：
   - Equal：自动修复尾差  
   - Exact：`abs(sum - total) < 0.01`  
   - %：`abs(sum% - 100) < 0.01`  
   - Shares：总份数 > 0  
   - Itemized：各项归属完整且合计匹配  
3. 用属性测试 / 单元测试覆盖样例金额（3 人、7 人、奇数分）。

---

### 4.4 循环账单 `RepeatFrequency` 仅为展示字段

**现象**

- 模型有 `weekly/monthly/yearly`，保存后 **无调度、无自动生成后续账单**。

**解决方案**

- 短期：UI 标注「Coming Soon」或移除选项。  
- 中期：用 `BGAppRefresh` / 本地通知 + 打开 App 时补生成，或 EventKit 式规则引擎。

---

### 4.5 结清（Settle Up）不唤起真实支付

**现象**

- 支持记录 Cash/PayPal/Venmo/微信/支付宝等 **记账备注**，但不跳转支付、不验证到账。

**解决方案**

- 文案改为「记录一笔已发生的还款」。  
- 可选：深度链接到 Venmo/PayPal（能力有限且地区差异大）。  
- 切勿宣传「一键支付结清」。

---

### 4.6 OCR 失败静默回落 Mock 小票

**现象**

```swift
// 识别失败 → mockReceiptResult()
// total 为 0 → 写死 48.50
// items 空 → 填入 Trader Joe's 假明细
```

**后果**

- 用户拍真实小票却得到虚假 Trader Joe's 数据，财务风险极高。

**解决方案**

1. 失败时返回明确错误态：「未能识别，请手动填写」。  
2. **禁止**用演示数据污染用户输入。  
3. Demo 按钮与真扫描路径分离，且 Demo 仅 DEBUG 可见。  
4. 识别语言设置 `recognitionLanguages`，支持中英文小票。  
5. 改进解析：TOTAL/合计优先、排除日期电话、置信度阈值。

---

### 4.7 语言切换无效 + 本地化严重不完整

**现象**

- Account 有语言 Picker，但未设置 `AppleLanguages` / 自定义 `Bundle` / `environment(\.locale)`。  
- `Localizable.xcstrings` 约 **208 keys，zh-Hans 仅约 9 条**；大量 key 空壳。  
- Onboarding、Pro、大量业务字符串硬编码英文。

**解决方案**

1. 短期：语言跟随系统，移除无效 Picker。  
2. 中期：完整翻译 en / zh-Hans / zh-Hant；用 String Catalog 状态跟踪。  
3. 若要做应用内语言：重启生效或 `id` 刷新根视图 + 自定义 localization bundle。  
4. 截图与 ASC 本地化语言与实际可用语言一致。

---

### 4.8 样例数据与「重置 Demo」面向生产用户

**现象**

- 首次进入自动 `SampleData.populateIfEmpty`。  
- Account 有 **Reset Demo Sample Data** 破坏性操作。  
- 用户真实数据会被演示人设（Alex Johnson 等）淹没认知。

**解决方案**

1. 首次引导二选一：「从空白开始」/「加载示例数据」。  
2. Reset 仅 DEBUG 或移到隐藏手势，并二次确认。  
3. 生产默认空白库；示例用单独「Demo Mode」入口。

---

### 4.9 删除账单无动态日志 / 编辑能力弱

**现象**

- `ExpenseDetailView` 可删除，但不写 `ActivityLog.deletedExpense`。  
- 编辑账单能力不完整（若仅有详情只读+删除）。  
- 删除后余额变化无审计。

**解决方案**

- 删除/编辑前后写 Activity；支持撤销（短时）或软删除。  
- 完善 Edit Expense 与分摊再平衡。

---

### 4.10 App Icon 使用 JPEG

**现象**

- `AppIcon-1024.jpg`（JPEG），非 Apple 推荐的 **PNG、无 alpha**。

**解决方案**

- 导出 1024×1024 **PNG**，无透明度、无圆角遮罩（系统自加）。  
- 避免纯白/纯黑大面积导致审核警告。

---

## 5. P2 重要问题

### 5.1 无网络同步与备份

- 卸载/换机数据全丢。  
- **方案**：iCloud（SwiftData + CloudKit）、导出备份 JSON、或「导出全部 CSV」。

### 5.2 无单元测试 / UI 测试

- 债务算法、分摊舍入、结算符号最需要测试。  
- **方案**：为 `DebtSimplifier`、`CurrencyFormatter`、`Split` 校验加 XCTest；关键 CI。

### 5.3 `fatalError` 初始化 ModelContainer

- 迁移失败直接崩溃。  
- **方案**：错误 UI + 重建/迁移策略；SwiftData 版本迁移计划。

### 5.4 PDF 导出分页与大数据

- 长账单可能画超出单页。  
- **方案**：分页绘制、表格布局、页脚页码。

### 5.5 好友/群组成员管理

- 移除成员、转让「当前用户」、合并重复好友等缺失。  
- 成员改名后历史 `ExpenseSplit.userName` 可能过期（冗余字段）。  
- **方案**：展示时以 `userId` 查表；历史快照可选保留。

### 5.6 通知与安全开关无效

- 见 3.5。实现或删除。

### 5.7 iPad 体验

- 有 `NavigationSplitView`，但全局加账单 sheet、多栏深度链接、键盘与指针优化不足。  
- **方案**：按 size class 做双栏详情、列宽、快捷键。

### 5.8 无障碍与动态字体

- 部分固定字号、图标按钮缺 `accessibilityLabel`。  
- **方案**：Dynamic Type、VoiceOver 标签、对比度检查。

### 5.9 性能

- 列表中反复全量 `filter` 全库 expenses 算余额，数据量大时卡顿。  
- **方案**：按 `groupId` 索引查询、缓存净额、后台计算。

### 5.10 工程元数据

- `SWIFT_VERSION: "5.0"` 与 README「Swift 6」不一致。  
- 无 PrivacyInfo.xcprivacy（若使用需声明的 API）。  
- **方案**：统一版本声明；补充隐私清单。

---

## 6. P3 优化建议

1. **空状态插画与引导**：新用户无示例时的任务引导（创建群组 → 加一笔 → 看余额）。  
2. **搜索**：账单、好友、群组全文搜索。  
3. **标签/自定义分类**：扩展 `ExpenseCategory`。  
4. **小组件 / 快捷指令**：查看「我欠多少」。  
5. **Haptic / 成功动效**：保存账单与结清反馈。  
6. **债务简化可视化**：简单图布局（节点=成员）。  
7. **多付款人**：一笔账单多人垫付（模型 `paidShare` 已预留，引擎未完整用）。  
8. **主题**：品牌色 token 已有，可扩展自定义强调色。

---

## 7. 架构与产品定位建议

### 7.1 当前真实定位

```
本地单机 AA 记账 Demo
  ├─ SwiftData 持久化
  ├─ 分摊 UI + 简化债务算法
  ├─ Vision OCR 试验性
  └─ StoreKit 外壳（未产品化）
```

### 7.2 建议 MVP 边界（可上架）

**必须有**

- 正确的「当前用户」与余额  
- 群组/好友/等额与精确分摊  
- 结清记录  
- 原创品牌与隐私政策  
- 稳定无崩溃主路径  

**可延后**

- 云同步、真邀请、真支付  
- 实时汇率、高级 OCR  
- 订阅（可先免费上架，或上架后再开 IAP）  

**若保留订阅**

- 必须有真实可验证的 Pro 权益差异  

---

## 8. 推荐修复路线图

### Phase 0（1–2 天）— 止血

- [ ] 修复 `currentUserId` 绑定  
- [ ] 关闭默认 Mock Pro；隐藏 DEBUG 开关  
- [ ] 产品改名评估与 Bundle ID 规划  
- [ ] OCR 失败禁止 Mock 污染  
- [ ] 删除或实现 Face ID / 相机 / 推送声明  

### Phase 1（3–5 天）— 可演示正确性

- [ ] 多币种统一换算进余额引擎  
- [ ] 分摊校验与尾差  
- [ ] 样例数据可选  
- [ ] 基础单元测试（DebtSimplifier + Split）  
- [ ] App Icon PNG  

### Phase 2（1 周）— 合规可提审

- [ ] 隐私政策 / 条款网页 + 应用内链接  
- [ ] 订阅动态价格与完整披露（若启用 IAP）  
- [ ] Pro 门禁与恢复购买验收  
- [ ] 本地化至少 en + 一个目标市场语言  
- [ ] ASC 截图、审核备注、演示账号说明（本地 App 可说明无需账号）  

### Phase 3（后续）— 产品化

- [ ] 备份/iCloud  
- [ ] 编辑账单完善  
- [ ] 性能与无障碍  
- [ ] 可选账号体系  

---

## 9. 问题清单速查表

| ID | 问题 | 级别 | 主要文件 |
|----|------|------|----------|
| I-01 | currentUserId 随机导致余额错误 | P0 | `AppState.swift`, `GroupListView`, `FriendsListView` |
| I-02 | 商标/品牌 Splitwise | P0 | 全局 + `Info.plist` + Bundle ID |
| I-03 | isMockPro 默认 true | P0 | `ProSubscriptionManager.swift` |
| I-04 | 无隐私政策/条款链接 | P0 | `SplitwiseProView`, Account |
| I-05 | 权限声明与实现不符 | P0 | `Info.plist`, `AccountView` |
| I-06 | 多币种未换算 | P0 | `DebtSimplifier`, `ChartsView` |
| I-07 | 邀请/协同虚假承诺 | P1 | `AddFriendView` |
| I-08 | Pro 无门禁 | P1 | 全 Views |
| I-09 | 分摊重算覆盖用户配置 | P1 | `AddExpenseView` |
| I-10 | 循环账单未实现 | P1 | `Expense`, `AddExpenseView` |
| I-11 | OCR Mock 污染 | P1 | `ReceiptScannerService` |
| I-12 | 本地化几乎未完成 | P1 | `Localizable.xcstrings`, `AppState` |
| I-13 | 强制/隐藏 Demo 数据不当 | P1 | `SampleData`, `AccountView` |
| I-14 | App Icon JPEG | P1 | `AppIcon.appiconset` |
| I-15 | 无测试/迁移脆弱 | P2 | 工程级 |
| I-16 | PDF 单页限制等 | P2 | `ExportManager` |

---

## 10. 结论

该项目作为 **学习型 / 原型型** 实现已经具备可观的界面广度，但在 **身份模型、金额正确性、付费真实性、品牌合规、隐私合规** 五个维度存在上线阻断项。  

优先顺序建议：

1. **正确性**（用户 ID + 多币种 + 分摊校验）  
2. **诚实性**（文案、Mock、权限、Demo 数据）  
3. **合规性**（改名、隐私政策、IAP）  
4. **完成度**（本地化、测试、备份）  

完成 Phase 0–2 后，再评估 App Store 提交；单独的审核拒绝风险清单见：  
**[APP_STORE_REVIEW_RISKS.md](./APP_STORE_REVIEW_RISKS.md)**。
