# Mac 演示快速指南（SwiftUI + TravelBillingCore）

## 目标
将已有的 SwiftUI 示例界面代码接入到一个 macOS App（Xcode 工程），在 Mac 上直接运行并查看列表、详情与分类图表。

## 依赖
- Xcode 15+
- macOS 13+（Swift Charts 需要 13 及以上）

## 步骤
1. 打开 Xcode，创建新项目
   - File → New → Project → macOS → App
   - 使用 SwiftUI，Interface 选 SwiftUI，Language 选 Swift
   - 最低版本选择 macOS 13 或更高
2. 添加 Swift 包依赖（本地）
   - Xcode → File → Add Packages → 选择 “Add Local…”
   - 指定路径：/Users/bytedance/Documents/trae_projects/travel_billing_records
   - 选择产品 TravelBillingCore 作为依赖，添加到你的 App Target
3. 导入生产界面代码
   - 将以下文件拖入你的 App 工程（勾选 “Copy items if needed”）：
     - apps/macos/TravelBillingMac/App.swift
     - apps/macos/TravelBillingMac/SampleData.swift
     - apps/macos/TravelBillingMac/TripsListView.swift
     - apps/macos/TravelBillingMac/TripDetailView.swift
     - apps/macos/TravelBillingMac/AnalyticsView.swift
   - 确保以上文件的 import 正常（需要 import Charts）
4. 设置 App 入口
   - 在你的工程的 @main App 中，将根视图设置为：
     - TripsListView(trips: SampleData.trips)
5. 运行
   - 选择 “My Mac” 作为运行目标
   - 点击 Run，看到示例数据、账单列表和分类柱状图

## 文件索引
- 包依赖： [Package.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Package.swift)
- 入口： [App.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac/App.swift)
- 数据： [SampleData.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac/SampleData.swift)
- 列表视图： [TripsListView.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac/TripsListView.swift)
- 详情视图： [TripDetailView.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac/TripDetailView.swift)
- 图表视图： [AnalyticsView.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac/AnalyticsView.swift)

## 常见问题
- Charts 报错或不可用：将 App Target 的 Deployment target 设为 macOS 13+。
- 找不到 TravelBillingCore：确认通过 “Add Local…” 引入包根目录，并把产品添加到 App Target 的依赖。
- 编译失败：检查示例文件是否已勾选 “Copy items if needed”，并确保 import 语句存在。
