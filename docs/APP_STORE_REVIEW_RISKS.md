# App Store Connect 审核拒绝风险评估与解决方案

> 初评日期：2026-07-27
> 最近复评：2026-07-29（commit `1480a9906a0c`）
> 适用对象：若以**当前代码与元数据状态**直接 Archive 并提交 App Store Connect 审核  
> 参考：Apple 2026-06-08 更新的 [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) 及本仓库实际实现
> 关联文档：[APP_ISSUES_AND_SOLUTIONS.md](./APP_ISSUES_AND_SOLUTIONS.md)

---

## 1. 总体结论

| 项目 | 评估 |
|------|------|
| **当前提交通过概率** | **很低**；不再给出无法被客观验证的具体百分比 |
| **最致命类别** | 商标/仿冒、Mock/Demo、Required Reason API 隐私清单、订阅合规、核心金额错误 |
| **建议** | **不要**在未完成下文「上架前必做清单」前正式提审 |
| **若必须尽快上架** | 先改名 + 关掉 Mock/Demo + 砍掉虚假 Pro/权限 + 补隐私政策，以「本地 AA 记账」最小范围提交 |

**本次二进制核验**

- Xcode 26.3 下 Debug/Release 模拟器构建成功，但均有 2 类 StoreKit 监听警告。
- Release App 中仍能检出 `Simulator Mock Pro Mode`、`Scan Sample Receipt (Pro Demo)`、Splitwise 品牌和原订阅 ID。
- Release App 中没有 `PrivacyInfo.xcprivacy`。
- 工程没有 Test target；`xcodebuild test` 直接报告 Scheme 未配置 Test Action。

审核员会实际安装二进制、点击主路径、检查订阅页与权限弹窗；App Store Connect 还会在上传处理阶段检查 Required Reason API 声明。构建成功不等于可提审。

---

## 2. 拒绝风险总览（按可能性 × 严重度）

| 优先级 | 状态 | 风险主题 | 相关 Guideline / 检查 | 可能性 | 严重度 |
|--------|------|----------|------------------------|--------|--------|
| R1 | ❌ | 使用 Splitwise 商标/仿冒 | 4.1、5.2.1 | 极高 | 阻断 |
| R2 | ❌ | Mock Pro / Demo 开关与假 OCR | 2.1、2.2 | 极高 | 阻断 |
| R3 | ❌ | 订阅无链接、动态价格与完整披露 | 3.1.2、2.3.1 | 高 | 阻断 |
| R4 | ❌ | 权限声明与功能不符 | 2.1、5.1.1 | 高 | 高 |
| R5 | ❌ | 邀请、实时汇率、最少笔数、无广告等宣传不实 | 2.3.1 | 高 | 高 |
| R6 | ⚠️ | ASC IAP 外部配置未知；App 内失败路径不合格 | 2.1、3.1 | 中–高 | 阻断 |
| R7 | ℹ️ | JPEG 图标有损质量 | HIG / 资产质量 | 低 | 低 |
| R8 | ❌ | 最低价值/仅 Demo 数据感 | 4.2 | 中 | 中–高 |
| R9 | ⚠️ | ASC 隐私问卷未知；App 内政策缺失 | 5.1 | 中–高 | 高 |
| R10 | ⚠️ | 出口合规问卷需在 ASC 核验 | 出口合规 | 中 | 低–中 |
| R11 | ❌ | 身份、个人账单、分摊、图表等主路径错误 | 2.1 | 高 | 阻断 |
| R12 | ❌ | 本地化/截图语言不一致 | 2.3 | 中 | 中 |
| R13 | ❌ | Required Reason API 隐私清单缺失 | App Store Connect 处理规则 | 高 | 阻断 |

---

## 3. 分项详解与解决方案

### R1. 商标与仿冒（最可能直接拒）

**触发依据（审核视角）**

- 应用显示名、启动页、Tab、Pro 页、PDF 元数据均使用 **「Splitwise」**。  
- Bundle ID：`com.splitwise.ios.app`。  
- 产品文案与结构高度模仿知名应用 Splitwise。  
- Guideline **4.1**（Copycats）、**5.2.1**（知识产权）。

**可能拒信关键词**

> “Your app… closely resembles…”, “intellectual property”, “brand”, “copycat”

**解决方案（必须）**

1. **全面重命名**（显示名、工程名、Bundle ID、订阅 Product ID、商店截图文案）。  
2. 图标、配色、文案避免「一眼假官方」。  
3. ASC「App 名称」做全球查重；避免包含 Splitwise。  
4. 若曾开源 README 写「复刻」，商店页与审核备注 **不要**引用该表述。  
5. 法务层面：不要使用对方商标做 ASO 关键词堆砌。

**验收标准**

- 二进制内字符串检索无未授权品牌名（或仅历史无关第三方库说明）。  
- 商店元数据、IAP 显示名全部为自有品牌。

---

### R2. 应用不完整 / 测试功能暴露

**触发依据**

- `isMockPro = true` 默认解锁全部 Pro。  
- UI 可见 **「Simulator Mock Pro Mode」**。  
- 购买失败路径强制 `isMockPro = true`。  
- Account **「Reset Demo Sample Data」**。  
- OCR **「Scan Sample Receipt (Pro Demo)」** 与识别失败回落假数据。  
- Guideline **2.1 App Completeness**。

**解决方案**

| 项 | 动作 |
|----|------|
| Mock Pro | Release 编译恒为 `false`；Toggle 仅 `#if DEBUG` |
| 购买失败 | 显示错误，不解锁 |
| Reset Demo | 删除或 Debug-only + 危险确认 |
| 样例数据 | 可选引导，非强制伪装成真实社交数据 |
| OCR Demo | 与生产路径分离；失败不填假小票 |

**审核备注建议文案（英文示例）**

> This is a fully offline bill-splitting utility. No login is required. Sample data can be dismissed on first launch. In-app purchases use StoreKit 2; sandbox tester: …

---

### R3. 订阅（In-App Purchase）合规

**触发依据**

- 存在订阅 UI 与 Product ID，但：  
  - 无 **可点击** Privacy Policy / Terms of Use（EULA）链接。  
  - 价格写死 `$2.99` / `$29.99`，未用 StoreKit 本地化价格。  
  - 试用、续订周期披露不完整（部分地区要求更严）。  
  - ASC 中若未创建同 ID 订阅组，真机审核购买会失败。  
- Guideline **3.1.1 / 3.1.2**，以及订阅披露惯例。

**解决方案**

1. **ASC 配置**  
   - App 内购买：月度/年度自动续期订阅  
   - 订阅群组、本地化、审核截图、清账说明  
   - 隐私政策 URL（App 级 + 订阅元数据）  

2. **App 内订阅页必备**  
   - 权益列表  
   - 每个商品的 **时长 + displayPrice**（来自 `Product`）  
   - 自动续订说明（可取消、何时扣款）  
   - 链接：Privacy Policy、Terms（可用 `Link` / Safari）  
   - Restore Purchases（已有，需保证可用与反馈）  

3. **功能绑定**  
   - 非 Pro 时 Pro 功能必须锁定，否则审核员会质疑「为何收费」。  
   - 若暂时无法做好 IAP： **首发移除订阅入口**，后续版本再加（通常更安全）。

4. **审核账号**  
   - 提供沙盒测试账号（若需要登录类；本 App 无登录则说明即可）。  
   - 说明如何验证免费 vs Pro（关闭 Mock 后）。

**高危决策**

> **二选一：完整合规 IAP，或完全去掉 IAP 再提审。**  
> 半成品订阅页是常见拒因。

---

### R4. 隐私权限：声明了却没用 / 误导用途

**Info.plist 现状**

| Key | 描述声称 | 代码现实 | 审核风险 |
|-----|----------|----------|----------|
| `NSCameraUsageDescription` | 拍照扫小票 | 无相机 API，仅相册选择 | 多余权限 / 不完整 |
| `NSFaceIDUsageDescription` | Face ID 保护账单 | Toggle 无 LocalAuthentication | 虚假功能 |
| `NSPhotoLibraryUsageDescription` | 选小票图 | 仅 PhotosPicker | 当前实现不需要请求完整相册权限，属于冗余 |

另外：推送开关无 APNs。

**Guideline**

- **5.1.1** 数据与权限仅在所需时请求，用途准确。  
- **2.1** 功能应可用。

**解决方案**

1. **删声明 + 删 UI**（推荐首发）：Face ID、Camera、Push。  
2. 或 **完整实现**后再保留声明。  
3. 相册：仅使用系统 PhotosPicker 时可移除完整相册用途声明；Apple 明确说明该 Picker 不需要照片库授权。若以后直接访问 PhotoKit，再添加准确用途说明。
4. 首次请求权限前用前置说明页（Purpose String 已写清）。

官方依据：[Selecting Photos and Videos in iOS](https://developer.apple.com/documentation/PhotoKit/selecting-photos-and-videos-in-ios)。

---

### R5. 元数据与功能不准确（2.3.1）

**可能被抓的「名不副实」点**

| 宣传点 | 实际 | 风险 |
|--------|------|------|
| 邮件邀请好友加入 | 仅本地创建 User | 误导 |
| 实时多币种汇率 | 静态写死汇率表 | 误导 |
| 100% 无广告（相对免费版有广告） | 无广告系统 | 虚假对比 |
| Vision AI 自动填单 | 失败塞 Mock | 体验像骗局 |
| 最少笔数 / min-flow | 实际为不保证最优的双指针贪心 | 算法宣传不实 |
| 个人账单 | 无群组时实际分给全部本地用户 | 核心功能描述不实 |
| 月度趋势 | 忽略 timeframe，跨年同月合并 | 图表宣传不实 |
| 完整复刻 Splitwise | 离线子集 | 元数据 + IP 双重风险 |
| 多语言 en/zh | 中文几乎未译 | 若商店勾选中文会有问题 |

**解决方案**

1. 重写 **App 描述、副标题、关键词、截图文案**：只承诺已实现能力。  
2. 删除「实时」「邀请注册」「无广告对比」等未实现卖点。  
3. 汇率标注「参考汇率 / 手动更新」。  
4. 商店语言与二进制本地化一致：未完成中文就不要把中文标为完整支持。  
5. 截图必须来自 **真机/模拟器真实 UI**，勿用未实现界面。

---

### R6. IAP 产品无法购买 / 配置错误

**触发场景**

- ASC 未创建 `com.splitwise.pro.monthly` / `yearly`。  
- 协议/银行/税务未完成导致 IAP 不可用。  
- 二进制 Product ID 与 ASC 不一致。  
- 审核员点购买无响应或立刻「变 Pro」（Mock）。

**解决方案**

1. 在 App Store Connect 完成：付费 App 协议、银行、税务。  
2. 创建订阅产品并置于「准备提交」且随版本一起送审。  
3. 使用沙盒完整走通：购买 → 恢复 → 过期/取消（尽可能）。  
4. 订阅页加载中/空商品列表要有 UI，禁止静默 Mock。

---

### R7. App Icon 与视觉资产

**状态修正**

- `AppIcon-1024.jpg` 是 1024×1024、无 alpha 的 JPEG。
- Xcode 26.3 Debug/Release 构建均成功，资产目录正确生成最终图标，所以“JPEG 会直接导致上传失败”没有被本次验证支持。
- Apple HIG 对光栅 App Icon 推荐 PNG（无损），JPEG 仍可能带来压缩伪影与品牌质量问题。

**可能结果**

- 更现实的风险是视觉质量、旧式单外观资产和品牌相似度，不应列为中高概率独立拒因。

**解决方案**

1. 替换为无损 PNG 或 Icon Composer 资产。
2. 避免过多文字、避免与系统 App 混淆。  
3. 检查 Default/Dark/Tinted 外观及暗黑背景辨识度。

官方依据：[App icons HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons)。

---

### R8. 最低功能与「Demo 感」（4.2）

**审核员可能的体验**

- 打开即是虚构人物 Alex/Sarah 的账单。  
- 无账号却像社交 AA 产品。  
- 多处 Demo、Reset Sample、假 OCR。  
- 核心余额若因 `currentUserId` Bug 全显示 settled，会被认为 **不能用**。

**Guideline 4.2**

- 应用需提供持久价值；纯模板/演示易被拒。

**解决方案**

1. 修复余额逻辑（见问题分析 I-01）。  
2. 首启：**空白开始** 为主路径；示例数据可选且可清空。  
3. 保证审核员 3 分钟路径：  
   - 建群 → 加成员 → 记一笔 → 看余额 → 记一笔还款 →（可选）导出。  
4. 审核备注写清上述路径（英文）。

**推荐审核备注（可粘贴）**

```text
Review notes:
1. [APP_NAME] is an offline bill-splitting utility. No account/login is required.
2. All user-entered expense data is stored on-device with SwiftData.
3. On first launch, create a group or explicitly choose the optional sample-data path.
4. Main path: Groups → Create Group → Add Expense → Split → Record a Payment.
5. Receipt OCR uses the system Photos picker and on-device Vision.
6. IAP: [PRODUCT_IDS]. Restore Purchases is available on [PATH].
7. No camera, Face ID, or push-notification feature is included in this build.
8. Sandbox details: [ONLY IF REQUIRED].
```

（提交前按最终实现改写品牌名与权限说明。）

---

### R9. App Privacy（隐私营养标签）填写错误

**当前数据行为（基于代码）**

- 数据主要存 **本机 SwiftData**。  
- 无可见分析 SDK、无账号服务器。  
- 小票图片可存本地 `receiptImageData`。  
- 订阅走 Apple，不经你的服务器（若未自建校验）。

**常见误填**

- 勾选了「收集邮箱/联系人」但实际没有。  
- 未说明照片用于 OCR 且仅设备处理。  
- 声明「用于追踪」但未 ATT（本 App 似乎无广告追踪）。

**解决方案**

1. ASC App Privacy 问卷与真实 SDK 清单对齐。  
2. 照片：用途「App 功能」，不用于追踪；说明 on-device。  
3. 发布可访问的 **隐私政策网页**（即使不收集数据也要写清）。  
4. 若未来加崩溃统计（如无隐私 SDK），更新问卷与政策。

---

### R10. 出口合规与加密问卷

**现状**

- 工程未见 `ITSAppUsesNonExemptEncryption` 显式配置。  
- 仅用 HTTPS（若有）/系统 API 通常可选「豁免」类答复。

**解决方案**

- 提交时如实回答加密问卷。  
- 仅标准 HTTPS + 系统加密时，多数选择豁免并在 Info 中设  
  `ITSAppUsesNonExemptEncryption = false`（按你实际使用情况）。  
- 不要猜测；对照 Apple 出口合规文档。

---

### R11. 稳定性与主路径故障（2.1 Performance – Bugs）

**已知高危 Bug**

- `currentUserId` 与 `isCurrentUser` 不一致 → 余额全错，像「坏掉的应用」。  
- “No Group (Individual)” 把账单分给全部用户；缺少当前用户时还能保存随机 payer UUID。
- Exact / Percentage / Shares / Itemized 没有保存前不变量校验，OCR items 未进入 itemized splits。
- 图表忽略 timeframe、跨年同月合并，且跨币种直接相加。
- 订阅冷启动不读取当前 entitlements；关闭 Mock 后，已付费用户也可能显示未订阅。
- `ModelContainer` 失败 `fatalError`。  
- PDF 只导出前 30 条 expense 且不含 settlement；持久化/导出失败普遍被 `try?` 静默吞掉。

**解决方案**

1. 真机 + 多机型跑通主路径（iPhone SE / Pro Max / iPad）。  
2. 修复身份、参与者集合、分摊不变量和余额后再提审。
3. 增加 Test target；当前不是“测试通过”，而是根本没有测试动作。
4. 避免审核包带调试断言崩溃，并为持久化失败提供可见错误。

---

### R12. 其他中低风险项

| 项 | 说明 | 处理 |
|----|------|------|
| 登录 | 无第三方登录则无需 Sign in with Apple | 保持「无需登录」表述一致 |
| 支付结清 | 未集成微信支付等 SDK，仅记录 | 勿在元数据写「支持微信付款」 |
| 未成年人 | 财务工具通常 4+ 或 12+ | 年龄分级按内容问卷如实 |
| 多语言商店 | 勾选语言需与 UI 匹配 | 未译完就只上英文商店页 |
| 4.2.3 Web 套壳 | 本 App 为原生，风险低 | 保持原生即可 |
| 重复提交 | 同功能换马甲 | 单一品牌、单一 Bundle |

---

### R13. Required Reason API 隐私清单缺失（上传阻断）

**状态：❌ 未修复**

- App 使用 `UserDefaults` / `@AppStorage`，但源码和实际 Release App 都没有 `PrivacyInfo.xcprivacy`。
- Apple 明确要求 App 自身代码使用 Required Reason API 时，在所属 bundle 的隐私清单中声明类别和批准理由。
- 当前用途是读写仅本 App 可见的偏好，通常对应：
  - `NSPrivacyAccessedAPICategoryUserDefaults`
  - `CA92.1`

**验收标准**

1. `PrivacyInfo.xcprivacy` 已加入 App target resources。
2. Archive 产物内可找到该文件。
3. Xcode Privacy Report 与 ASC 上传处理均无 Required Reason API 缺失提示。

官方依据：[Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)、[Required Reason API](https://developer.apple.com/documentation/BundleResources/describing-use-of-required-reason-api)。

---

## 4. 按 Guideline 归类速查

| Guideline | 本项目触点 | 动作 |
|-----------|------------|------|
| **2.1 Completeness** | Mock、Demo、空 IAP、余额 Bug | 去测试代码、修主路径 |
| **2.3 Metadata** | 名不副实卖点 | 改描述与截图 |
| **3.1.1/3.1.2 IAP** | 订阅页、恢复购买、链接 | 合规化或移除 IAP |
| **4.1 Copycats** | Splitwise 命名与仿冒 | **强制改名** |
| **4.2 Minimum Functionality** | Demo 感、不可用余额 | 真价值路径 + 可选样例 |
| **5.1 Privacy** | 权限与问卷 | 对齐实现；政策 URL |
| **5.2.1 IP** | 商标 | 改名、无侵权素材 |
| **Required Reason API** | UserDefaults 无隐私清单 | `PrivacyInfo.xcprivacy` + `CA92.1` |

---

## 5. 上架前必做清单（Checklist）

### 5.1 法律与品牌（阻塞）

- [ ] 确定原创 App 名称并完成基础商标检索  
- [ ] 更换 Bundle ID（不再使用 `com.splitwise.*`）  
- [ ] 全应用字符串与商店文案去侵权品牌  
- [ ] 上线 Privacy Policy URL  
- [ ] 上线 Terms of Use URL（有订阅时强烈必须）  

### 5.2 二进制质量（阻塞）

- [ ] 修复 `currentUserId` / 余额  
- [ ] 修复 No Group 参与者集合、好友 1 对 1 入口与随机 payer
- [ ] 为所有分摊模式增加保存前校验；OCR items 完整进入 Itemized
- [ ] 修复多币种、图表 timeframe/年月与债务算法宣传
- [ ] Release 关闭 Mock Pro；移除审核可见 Demo 开关  
- [ ] OCR 失败不写入假数据  
- [ ] 删除未实现的 Face ID / 推送 / 相机（或做完）  
- [ ] 加入 `PrivacyInfo.xcprivacy`，Archive 中验证 UserDefaults Required Reason
- [ ] 修复 PDF 30 条截断、漏 settlement 与 CSV 公式注入
- [ ] 新增 Test target 并覆盖审核主路径
- [ ] 清除 Release 的 StoreKit 编译警告
- [ ] 真机主路径回归无崩溃  

### 5.3 商业与 IAP（若保留订阅）

- [ ] ASC 订阅产品与二进制 ID 一致  
- [ ] 付费协议 / 银行 / 税务完成  
- [ ] 动态价格 + 续订文案 + 法律链接  
- [ ] Pro 功能真实锁定  
- [ ] 沙盒购买与恢复验证  

### 5.4 若暂不订阅（更快过审策略）

- [ ] 移除 Pro 购买页与 StoreKit 依赖入口  
- [ ] 所有功能免费或仅「后续版本」标注  
- [ ] 商店描述不提 IAP  

### 5.5 ASC 元数据

- [ ] 准确描述（本地离线 AA，非社交邀请平台）  
- [ ] 截图与实际 UI 一致  
- [ ] 隐私问卷与实现一致  
- [ ] 审核备注含操作路径与沙盒账号  
- [ ] 支持 URL / 营销 URL（可指向政策站）  

---

## 6. 推荐提审策略

### 策略 A：最小可过审（约 1–2 周，推荐）

1. 改名 + 新 Bundle ID  
2. 修身份/个人账单/分摊/多币种 + 去 Mock/Demo
3. 加隐私清单并完成权限最小化
4. 砍订阅或做完整合规二选一（倾向 **首发砍订阅**）
5. 隐私政策 + 英文商店页  
6. Test target + 真机主路径回归

### 策略 B：完整商业版（约 3–6 周）

1. 在 A 基础上加合规 IAP 与真实 Pro 门禁  
2. 完整本地化  
3. 改进 OCR 与导出  
4. 可选 iCloud 备份  

### 不推荐

- 当前状态直接 Archive 提交  
- 保留 Splitwise 名称「先过审再改」（通常直接拒且浪费周期）  
- 对审核员隐瞒 Mock 开关  

---

## 7. 预估拒信场景与应对

| 场景 | 典型拒因 | 你的修复包 |
|------|----------|------------|
| 首次提交 | 4.1 / 5.2 仿冒 | 改名重打包 |
| 二次提交 | 2.1 测试功能 / IAP | 去 Mock；修好订阅或移除 |
| 三次提交 | 2.3 元数据不准 | 改描述与截图，对齐功能 |
| 偶发 | 5.1 权限 | 删多余权限，更新政策 |

**Reply to App Review 原则**

- 简短、英文、列已修改点 + 构建号。  
- 附复现路径证明已修复。  
- 不要争辩商标若你确实用了他人品牌。  

---

## 8. 结论

以 **当前仓库状态** 提交 App Store Connect：

1. **品牌（Splitwise）** 一项即足以被拒。  
2. **缺失 Required Reason API 隐私清单** 可能在上传处理阶段直接阻断。
3. **Mock Pro / Demo / 假 OCR** 会被认定为未完成应用。
4. **半成品订阅** 与 **虚假权限** 进一步拉高拒审率。
5. **身份、个人账单、分摊和多币种 Bug** 可能导致审核员判定应用不可用。

**最低可行过审路径：**  
**改名 → 修正确性 → 去测试残留 → 权限与文案诚实 → 隐私政策齐全 →（IAP 完整做或整块拿掉）。**

详细产品与技术问题见：  
**[APP_ISSUES_AND_SOLUTIONS.md](./APP_ISSUES_AND_SOLUTIONS.md)**。

---

## 9. 文档维护

| 字段 | 值 |
|------|-----|
| 路径 | `docs/APP_STORE_REVIEW_RISKS.md` |
| 配套 | `docs/APP_ISSUES_AND_SOLUTIONS.md` |
| 当前代码基线 | `1480a9906a0c` |
| 当前状态 | R1–R5、R8、R11–R13 未修；R6/R9/R10 含外部待核验项；R7 已降级 |
| 下次复评建议 | 完成 Phase 0–2 修复后，按本清单逐项打勾再 Archive |

---

## 10. 官方参考（本次复评）

- [App Review Guidelines（Last Updated: 2026-06-08）](https://developer.apple.com/app-store/review/guidelines/)
- [Offer auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Describing use of required reason API](https://developer.apple.com/documentation/BundleResources/describing-use-of-required-reason-api)
- [Selecting Photos and Videos in iOS](https://developer.apple.com/documentation/PhotoKit/selecting-photos-and-videos-in-ios)
- [App icons HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons)
