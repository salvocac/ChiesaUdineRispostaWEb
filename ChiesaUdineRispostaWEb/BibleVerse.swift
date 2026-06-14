import Foundation

struct BibleData: Codable {
    let verses: [BibleVerse]
}

struct BibleVerse: Codable, Identifiable {
    let book: Int
    let book_name: String
    let chapter: Int
    let verse: Int
    let text: String

    var id: String {
        "\(book_name)-\(chapter)-\(verse)"
    }
}
