import SwiftUI
import AVKit
import AVFoundation
import Speech
import WebKit

struct BibleData: Codable {
    let verses: [BibleVerse]
}

struct BibleVerse: Codable, Identifiable {

    var id: String {
        "\(book)-\(chapter)-\(verse)"
    }

    let book_name: String
    let book: Int
    let chapter: Int
    let verse: Int
    let text: String
}

struct AudioTrack: Identifiable {

    let title: String
    let url: URL

    var id: String {
        url.absoluteString
    }
}

struct HeaderLogoView: View {

    var body: some View {

        VStack(spacing: 10) {

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
            Divider()
        }
        .padding(.top, 0)    }
}

struct WebView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {

        let webView = WKWebView()
        webView.scrollView.bounces = false

        return webView
    }

    func updateUIView(_ webView: WKWebView,
                      context: Context) {

        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct WebsiteView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let url: URL
    let title: String

    var body: some View {
        
        NavigationStack {

            VStack(spacing: 0) {

                HeaderLogoView()

                WebView(url: url)
            }
            .ignoresSafeArea(edges: .bottom)

            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        dismiss()

                    } label: {

                        Image(systemName: "xmark")
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

struct BibleView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject
    private var audioManager =
    BibleAudioManager()
    @State private var selectedBook = "Genesi"
    @State private var selectedChapter = 1

    @State private var startVerse = 1
    @State private var endVerse = 1
    @State private var copied = false
    
    @State private var verses: [BibleVerse] = []

    let books = [
        "Genesi","Esodo","Levitico","Numeri","Deuteronomio",
        "Giosuè","Giudici","Rut","1 Samuele","2 Samuele",
        "1 Re","2 Re","Salmi","Proverbi","Isaia",
        "Matteo","Marco","Luca","Giovanni","Romani",
        "1 Corinzi","2 Corinzi","Galati","Efesini",
        "Filippesi","Colossesi","Apocalisse"
    ]
    
    // Build the list of available Italian voices dynamically
    let availableItalianVoices: [(String, String)] = {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "it-IT" }
        for v in voices {
            print("Disponibile: \(v.name) [\(v.quality.rawValue)]")
        }
        return voices.map { ("\($0.name) (\($0.quality == .premium ? "Premium" : "Normale"))", $0.name) }
    }()
    
    let premiumVoices: [(String, String)]
    
    @State private var selectedVoiceLabel: String

    init() {
        // Initialize premiumVoices with availableItalianVoices
        self.premiumVoices = availableItalianVoices
        
        // Initialize selectedVoiceLabel with the first voice label or empty string if none
        _selectedVoiceLabel = State(initialValue: premiumVoices.first?.0 ?? "")
    }

    var chapters: [Int] {

        let filtered = verses.filter {
            $0.book_name == selectedBook
        }

        let numbers = Set(filtered.map { $0.chapter })

        return numbers.sorted()
    }

    var verseNumbers: [Int] {

        let filtered = verses.filter {

            $0.book_name == selectedBook
            &&
            $0.chapter == selectedChapter
        }

        let numbers = Set(filtered.map { $0.verse })

        return numbers.sorted()
    }

    var filteredVerses: [BibleVerse] {

        verses.filter {

            $0.book_name == selectedBook
            &&
            $0.chapter == selectedChapter
            &&
            $0.verse >= startVerse
            &&
            $0.verse <= endVerse
        }
        .sorted { $0.verse < $1.verse }
    }

    var chapterText: String {

        filteredVerses
            .map {
                $0.text
            }
            .joined(separator: " ")
    }
    var copyText: String {

        """
        \(selectedBook) \(selectedChapter):\(startVerse)-\(endVerse)

        \(chapterText)
        """
    }
    var body: some View {

        NavigationStack {

            VStack {
                
                //    HeaderLogoView()
                
                VStack(spacing: 2) {
                    
                    Picker("Libro", selection: $selectedBook) {
                        
                        ForEach(books, id: \.self) { book in
                            
                            Text(book)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        
                        Text("Cap.")
                            .frame(width: 40)
                        
                        Picker("", selection: $selectedChapter) {
                            ForEach(chapters, id: \.self) { chapter in
                                Text("\(chapter)")
                            }
                        }
                        .frame(width: 80)
                        
                        Text("Da")
                            .frame(width: 30)
                        
                        Picker("", selection: $startVerse) {
                            ForEach(verseNumbers, id: \.self) { verse in
                                Text("\(verse)")
                            }
                        }
                        .frame(width: 80)
                        
                        Text("A")
                            .frame(width: 20)
                        
                        Picker("", selection: $endVerse) {
                            ForEach(verseNumbers, id: \.self) { verse in
                                Text("\(verse)")
                            }
                        }
                        .frame(width: 80)
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                
                // New premium voice picker
                
                
                HStack(spacing: 30) {
                    let selectedVoiceName = premiumVoices.first(where: { $0.0 == selectedVoiceLabel })?.1 ?? "Alice"
                    
                    Button {
                        let intro = "\(selectedBook), capitolo \(selectedChapter), versetti da \(startVerse) a \(endVerse)."
                        
                        audioManager.speak(
                            text: intro + " " + chapterText,
                            voiceName: selectedVoiceName
                        )
                    } label: {
                        
                        VStack {
                            
                            Image(systemName:
                                    "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                            
                            Text("Ascolta")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        
                        if audioManager.isPaused {
                            
                            audioManager.resume()
                            
                        } else {
                            
                            audioManager.pause()
                        }
                        
                    } label: {
                        
                        VStack {
                            
                            Image(
                                systemName:
                                    audioManager.isPaused
                                ? "play.circle"
                                : "pause.circle.fill"
                            )
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                            
                            Text(
                                audioManager.isPaused
                                ? "Riprendi"
                                : "Pausa"
                            )
                            .font(.caption)
                        }
                    }
                    
                    Button {
                        
                        audioManager.stop()
                        
                    } label: {
                        
                        VStack {
                            
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                            
                            Text("Stop")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        
                        UIPasteboard.general.string = copyText
                        
                        copied = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                        
                    } label: {
                        
                        VStack {
                            
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                            
                            Text("Copia")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical)
                if verticalSizeClass != UserInterfaceSizeClass.compact {

                    Picker("", selection: $selectedVoiceLabel) {
                        ForEach(premiumVoices, id: \.0) { voice in
                            Text(voice.0)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                if copied {
                    
                    Text("Testo copiato negli appunti")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {

                        ForEach(filteredVerses) { verse in

                            HStack(alignment: .top, spacing: 12) {

                                Text("\(verse.verse)")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)

                                Text(verse.text)
                                    .font(.system(size: 18))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }

                            Divider()
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }

            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Bibbia")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        audioManager.stop()

                        dismiss()

                    } label: {

                        Image(systemName: "xmark")
                            .fontWeight(.bold)
                    }
                }
            }

            .onAppear {

                loadBible()
            }

            .onChange(of: selectedChapter) {

                if let first = verseNumbers.first {

                    startVerse = first
                    endVerse = first
                }
            }
        }
    }

    func loadBible() {

        guard let url = Bundle.main.url(
            forResource: "diodati",
            withExtension: "json"
        ) else {

            print("❌ File JSON non trovato")
            return
        }

        do {

            let data = try Data(contentsOf: url)

            let bibleData = try JSONDecoder()
                .decode(BibleData.self, from: data)

            verses = bibleData.verses

            if let first = verseNumbers.first {

                startVerse = first
                endVerse = first
            }

        } catch {

            print(error)
        }
    }
}

struct ContentView: View {

    @State private var showBible = false
    @State private var showWebsite = false
    @State private var showYoutube = false

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [
                        Color.white,
                        Color.blue.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {

                    Spacer()

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)

                    Text("Una Parola per Te")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Chiesa Cristiana Evangelica Friulana di Udine")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Button {

                        showBible = true

                    } label: {

                        HStack {

                            Image(systemName: "book.fill")

                            Text("Apri Bibbia")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    Button {

                        showWebsite = true

                    } label: {

                        HStack {

                            Image(systemName: "globe")

                            Text("Sito Web")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    Button {

                        showYoutube = true

                    } label: {

                        HStack {

                            Image(systemName:
                                    "play.rectangle.fill")

                            Text("Canale YouTube")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    Spacer()

                    Text("© CCE Friulana di Udine")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                }
            }

            .fullScreenCover(isPresented: $showBible) {

                BibleView()
            }

            .fullScreenCover(isPresented: $showWebsite) {

                WebsiteView(
                    url: URL(
                        string:
                        "https://www.chiesacristianaudine.it"
                    )!,
                    title: "Sito Web"
                )
            }

            .fullScreenCover(isPresented: $showYoutube) {

                WebsiteView(
                    url: URL(
                        string:
                        "https://www.youtube.com/channel/UCqtwkH2xz1fFoTObbDXcpOw"
                    )!,
                    title: "YouTube"
                )
            }
        }
    }
}
