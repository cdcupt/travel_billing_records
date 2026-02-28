import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ImageImportView: View {
    var onText: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isRecognizing = false
    @State private var errorText: String?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var hasAutoLaunchedCamera = false
    
    var body: some View {
        VStack(spacing: 24) {
            if isRecognizing {
                ProgressView("正在识别账单金额...")
                    .scaleEffect(1.2)
            } else {
                Text("选择识别方式")
                    .font(.headline)
                
                Button {
                    showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.top)
            }
            
            if let errorText {
                Text(errorText)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .onAppear {
            if !hasAutoLaunchedCamera {
                showCamera = true
                hasAutoLaunchedCamera = true
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $cameraImage)
        }
        .onChange(of: cameraImage) { image in
            if let image {
                recognize(uiImage: image)
            }
        }
        .onChange(of: selectedItems) { newItems in
            guard let item = newItems.first else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    recognize(uiImage: uiImage)
                }
            }
        }
    }
    
    private func recognize(uiImage: UIImage) {
        isRecognizing = true
        errorText = nil
        
        // Run OCR in background
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = uiImage.cgImage else {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    self.errorText = "无法处理图片"
                }
                return
            }
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let strings = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                let fullText = strings.joined(separator: "\n")
                
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    // Automatically return result and close
                    self.onText(fullText)
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    self.errorText = "识别失败，请重试"
                }
            }
        }
    }
}
