import Foundation

final class DailyVerseManager {

    static let shared = DailyVerseManager()

    func loadVerses() -> [DailyVerse] {

        guard let url = Bundle.main.url(
            forResource: "daily_verses",
            withExtension: "json"
        ) else {

            print("❌ daily_verses.json non trovato")
            return []
        }

        do {

            let data = try Data(contentsOf: url)

            let verses = try JSONDecoder()
                .decode([DailyVerse].self,
                        from: data)

            print("✅ DailyVerses caricati: \(verses.count)")

            return verses

        } catch {

            print("❌ Errore JSON:", error)
            return []
        }
    }

    func verseOfToday() -> DailyVerse? {

        let verses = loadVerses()

        print("📖 DailyVerses count =", verses.count)

        guard !verses.isEmpty else {

            print("❌ NESSUN VERSETTO CARICATO")
            return nil
        }

        let daysSinceEpoch =
            Calendar.current.dateComponents(
                [.day],
                from: Date(timeIntervalSince1970: 0),
                to: Date()
            ).day ?? 0

        let index = daysSinceEpoch % verses.count

        print("📅 Indice del giorno =", index)
        print("📖 Versetto scelto =", verses[index].reference ?? "NIL")
        print("💬 Commento =", verses[index].reflection ?? "NIL")

        return verses[index]
    }
}
