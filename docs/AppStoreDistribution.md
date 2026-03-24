# iOS App Store 发布指南

恭喜您完成了“旅行记账” App 的开发！接下来是将应用发布到 App Store 的完整步骤。

## 1. 准备工作

在开始之前，请确保您拥有：
- 一个 **Apple Developer Program** 账号（需付费，每年 $99）。
- 一台安装了 **Xcode** 的 Mac 电脑。
- **App Store Connect** 的访问权限。

## 2. 检查项目配置

在 Xcode 中打开您的项目 `TravelBillingiOS.xcodeproj`，完成以下配置检查：

### A. 身份信息 (Identity)
1. 选择左侧导航栏的项目根节点（蓝色的图标）。
2. 选择 Target -> `TravelBillingiOS`。
3. 在 **General** 标签页下，检查 **Identity** 部分：
   - **Display Name**: `旅行记账`（已设置）
   - **Bundle Identifier**: 这是应用的唯一标识符（例如 `com.yourname.travelbilling`）。确保它不仅唯一，而且与您在 Apple Developer 后台注册的一致。
   - **Version**: `1.0`（这是用户看到的版本号）
   - **Build**: `1`（这是内部构建号，每次上传新包必须递增）

### B. 签名与证书 (Signing & Capabilities)
1. 切换到 **Signing & Capabilities** 标签页。
2. **Team**: 选择您的开发者团队（如果显示 None，请登录您的 Apple ID 并选择付费团队）。
3. **Bundle Identifier**: 确保没有红色错误提示。
4. **Automatically manage signing**: 勾选此项（推荐新手使用，Xcode 会自动处理证书和配置文件）。

### C. 隐私权限描述 (Info.plist)
您的应用使用了相机、相册和麦克风权限，我们已经在 `Info.plist` 中为您配置好了说明文案：
- **Camera Usage Description**: 用于拍摄票据并识别文本
- **Photo Library Usage Description**: 用于选择票据照片并识别文本
- **Microphone Usage Description**: 用于语音识别录音
- **Speech Recognition Usage Description**: 用于将语音转换为账单文本

**注意**：请确保这些描述准确反映了应用的使用场景，否则审核会被拒。

## 3. 在 App Store Connect 创建应用

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)。
2. 点击 **My Apps** -> **+** -> **New App**。
3. 填写信息：
   - **Platform**: iOS
   - **Name**: 旅行记账
   - **Primary Language**: Simplified Chinese (简体中文)
   - **Bundle ID**: 选择与 Xcode 中一致的 ID。
   - **SKU**: 自定义一个唯一编号（例如 `TB001`）。
   - **User Access**: Full Access。

## 4. 构建与上传 (Archive & Upload)

这是将代码打包上传到 Apple 服务器的过程：

1. 在 Xcode 顶部工具栏，选择目标设备为 **Any iOS Device (arm64)**。
2. 菜单栏点击 **Product** -> **Archive**。
3. 等待编译完成，Xcode 会自动打开 **Organizer** 窗口。
4. 选中刚刚构建的归档文件，点击右侧的 **Distribute App**。
5. 选择 **App Store Connect** -> **Upload** -> **Next**。
6. 保持默认选项（勾选 Upload your app's symbols 等），一路点击 **Next**。
7. 最后点击 **Upload**。上传成功后会有绿色对勾提示。

## 5. 提交审核 (Submit for Review)

回到 [App Store Connect](https://appstoreconnect.apple.com) 网页：

1. 进入您刚才创建的应用页面。
2. 在左侧菜单点击 **App Store** -> **1.0 Prepare for Submission**。
3. **构建版本 (Build)**：向下滚动到 Build 部分，点击 `+` 号，选择刚才上传的版本（可能需要等待几分钟处理时间）。
4. **元数据 (Metadata)**：
   - **截图**：上传 iPhone 6.5寸 (iPhone 14 Pro Max) 和 5.5寸 (iPhone 8 Plus) 的截图。
   - **描述**：简单介绍应用功能（如：旅行记账是一款便捷的记账工具，支持 OCR 拍照识别和语音记账...）。
   - **关键词**：记账,旅行,账单,OCR,语音记账。
   - **支持 URL**：填写您的个人主页或简单的支持页面链接。
5. **分级 (Age Rating)**：如实填写问卷（通常是 4+）。
6. **审核信息 (App Review Information)**：
   - 如果应用需要登录，请提供测试账号（本项目为本地存储，无需账号）。
   - **备注**：可以在这里说明“OCR 功能需要联网”等信息。
7. 点击右上角的 **Add for Review**。
8. 再次确认信息无误后，点击 **Submit to App Review**。

## 6. 等待审核

- 状态会变为 **Waiting for Review**。
- 通常审核需要 24-48 小时。
- 如果审核通过，状态变为 **Ready for Sale**，应用就会在 App Store 上架。
- 如果被拒（Rejected），请仔细阅读 Apple 的回复，修改问题后重新打包上传（记得增加 Build Number，如改为 `2`）。

祝您的应用大受欢迎！
