import Foundation

final class DailyVerseManager {

    static let shared = DailyVerseManager()

    func loadVerses() -> [DailyVerse] {

        guard let url = Bundle.main.url(
            forResource: "daily_verses",
            withExtension: "json"
        ) else {

            print("daily_verses.json non trovato")
            return []
        }

        do {

            let data = try Data(contentsOf: url)

            return try JSONDecoder()
                .decode([DailyVerse].self,
                        from: data)

        } catch {

            print(error)
            return []
        }
    }

    func verseOfToday() -> DailyVerse? {

        let verses = loadVerses()

        guard !verses.isEmpty else {
            return nil
        }

        let daysSinceEpoch = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: Date()).day ?? 0
        let index = daysSinceEpoch % verses.count

        return verses[index]
    }
}
