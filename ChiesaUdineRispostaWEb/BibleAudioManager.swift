import Foundation
import AVFoundation
import Combine

final class BibleAudioManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published var isSpeaking = false
    @Published var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()

        synthesizer.delegate = self
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {

        do {

            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [
                    .duckOthers,
                    .allowBluetooth,
                    .allowAirPlay
                ]
            )

            try AVAudioSession.sharedInstance().setActive(
                true,
                options: .notifyOthersOnDeactivation
            )

        } catch {

            print("Errore AudioSession: \(error.localizedDescription)")
        }
    }

    // MARK: - Speech

    /// Speaks the given text. Optionally uses a specified voice by name.
    func speak(text: String, voiceName: String? = nil) {

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        let selectedVoice = UserDefaults.standard.string(
            forKey: "selectedVoiceIdentifier"
        )

        if let selectedVoice,
           let voice = AVSpeechSynthesisVoice(identifier: selectedVoice) {

            utterance.voice = voice

        } else if let voice = AVSpeechSynthesisVoice(language: "it-IT") {

            utterance.voice = voice
        }

        utterance.rate = 0.38
        utterance.pitchMultiplier = 0.95
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.language.starts(with: "it") {
                print("ITALIANA:", voice.name, "-", voice.identifier)
            }
        }
    }

    func pause() {

        guard synthesizer.isSpeaking else { return }

        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {

        guard synthesizer.isPaused else { return }

        synthesizer.continueSpeaking()
    }

    func stop() {

        synthesizer.stopSpeaking(at: .immediate)

        isSpeaking = false
        isPaused = false
    }

    // MARK: - Delegate

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {

        DispatchQueue.main.async {

            self.isSpeaking = true
            self.isPaused = false
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {

        DispatchQueue.main.async {

            self.isPaused = true
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {

        DispatchQueue.main.async {

            self.isPaused = false
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {

        DispatchQueue.main.async {

            self.isSpeaking = false
            self.isPaused = false
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {

        DispatchQueue.main.async {

            self.isSpeaking = false
            self.isPaused = false
        }
    }
}
