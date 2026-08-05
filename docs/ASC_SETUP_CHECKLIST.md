# BillNest App Store Connect 创建与提审清单

**App ID**: `6798151983`  
**Bundle ID**: `app.billnest.ios`  
**SKU**: `BILLNEST-IOS-2026`  
**Version**: `1.0` (`b9189be5-723d-4b1a-b4d5-3cb1e9435789`)  
**更新日期**: 2026-08-05

## 当前状态

| 项 | 状态 |
|----|------|
| Bundle ID + IAP + CloudKit | ✅ |
| ASC App 记录 | ✅ `6798151983` |
| 五语言 App 名称 / 副标题 / 隐私 URL | ✅ en-US / zh-Hans / zh-Hant / ja / ko |
| 五语言描述 / 关键词 / Support / Marketing | ✅（首版不可填 Whatʼs New，已省略） |
| 类目 | ✅ Finance + Productivity |
| 定价 | ✅ Free（US 基准） |
| 可用性 | ✅ 全球 175 区 + 新地区自动上架 |
| 年龄分级 | ✅ 全 NONE / false |
| 内容版权声明 | ✅ 不使用第三方内容 |
| Copyright | ✅ `2026 BillNest` |
| 加密 | ✅ 工程 `ITSAppUsesNonExemptEncryption=false`（豁免，无需 ASC 声明） |
| 审核联系人 + 备注 | ✅（复用开发者联系方式；无登录账号） |
| 订阅组 BillNest Pro | ✅ |
| `app.billnest.pro.monthly` @ $2.99 | ✅ READY_TO_SUBMIT |
| `app.billnest.pro.yearly` @ $29.99 | ✅ READY_TO_SUBMIT |
| App 截图 | ❌ **提交阻断** |
| 构建 Archive 上传并选中 | ❌ **提交阻断** |
| App Privacy（隐私营养标签） | ⚠️ 请在 ASC 网页确认并发布 |
| 订阅促销图（可选） | ⚠️ 建议补正式截图（当前为占位图） |

## 阻断项（`asc review doctor`）

1. **上传构建**：Xcode Archive → Distribute App → App Store Connect，处理完成后在 1.0 版本选中该 Build  
2. **上传截图**：至少一套 iPhone 尺寸（建议 6.7" / 6.5"）；五语言可先共用英文截图  

完成后：

```bash
asc review doctor --app "6798151983"
asc validate --app "6798151983" --version "1.0" --platform IOS
# 就绪后：
asc review submit --app "6798151983" --version "1.0" --build "BUILD_ID" --confirm
```

## 元数据本地目录

- `asc-metadata/app-info/*.json`
- `asc-metadata/version/1.0/*.json`（勿加 `whatsNew`，首版 API 拒绝）
- 推送命令：`asc metadata push --app 6798151983 --version 1.0 --dir ./asc-metadata`
- 版本文案补推：`asc apps info edit --app 6798151983 --version 1.0 --platform IOS --from-dir ./asc-metadata/version/1.0`

## 链接

- Privacy: https://asynch1889.github.io/BillNest-Legal/privacy.html  
- Terms: https://asynch1889.github.io/BillNest-Legal/terms.html  
- Support: https://github.com/aSynch1889/BillNest-Legal/issues  
- ASC: https://appstoreconnect.apple.com/apps/6798151983  
