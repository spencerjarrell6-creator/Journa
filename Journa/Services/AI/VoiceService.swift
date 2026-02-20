import Speech
import AVFoundation
import SwiftUI
import Combine

class VoiceService: ObservableObject {
    static let shared = VoiceService()
    
    @Published var isListening = false
    @Published var transcribedText = ""
    
    private var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var engine = AVAudioEngine()
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func startListening(onUpdate: @escaping (String) -> Void) async {
        let granted = await requestPermission()
        guard granted else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request = request else { return }
            request.shouldReportPartialResults = true
            
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            
            engine.prepare()
            try engine.start()
            
            await MainActor.run { isListening = true }
            
            task = recognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        onUpdate(text)
                    }
                }
            }
        } catch {
            print("Voice error: \(error)")
        }
    }
    
    func stopListening() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()  // use finish instead of cancel to get final result
        request = nil
        task = nil
        isListening = false
    }
}
