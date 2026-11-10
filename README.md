# 花拾归匣

物有所归，心有所安。

花拾归匣是一款面向美好生活资产管理的应用。当前主工程已迁移为原生 Flutter + Dart，可运行于 iOS、Android 与 Web。

## Flutter 版本功能

- **首页**：今日一物主视觉、优先级行动建议、紧凑生活数据、快捷入口和横向物品架
- **匣中之物**：搜索、生活陈列/使用台账/按位置收纳三种视图、拾入、编辑、照片选择、详情与删除
- **一物一页**：最多 9 张照片、购买币种、最近使用光景、完整生命轨迹与相伴之物
- **物品关联**：双向维护组合物品，并汇总组合使用日均和拥有日均
- **使用记录**：按状态历史累计真实使用区间，自动排除闲置和维修时间；也可手动增加/减少使用次数
- **归处**：空间地图、暂未归处理、搜索、添归处和快速调整物品位置
- **匣中光景**：时间范围切换、使用率结论、优先行动提醒、目标成本对比、进入生活节奏和可折叠明细
- **心愿匣**：冷静期、仍想要/放弃决策、避免花费和心愿记录
- **闲置回血**：待决定/计划处理/完成处理、参考回血区间、目标价格、计划日期和扣除运费手续费后的净回血
- **珍爱与成就**：珍爱之物、匣光星图和 5 组 44 枚徽章
- **拾花人**：个人资料编辑、头像上传、账号退出/注销、10 套皮肤、跟随系统和隐私说明
- **游客模式**：每个游客会话最多添加 3 次物品；数据仅保存在本机，并在首次进入游客模式 3 天后自动清理
- **登录同步**：登录后合并账号云端数据与游客数据，并上传游客物品照片
- **持续同步**：账号模式下本机修改会在后台写回云端，首页下拉可拉取最新数据；页面不展示常驻云同步状态横幅
- **隐私与协议**：隐私政策与服务协议双 Tab，正文只从服务端配置读取，不保留本地兜底文本
- **首次协议门禁**：首次使用或协议版本更新后以模态弹窗要求阅读并同意，普通用户二次拒绝后停留在阻断状态
- **版本更新**：首页静默检查后端版本配置，支持普通更新 24 小时稍后提醒、强制更新、外部下载和复制下载链接兜底
- **本地持久化**：移动端使用 SQLite，Web 使用 `shared_preferences`；包含 schema 版本、上一版本备份、损坏保护、串行写入和旧数据自动迁移
- **图片管理**：照片保存、替换、删除和清空数据时同步清理；缩略图按显示尺寸解码
- **资源精简**：Flutter 包只包含主图标和分类图片，旧 tabBar、徽章 SVG 与多套桌面图标不再进入资源包

首次安装不会载入演示数据，游客物品、心愿和收纳记录由用户自行添加。

## 技术栈

- Flutter 3.47+
- Dart 3.13+
- Material 3
- `flutter_localizations`：简体中文日期与系统组件
- `sqflite`：移动端本地数据库
- `shared_preferences`：Web 端存储与旧版本数据迁移
- `flutter_secure_storage`：iOS Keychain / Android Keystore 会话 Token
- `http`：登录、云配置同步、版本/协议公共配置
- `encrypt`：登录密码 AES-ECB 加密
- `package_info_plus`：读取当前应用版本
- `url_launcher`：打开版本下载地址
- `image_picker`：物品照片选择
- `path_provider`：照片持久化目录

## 目录结构

```text
lib/
  main.dart                 应用启动
  app.dart                  MaterialApp 与主导航
  models.dart               物品、心愿、分类、状态和成本指标
  app_store.dart            全局状态与事务式持久化
  components/               筛选栏、快捷入口、菜单行和物品列表卡片
  services/api/             统一请求、响应码、Token 与超时处理
  services/                 登录、云同步、版本更新和协议服务
  storage/                  SQLite、Web 存储和图片文件服务
  theme.dart                Flutter 主题
  widgets.dart              通用卡片、按钮、图片和弹窗组件
  screens/                  全部页面
test/                       数据模型测试
ios/                        iOS 原生工程
android/                    Android 原生工程
web/                        Web 工程
static/image/               从原项目沿用的图片素材
```

工程已完整迁移为 Flutter + Dart，不再依赖旧跨端框架或 JavaScript 构建链。

## 本地运行

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

指定 iOS 模拟器：

```bash
flutter devices
flutter run -d <device-id>
```

当前验证环境：

- Flutter 3.47.8 / Dart 3.13.7
- iPhone 17 Pro，iOS 26.2 模拟器
- `flutter analyze`：0 问题
- `flutter test`：91 项通过

持久化数据会在每次成功修改前保留上一份快照。主数据损坏时优先从备份恢复；若没有可用备份，应用会阻止写入并保留原始损坏文件，避免用空数据静默覆盖。

## 迁移边界

Flutter 版本已接入原项目的密码登录、验证码登录、用户详情、云配置读写和 OSS 图片上传接口。首次使用默认进入游客模式，登录时执行游客数据合并与云端写入；同步失败会保留全部游客数据。

当前网关为 `https://dmjz.makcabxa02y.icu`，登录和版本更新使用后端应用标识“花拾归匣”。公共配置主键使用 `ZD_PRIVACY_PROTOC` 和 `ZD_REGISTER_PROTOC`，正文只从远程读取，不保留本地兜底。

每件物品支持人民币、美元、港币、欧元、日元和英镑；人民币合计会明确排除外币，避免未配置汇率时直接混合金额。

线上服务仍待补齐 Token 刷新。当前 API、资源和协议网页配置可通过 Dart Define 覆盖：

```bash
flutter run \
  --dart-define=API_BASE_URL=https://example.com \
  --dart-define=APP_BRAND=应用标识 \
  --dart-define=RESOURCE_BASE_URL=https://cdn.example.com \
  --dart-define=AGREEMENT_PAGE_URL=https://example.com/agreement.html \
  --dart-define=AGREEMENT_OPERATOR_NAME=运营主体 \
  --dart-define=AGREEMENT_CONTACT_EMAIL=privacy@example.com
```

Web 端图片使用 IndexedDB Blob 持久保存，刷新页面后仍可读取；协议网页入口使用 `web/agreement.html`，未配置 iOS 协议网页地址或网页无法打开时会回退到 App 原生协议页。账号修改会先完成本地持久化，再由后台同步队列合并上传，不阻塞后续操作。

