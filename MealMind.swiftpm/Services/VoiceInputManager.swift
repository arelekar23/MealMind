//
//  VoiceInputManager.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/22/26.
//

import Foundation
import Speech
import AVFoundation
import AudioToolbox

@MainActor
class VoiceInputManager: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    var onResult: ((String) -> Void)?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var silenceTimer: Timer?
    private var maxTimer: Timer?
    private let silenceTimeout: TimeInterval = 2.0
    private let maxDuration: TimeInterval = 30.0
    
    private func playStartTone() {
        AudioServicesPlaySystemSound(1110)
    }
    
    private func playCancelTone() {
        AudioServicesPlaySystemSound(1111)
    }
    
    func startListening() {
        guard !isListening else { return }
        errorMessage = nil
        transcribedText = ""
        
        Task {
            let micOK = await withCheckedContinuation { cont in
                AVAudioApplication.requestRecordPermission { granted in cont.resume(returning: granted) }
            }
            guard micOK else { errorMessage = "Microphone access denied."; return }
            
            let speechOK = await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { status in
                    cont.resume(returning: status == .authorized)
                }
            }
            guard speechOK else { errorMessage = "Speech recognition denied."; return }
            
            beginRecognition()
        }
    }
    
    private func beginRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            errorMessage = "No audio input available."
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let hasError: String? = {
                guard let error else { return nil }
                let nsErr = error as NSError
                if nsErr.domain == "kAFAssistantErrorDomain" && (nsErr.code == 216 || nsErr.code == 309) { return nil }
                return error.localizedDescription
            }()
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let text {
                    self.transcribedText = text
                    self.resetSilenceTimer()
                }
                if let hasError { self.errorMessage = hasError }
                if isFinal { self.finishWithResult(playCancelTone: true) }
            }
        })
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        
        do {
            engine.prepare()
            try engine.start()
            
            isListening = true
            playStartTone()
            startMaxTimer()
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            cleanup(playCancelTone: false)
        }
    }
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.finishWithResult(playCancelTone: true) }
        }
    }
    
    private func resetSilenceTimer() {
        startSilenceTimer()
    }
    
    private func startMaxTimer() {
        maxTimer?.invalidate()
        maxTimer = Timer.scheduledTimer(withTimeInterval: maxDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.finishWithResult(playCancelTone: true) }
        }
    }
    
    private func finishWithResult(playCancelTone: Bool) {
        let finalText = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanup(playCancelTone: playCancelTone)
        if !finalText.isEmpty { onResult?(finalText) }
    }
    
    func stopListening() {
        playCancelTone()
        cleanup(playCancelTone: true)
    }
    
    private func cleanup(playCancelTone: Bool) {
        if playCancelTone, isListening {
            playCancelTone
        }
        
        silenceTimer?.invalidate(); silenceTimer = nil
        maxTimer?.invalidate(); maxTimer = nil
        
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
