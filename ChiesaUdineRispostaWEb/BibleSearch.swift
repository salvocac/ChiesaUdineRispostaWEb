import Foundation
import Combine

struct BibleReference: Equatable {
    let book: String
    let chapter: Int?
    let verse: Int?
    
    var description: String {
        var desc = book
        if let chapter = chapter {
            desc += " \(chapter)"
            if let verse = verse {
                desc += ":\(verse)"
            }
        }
        return desc
    }
}

struct BibleReferenceParser {
    static func parse(_ input: String) -> BibleReference? {
        // Normalize input
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // Lowercased for matching
        let lower = text.lowercased()

        // Abbreviations map (Italian common abbreviations)
        let abbr: [String: String] = [
            // Pentateuco
            "gen": "Genesi", "eso": "Esodo", "lev": "Levitico", "num": "Numeri", "deu": "Deuteronomio",
            // Storici
            "gios": "Giosuè", "giu": "Giudici", "rut": "Rut", "1sam": "1 Samuele", "2sam": "2 Samuele",
            "1re": "1 Re", "2re": "2 Re", "1cr": "1 Cronache", "2cr": "2 Cronache", "esd": "Esdra",
            "neh": "Neemia", "est": "Ester",
            // Sapienziali/poetici
            "giob": "Giobbe", "sal": "Salmi", "prov": "Proverbi", "ec": "Ecclesiaste", "cant": "Cantico dei Cantici",
            // Profeti maggiori/minori
            "isa": "Isaia", "ger": "Geremia", "lam": "Lamentazioni", "eze": "Ezechiele", "dan": "Daniele",
            "os": "Osea", "gioe": "Gioele", "amo": "Amos", "oba": "Abdia", "gio": "Giona", "mic": "Michea",
            "nah": "Naum", "ab": "Abacuc", "sof": "Sofonia", "ag": "Aggeo", "zac": "Zaccaria", "mal": "Malachia",
            // Vangeli e Atti
            "mat": "Matteo", "mar": "Marco", "luc": "Luca", "giov": "Giovanni", "att": "Atti",
            // Lettere paoline
            "rom": "Romani", "1cor": "1 Corinzi", "2cor": "2 Corinzi", "gal": "Galati", "ef": "Efesini",
            "fil": "Filippesi", "col": "Colossesi", "1tess": "1 Tessalonicesi", "2tess": "2 Tessalonicesi",
            "1tim": "1 Timoteo", "2tim": "2 Timoteo", "tit": "Tito", "file": "Filemone",
            // Ebrei e cattoliche
            "ebr": "Ebrei", "giac": "Giacomo", "1pie": "1 Pietro", "2pie": "2 Pietro",
            "1gio": "1 Giovanni", "2gio": "2 Giovanni", "3gio": "3 Giovanni", "giuda": "Giuda",
            // Apocalisse
            "ap": "Apocalisse"
        ]

        // Tokenize: split on spaces and punctuation around chapter/verse
        // Accept formats like: "sal 23:1", "giov 3 16", "genesi 1", "giovanni 3:16"
        // Strategy: first token(s) are book; numbers after are chapter/verse

        // Replace multiple spaces
        let collapsed = lower.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Extract potential chapter/verse part
        // Regex: ^\s*([\p{L} .0-9]+?)\s*(\d+)?(?:[: ](\d+))?\s*$
        let pattern = "^\\s*([\\p{L} .0-9]+?)\\s*(\\d+)?(?:[: ](\\d+))?\\s*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: (collapsed as NSString).length)
        guard let match = regex.firstMatch(in: collapsed, options: [], range: range) else { return nil }

        func group(_ i: Int) -> String? {
            let r = match.range(at: i)
            if r.location != NSNotFound, let sr = Range(r, in: collapsed) {
                return String(collapsed[sr])
            }
            return nil
        }

        var rawBook = (group(1) ?? "").trimmingCharacters(in: .whitespaces)
        let chapterStr = group(2)
        let verseStr = group(3)

        if rawBook.isEmpty { return nil }

        // If book starts with a known abbreviation, expand it
        // Handle numeric prefixes like "1cor", "2sam" already covered in map keys
        var normalizedBook = rawBook
        // Try exact abbr match first
        if let mapped = abbr[normalizedBook.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "")] {
            normalizedBook = mapped
        } else {
            // Try first word as abbr (e.g., "giov" from "giov ann i" typo)
            if let first = normalizedBook.split(separator: " ").first {
                let key = first.replacingOccurrences(of: ".", with: "").lowercased()
                if let mapped = abbr[key] {
                    normalizedBook = mapped
                }
            }
        }

        // Capitalize book name for display if not mapped
        if abbr.values.contains(normalizedBook) == false {
            normalizedBook = normalizedBook.prefix(1).uppercased() + normalizedBook.dropFirst()
        }

        let chapter = chapterStr.flatMap { Int($0) }
        let verse = verseStr.flatMap { Int($0) }

        return BibleReference(book: normalizedBook, chapter: chapter, verse: verse)
    }
}

final class BibleSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var parsed: BibleReference? = nil
    
    func updateQuery(_ new: String) {
        query = new
        parsed = BibleReferenceParser.parse(new)
    }
    
    func search(completion: @escaping (BibleReference?) -> Void) {
        // Placeholder for future content lookup logic
        completion(parsed)
    }
}
