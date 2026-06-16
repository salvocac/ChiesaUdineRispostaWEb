import SwiftUI
import AVKit
import AVFoundation
import Speech
import WebKit
import StoreKit

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
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var verses: [BibleVerse] = []
    
    @State private var isSelecting = false
    @State private var selectedIDs: Set<String> = []
    
    // Added properties for audio playback and speech synthesis
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingMusic = false
    let speechSynthesizer = AVSpeechSynthesizer()
    
    @FocusState private var isSearchFocused: Bool

    private func performSearch() {
        // Trim spaces and ensure there's text to search
        searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return }
        // Dismiss keyboard
        isSearchFocused = false
    }
    
    private func performVerseSearch() {
        // Ensure valid range
        if endVerse < startVerse {
            swap(&startVerse, &endVerse)
        }
        // Clear text search to show range results
        if !searchText.isEmpty {
            searchText = ""
        }
        // Dismiss keyboard if active
        isSearchFocused = false
    }
    
    var books: [String] {

        let orderedBooks = Dictionary(
            grouping: verses,
            by: { $0.book }
        )

        return orderedBooks
            .sorted { $0.key < $1.key }
            .compactMap { $0.value.first?.book_name }
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
    
    var searchResults: [BibleVerse] {
        
        if searchText.isEmpty {
            return []
        }
        
        return verses.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var displayedVerses: [BibleVerse] {
        
        if searchText.isEmpty {
            return filteredVerses
        } else {
            return searchResults
        }
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
    var shareText: String {
        
        """
        \(selectedBook) \(selectedChapter):\(startVerse)-\(endVerse)
        
        \(chapterText)
        """
    }
    var searchShareText: String {
        
        searchResults.prefix(50).map {
            
            "\($0.book_name) \($0.chapter):\($0.verse)\n\($0.text)"
            
        }
        .joined(separator: "\n\n")
    }
    var copyText: String {
        
        """
        \(selectedBook) \(selectedChapter):\(startVerse)-\(endVerse)
        
        \(chapterText)
        """
    }
    var selectedShareText: String {
        let versesToShare: [BibleVerse]
        if isSelecting && !selectedIDs.isEmpty {
            let pool = searchText.isEmpty ? filteredVerses : displayedVerses
            versesToShare = pool.filter { v in
                let id = "\(v.book_name)|\(v.chapter)|\(v.verse)"
                return selectedIDs.contains(id)
            }
        } else {
            versesToShare = []
        }
        return versesToShare.map { v in
            "\(v.book_name) \(v.chapter):\(v.verse)\n\(v.text)"
        }.joined(separator: "\n\n")
    }
    
    // Function to start playing relax music
    func playRelaxMusic() {
        guard let url = Bundle.main.url(forResource: "relax", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            isPlayingMusic = true
        } catch {
            print("Could not play relax music: \(error)")
        }
    }
    // Function to pause music
    func pauseMusic() {
        audioPlayer?.pause()
        isPlayingMusic = false
    }
    // Function to speak with Luca's voice
    func speakWithLuca(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_it-IT_compact") // "Luca" voice
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    var body: some View {
        
        NavigationStack {
            
            VStack {

                HStack(spacing: 16) {
                    Button(action: {
                        if isPlayingMusic {
                            pauseMusic()
                        } else {
                            playRelaxMusic()
                        }
                    }) {
                        Image(
                            systemName: isPlayingMusic
                            ? "pause.circle.fill"
                            : "play.circle.fill"
                        )
                        .font(.largeTitle)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                VStack(spacing: 2) {
                    
                    HStack {
                        Image(systemName: "magnifyingglass")

                        TextField(
                            "Cerca una parola nella Bibbia...",
                            text: $searchText
                        )
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }

                        Button {
                            performSearch()
                        } label: {
                            Text("Cerca")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button {
                            isSelecting.toggle()
                            if !isSelecting { selectedIDs.removeAll() }
                        } label: {
                            Text(isSelecting ? "Fine selezione" : "Seleziona versetti")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)

                        Spacer()

                        if isSelecting {
                            Button {
                                // Apri ShareSheet con i versetti selezionati
                                if !selectedIDs.isEmpty {
                                    showShareSheet = true
                                }
                            } label: {
                                Text("Condividi selezionati")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(selectedIDs.isEmpty ? .gray : .blue)
                            .disabled(selectedIDs.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    
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
                    
                    HStack(spacing: 8) {
                        VStack {
                            Text("Cap.")
                                .font(.caption)
                            Picker("", selection: $selectedChapter) {
                                ForEach(chapters, id: \.self) { chapter in
                                    Text("\(chapter)")
                                }
                            }
                        }

                        VStack {
                            Text("Da")
                                .font(.caption)
                            Picker("", selection: $startVerse) {
                                ForEach(verseNumbers, id: \.self) { verse in
                                    Text("\(verse)")
                                }
                            }
                        }

                        VStack {
                            Text("A")
                                .font(.caption)
                            Picker("", selection: $endVerse) {
                                ForEach(verseNumbers, id: \.self) { verse in
                                    Text("\(verse)").tag(verse)
                                }
                            }
                        }

                        Button {
                            performVerseSearch()
                        } label: {
                            Text("Cerca")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 30) {
                        Button {
                            let intro = "\(selectedBook), capitolo \(selectedChapter), versetti da \(startVerse) a \(endVerse)."
                            
                            audioManager.speak(
                                text: intro + " " + chapterText,
                                voiceName: "com.apple.ttsbundle.siri_male_it-IT_compact"
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
                        Button {
                            

                                createVerseImage()

                            } label: {                            VStack {
                                
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                
                                Text("Condividi")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    if copied {
                        
                        Text("Testo copiato negli appunti")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                  
                    ScrollView {
                        
                        LazyVStack(alignment: .leading, spacing: 12) {
                            
                            ForEach(displayedVerses) { verse in
                                
                                HStack(alignment: .top, spacing: 12) {
                                    if isSelecting {
                                        let id = "\(verse.book_name)|\(verse.chapter)|\(verse.verse)"
                                        Button {
                                            if selectedIDs.contains(id) {
                                                selectedIDs.remove(id)
                                            } else {
                                                selectedIDs.insert(id)
                                            }
                                        } label: {
                                            Image(systemName: selectedIDs.contains(id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedIDs.contains(id) ? .blue : .gray)
                                                .font(.system(size: 22))
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if searchText.isEmpty {
                                        Text("\(verse.verse)")
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                    } else {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(verse.book_name)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                            Text("\(verse.chapter):\(verse.verse)")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.blue)
                                        .frame(width: 90, alignment: .leading)
                                    }

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
                    
                    print("BibleManager count =",
                          BibleManager.shared.verses.count)
                }
                
                .onChange(of: selectedChapter) {
                    
                    if let first = verseNumbers.first {
                        
                        startVerse = first
                        endVerse = first
                    }
                }
                
                .sheet(isPresented: $showShareSheet) {

                    if let shareImage {

                        ShareSheet(
                            items: [shareImage]
                        )

                    } else {

                        ShareSheet(
                            items: [
                                isSelecting && !selectedShareText.isEmpty
                                ? selectedShareText
                                : (searchText.isEmpty ? shareText : searchShareText)
                            ]
                        )
                    }
                }
            }
        }
    }
    
    private func loadBible() {
        guard let url = Bundle.main.url(
            forResource: "riveduta",
            withExtension: "json"
        ) else {
            print("❌ File JSON non trovato")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let bibleData = try JSONDecoder().decode(BibleData.self, from: data)
            verses = bibleData.verses

            if let first = verseNumbers.first {
                startVerse = first
                endVerse = first
            }
        } catch {
            print(error)
        }
    }
    @MainActor
    private func createVerseImage() {

        print("🔥 createVerseImage chiamata")

        let card = BrandedVerseShareCard(
            reference: "\(selectedBook) \(selectedChapter):\(startVerse)",
            verse: chapterText
        )
        .frame(width: 1080, height: 1440) // 3:4 ad alta risoluzione
        .background(Color.white)

        // Rendering sincrono su main per evitare problemi di timing
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1 // frame grande, qualità già elevata

        if let image = renderer.uiImage {
            print("✅ Immagine generata")
            shareImage = image
            showShareSheet = true
        } else {
            print("❌ renderer.uiImage NIL - non apro lo sheet, uso eventualmente fallback testuale manuale")
        }
    }
} // <-- Added closing brace for BibleView

struct ContentView: View {
    private let firstLaunchKey = "firstLaunchDate"
    private let didRequestReviewKey = "didRequestReviewOnce"

    @State private var showBible = false
    @State private var showAudio = false
    @State private var showAbout = false

    @State private var showWebsite = false
    @State private var showYoutube = false
    @State private var showDailyVerse = false
    @State private var showAudioSettings = false

   
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

                VStack(spacing: 8) {

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                        .padding(.top, 10)

                    Button {
                        showDailyVerse = true
                    } label: {
                        HStack {
                            Image(systemName: "quote.bubble.fill")
                            Text("Versetto del giorno")
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
                        showBible = true
                    } label: {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Apri Bibbia")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
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

                        if let url = URL(
                            string: "https://maps.google.com/?q=Via+Croazia+14+33100+Udine"
                        ) {
                            UIApplication.shared.open(url)
                        }

                    } label: {

                        HStack {
                            Image(systemName: "map.fill")

                            Text("Dove siamo")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    HStack(spacing: 35) {

                        Button {
                            if let url = URL(
                                string: "https://www.youtube.com/channel/UCqtwkH2xz1fFoTObbDXcpOw"
                            ) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("youtube")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        }

                        Button {
                            if let url = URL(
                                string: "https://www.instagram.com/chiesaevangelicadiudine/"
                            ) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        }

                        Button {
                            if let url = URL(
                                string: "https://www.facebook.com/share/1HxDBZvDhC/?mibextid=wwXIfr"
                            ) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("facebook")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding(.vertical, 10)

                    Spacer()

                    Button {
                        showAudioSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")

                            Text("Migliora la qualità della voce")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    Text("© CCE Friulana di Udine")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                }
            }
            .fullScreenCover(isPresented: $showDailyVerse) {
                DailyVerseView()
            }
            .fullScreenCover(isPresented: $showBible) {
                BibleView()
            }
            .fullScreenCover(isPresented: $showWebsite) {
                WebsiteView(
                    url: URL(
                        string: "https://www.chiesacristianaudine.it"
                    )!,
                    title: "Sito Web"
                )
            }
            .fullScreenCover(isPresented: $showYoutube) {
                WebsiteView(
                    url: URL(
                        string: "https://www.youtube.com/channel/UCqtwkH2xz1fFoTObbDXcpOw"
                    )!,
                    title: "YouTube"
                )
            }
            .sheet(isPresented: $showAudioSettings) {
                AudioSettingsView()
            }
            .onAppear {
                checkAndRequestReviewIfNeeded()
            }
        }
    }

    private func checkAndRequestReviewIfNeeded() {
        let defaults = UserDefaults.standard
        let now = Date()

        // Record first launch date if missing
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(now, forKey: firstLaunchKey)
            return
        }

        // Avoid requesting more than once
        if defaults.bool(forKey: didRequestReviewKey) {
            return
        }

        guard let firstLaunch = defaults.object(forKey: firstLaunchKey) as? Date else { return }
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: now).day ?? 0

        if daysSinceFirstLaunch >= 5 {
            // Try to request review in the current active scene
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) {
                SKStoreReviewController.requestReview(in: scene)
                defaults.set(true, forKey: didRequestReviewKey)
            }
        }
    }
}
// MARK: - 3:4 Branded Components

struct BrandedVerseShareCard: View {
    let reference: String
    let verse: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background card with subtle shadow
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)

            // Verse content
            VStack(alignment: .leading, spacing: 16) {
                Text(reference)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.black)

                Text(verse)
                    .font(.system(size: 44, weight: .regular))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
            }
            .padding(80)

            // Brand logo (semplificato per rendering affidabile)
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .padding(28)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 2)
        )
        .aspectRatio(3/4, contentMode: .fit)
    }
}

struct BrandedCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 36)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(10)
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
    }
}

struct BrandedImage: View {
    let name: String
    let cornerRadius: CGFloat

    init(_ name: String, cornerRadius: CGFloat = 16) {
        self.name = name
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        BrandedCard(cornerRadius: cornerRadius) {
            Image(name)
                .resizable()
                .scaledToFill()
                .background(Color.black.opacity(0.02))
        }
    }
}

/*
USO ESEMPIO:

// 1) Immagine brandizzata 3:4
BrandedImage("nomeImmagine")
    .frame(maxWidth: 300) // opzionale

// 2) Contenuto personalizzato 3:4 con overlay del logo
BrandedCard {
    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                Text("Titolo")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Text("Sottotitolo o versetto")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        )
}
.frame(maxWidth: 320) // opzionale

// Inseriscilo dove vuoi (ad es. in DailyVerseView, nella condivisione social o nelle schermate con immagini)
*/


