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

                Section("Consiglio") {

                    Text("""
                    Per una voce più naturale installa una voce premium Apple.

                    Vai in:
                    Impostazioni → Accessibilità → Contenuto letto → Voci → Italiano

                    e scarica Luca o Elsa in qualità avanzata.
                    """)
                    .font(.footnote)
                }
            }
            .navigationTitle("Audio")
        }
    }
}
