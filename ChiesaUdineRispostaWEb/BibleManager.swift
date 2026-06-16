import Foundation

final class BibleManager {

    static let shared = BibleManager()

    private(set) var verses: [BibleVerse] = []

    init() {

        print("🔥 BibleManager inizializzato")

        loadBible()
    }

    private func loadBible() {

        guard let url = Bundle.main.url(
            forResource: "riveduta",
            withExtension: "json"
        ) else {

            print("❌ diodati.json NON trovato")
            return
        }

        print("✅ diodati.json trovato")

        do {

            let data = try Data(contentsOf: url)

            let bible = try JSONDecoder()
                .decode(BibleData.self, from: data)

            verses = bible.verses

            print("✅ Versetti caricati: \(verses.count)")

        } catch {

            print("❌ Errore JSON:")
            print(error)
        }
    }

    func verseOfToday() -> BibleVerse? {

        guard !verses.isEmpty else {

            print("❌ Nessun versetto caricato")
            return nil
        }

        let dayOfYear =
            Calendar.current.ordinality(
                of: .day,
                in: .year,
                for: Date()
            ) ?? 1

        let index = (dayOfYear * 37) % verses.count

        return verses[index]
    }
}
