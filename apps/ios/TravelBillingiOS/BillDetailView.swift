import SwiftUI
import UIKit

struct BillDetailView: View {
    let bill: Bill
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isShowingFullImage     = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Receipt image
                        if let imagePath = bill.imagePath {
                            let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let url = URL(fileURLWithPath: dir).appendingPathComponent(imagePath)
                            if let image = UIImage(contentsOfFile: url.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                                    .onTapGesture { isShowingFullImage = true }
                                    .padding(.horizontal)

                                Text("点按查看大图")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        // Category hero
                        VStack(spacing: 12) {
                            Image(systemName: bill.category.icon)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(bill.category.color)
                                .frame(width: 72, height: 72)
                                .glassEffect(.regular.tint(bill.category.color), in: .circle)

                            Text(bill.category.displayName)
                                .font(Theme.headlineFont())
                                .foregroundColor(Theme.textPrimary)

                            let amount = NSDecimalNumber(decimal: bill.amount).doubleValue
                            Text("\(amount, specifier: "%.2f") \(bill.currency ?? "")")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
                        .padding(.horizontal)

                        // Details
                        VStack(spacing: 0) {
                            detailRow(label: "日期", value: bill.date.formatted(date: .long, time: .omitted))
                            if let note = bill.note, !note.isEmpty {
                                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                                detailRow(label: "备注", value: note)
                            }
                            if !bill.participants.isEmpty {
                                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                                detailRow(label: "参与者", value: bill.participants.map { $0.name }.joined(separator: ", "))
                            }
                        }
                        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
                        .padding(.horizontal)

                        // Delete button
                        if onDelete != nil {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除账单")
                                }
                                .font(Theme.headlineFont())
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.tint(.red), in: .rect(cornerRadius: Theme.cornerRadius))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("账单详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("删除", role: .destructive) { onDelete?(); dismiss() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这笔账单吗？此操作无法撤销。")
            }
            .fullScreenCover(isPresented: $isShowingFullImage) {
                if let imagePath = bill.imagePath {
                    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let url = URL(fileURLWithPath: dir).appendingPathComponent(imagePath)
                    if let image = UIImage(contentsOfFile: url.path) {
                        ZoomableImageView(image: image) { isShowingFullImage = false }
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.subheadlineFont())
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.subheadlineFont())
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
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
