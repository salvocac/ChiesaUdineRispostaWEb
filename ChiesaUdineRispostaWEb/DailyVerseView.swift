import SwiftUI
import AVFoundation

struct DailyVerseView: View {

    @State private var dailyVerse: DailyVerse? =
        DailyVerseManager.shared.verseOfToday()

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    if let verse = dailyVerse {

                        Text(verse.reference ?? "")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text(verse.verseText ?? "")
                            .font(.title3)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text(verse.reflection ?? "")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 40) {

                            Button {
                                play()
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title)
                            }

                            Button {
                                stop()
                            } label: {
                                Image(systemName: "stop.fill")
                                    .font(.title)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Versetto del giorno")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func play() {

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )

            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        guard let verse = dailyVerse else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let text = """
        Versetto del giorno.

        \(verse.reference ?? "")

        \(verse.verseText ?? "")

        Commento.

        \(verse.reflection ?? "")
        """

        let utterance = AVSpeechUtterance(string: text)

        if let voice = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = voice
        }

        utterance.rate = 0.5

        synthesizer.speak(utterance)
    }

    private func stop() {

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
