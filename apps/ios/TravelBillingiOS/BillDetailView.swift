
import SwiftUI
import UIKit

struct BillDetailView: View {
    let bill: Bill
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Section
                    if let imagePath = bill.imagePath {
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let fullURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(imagePath)
                        
                        if let image = UIImage(contentsOfFile: fullURL.path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        } else {
                            // Debug view for failed image load
                            VStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.orange)
                                            Text("无法加载图片")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            let exists = FileManager.default.fileExists(atPath: fullURL.path)
                                            Text("文件存在: \(exists ? "是" : "否")")
                                                .font(.caption2)
                                                .foregroundColor(exists ? .green : .red)
                                            
                                            Text("Path: \(fullURL.path)")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        }
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    } else {
                        // Debug view for nil imagePath
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    // Use 'photo' with strikethrough logic or simpler icon if available
                                    // But safer to just use 'photo' and maybe tint it gray
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("无发票图片 (Path is nil)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .cornerRadius(12)
                    }
                    
                    // Details Section
                    VStack(spacing: 16) {
                        DetailRow(label: "金额", value: "\(bill.amount) \(bill.currency ?? "")")
                        DetailRow(label: "类别", value: bill.category.displayName)
                        DetailRow(label: "日期", value: bill.date.formatted(date: .long, time: .omitted))
                        if let note = bill.note, !note.isEmpty {
                            DetailRow(label: "备注", value: note)
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("删除账单")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("账单详情")
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("删除", role: .destructive) {
                    if let onDelete = onDelete {
                        onDelete()
                    }
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除这笔账单吗？此操作无法撤销。")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
