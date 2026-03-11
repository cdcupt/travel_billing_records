
import SwiftUI
import UIKit

struct BillDetailView: View {
    let bill: Bill
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isShowingFullImage = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Section
                    if let imagePath = bill.imagePath {
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let fullURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(imagePath)
                        
                        if let image = UIImage(contentsOfFile: fullURL.path) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 400)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                    .onTapGesture {
                                        isShowingFullImage = true
                                    }
                                
                                Text("点按图片查看大图，支持缩放")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
            .fullScreenCover(isPresented: $isShowingFullImage) {
                // Reload image from disk to avoid依赖额外 state，防止出现瞬间为空导致闪退/自动关闭
                if let imagePath = bill.imagePath {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let fullURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(imagePath)
                    
                    if let image = UIImage(contentsOfFile: fullURL.path) {
                        ZoomableImageView(image: image) {
                            isShowingFullImage = false
                        }
                    } else {
                        // 显示简单的错误界面，而不是瞬间关闭
                        VStack(spacing: 16) {
                            Color.black.opacity(0.9)
                                .ignoresSafeArea()
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.orange)
                                        Text("无法加载大图")
                                            .foregroundColor(.white)
                                        Button("关闭") {
                                            isShowingFullImage = false
                                        }
                                        .padding(.top, 8)
                                    }
                                )
                        }
                    }
                } else {
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("没有可显示的图片")
                                    .foregroundColor(.white)
                                Button("关闭") {
                                    isShowingFullImage = false
                                }
                                .padding(.top, 8)
                            }
                        )
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

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let onClose: () -> Void
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.backgroundColor = UIColor.black
        scrollView.delegate = context.coordinator
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(singleTap)
        
        singleTap.require(toFail: doubleTap)
        
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.onClose = onClose
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        var onClose: () -> Void
        
        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view?.superview as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let location = gesture.location(in: gesture.view)
                let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: location, scrollView: scrollView)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            onClose()
        }
        
        private func zoomRectForScale(scale: CGFloat, center: CGPoint, scrollView: UIScrollView) -> CGRect {
            var zoomRect = CGRect.zero
            if let imageView = imageView {
                zoomRect.size.height = imageView.frame.size.height / scale
                zoomRect.size.width  = imageView.frame.size.width  / scale
                let newCenter = imageView.convert(center, from: imageView)
                zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
                zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
            }
            return zoomRect
        }
    }
}
