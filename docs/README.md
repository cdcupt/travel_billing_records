# 旅游记录账单 App 设计与架构（iOS）

## 产品目标
- 创建旅行项目，集中记录本次旅行所有账单
- 通过文字、语音、图片上传账单，自动记录与分类
- 统计并可视化每次旅行的开销（图表/表格）

## 技术选型
- iOS 客户端：SwiftUI + Combine（iOS 16+），Charts 进行图表展示
- 核心数据与算法：独立 SwiftPM 库（TravelBillingCore），用于模型、分类与统计
- 本地存储：JSON 文件或 Core Data；后续可扩展 iCloud 同步

## 模块划分
- TravelBillingCore（已落地）
  - 数据模型：Trip、Bill、BillCategory 等
  - 文本导入器：SimpleTextImporter（解析金额与日期占位）
  - 规则分类器：RuleBasedClassifier（中文关键字映射）
  - 统计聚合：Statistics（按类别、按日汇总）
- iOS App（生产）
  - 视图：TripsListView、TripDetailView、AddBillView、AnalyticsView
  - 语音识别：Speech 框架，将语音转文字后走文本导入与分类
  - 图片识别：Vision 框架 OCR，提取票据文本后走文本导入与分类
  - 图表展示：Swift Charts（柱状图/饼图/折线图）

## iOS 视图草图（伪代码）
```swift
struct TripsListView: View {
    @State var trips: [Trip]
    var body: some View {
        List(trips) { trip in
            NavigationLink(trip.name) {
                TripDetailView(trip: trip)
            }
        }
        .toolbar {
            Button("新建旅行") { /* 创建 Trip */ }
        }
    }
}

struct TripDetailView: View {
    @State var trip: Trip
    var body: some View {
        List {
            Section("汇总") {
                Text("总开销 \(trip.totalAmount) \(trip.currency)")
            }
            Section("账单") {
                ForEach(trip.bills) { bill in
                    Text("\(bill.category.rawValue) - \(bill.amount) \(bill.currency)")
                }
            }
        }
        .toolbar {
            Menu("添加账单") {
                Button("文字") { /* 文本输入 -> SimpleTextImporter */ }
                Button("语音") { /* Speech 转文字 -> 导入 */ }
                Button("图片") { /* Vision OCR -> 导入 */ }
            }
        }
    }
}
```

## 图表展示（Swift Charts 示例）
```swift
import Charts

struct CategoryChartView: View {
    let data: [CategorySummary]
    var body: some View {
        Chart(data, id: \.category) {
            BarMark(
                x: .value("金额", $0.total as NSDecimalNumber),
                y: .value("类别", $0.category.rawValue)
            )
        }
    }
}
```

## 数据流
1. 用户选择导入方式（文字/语音/图片）
2. 语音/图片走 iOS 框架转文字（Speech / Vision）
3. 文本进入 SimpleTextImporter 提取金额与日期（占位）
4. RuleBasedClassifier 根据中文关键字分类
5. 生成 Bill，写入 Trip，触发 Statistics 汇总
6. Swift Charts 展示分类与每日统计图表

## 多人分摊与货币
- Bill 支持参与者分摊 ParticipantShare；后续可加入自动平均分摊
- 货币字段保留，后续接入汇率转换服务

## 目录与代码
- 目录与代码
- SwiftPM 核心库
  - [Package.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Package.swift)
  - [Models.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Sources/TravelBillingCore/Models.swift)
  - [Classification.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Sources/TravelBillingCore/Classification.swift)
  - [Statistics.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Sources/TravelBillingCore/Statistics.swift)
  - 测试： [ClassificationTests.swift](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/Tests/TravelBillingCoreTests/ClassificationTests.swift)
- 生产工程
  - Mac： [TravelBillingMac.xcodeproj](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/macos/TravelBillingMac.xcodeproj)
  - iPhone： [TravelBillingiOS.xcodeproj](file:///Users/bytedance/Documents/trae_projects/travel_billing_records/apps/ios/TravelBillingiOS.xcodeproj)

## 后续集成步骤
- 使用 Xcode 创建 iOS App，添加 SwiftPM 依赖 TravelBillingCore
- 实现视图层与导入管道（Speech、Vision）
- 完善金额/日期解析（正则与自然语言时间解析）
- 引入持久化与同步（Core Data / iCloud）
