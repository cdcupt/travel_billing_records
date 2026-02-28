import SwiftUI
import Speech
import AVFoundation

struct VoiceImportView: View {
    var onText: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText: String = ""
    @State private var isRecording: Bool = false
    @State private var errorText: String?
    
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    @State private var request = SFSpeechAudioBufferRecognitionRequest()
    @State private var task: SFSpeechRecognitionTask?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("语音导入")
                .font(.headline)
            TextEditor(text: $recognizedText)
                .frame(minHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))
            HStack {
                Button(isRecording ? "停止" : "开始") {
                    if isRecording { stopRecording() } else { startRecording() }
                }
                .buttonStyle(.borderedProminent)
                Button("解析为账单") {
                    onText(recognizedText)
                    dismiss()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            if let errorText {
                Text(errorText).foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            requestPermission()
        }
    }
    
    private func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status != .authorized {
                errorText = "语音识别权限未授权"
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                errorText = "麦克风权限未授权"
            }
        }
    }
    
    private func startRecording() {
        errorText = nil
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                recognizedText = result.bestTranscription.formattedString
            }
            if let error = error {
                errorText = error.localizedDescription
            }
        }
        isRecording = true
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        isRecording = false
    }
}
