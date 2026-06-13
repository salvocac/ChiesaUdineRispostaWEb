import SwiftUI
import AVFoundation

struct AudioSettingsView: View {

    @AppStorage("selectedVoiceIdentifier")
    private var selectedVoiceIdentifier = ""

    private let voices = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language.starts(with: "it") }

    var body: some View {

        NavigationStack {

            Form {

                Section("Voce lettura") {

                    Picker("Voce", selection: $selectedVoiceIdentifier) {

                        ForEach(voices, id: \.identifier) { voice in
                            Text(voice.name)
                                .tag(voice.identifier)
                        }
                    }
                }
            }
            .navigationTitle("Audio")
        }
    }
}
