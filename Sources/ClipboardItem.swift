import Foundation

enum ClipboardKind: String, Codable {
    case text
    case image
}

struct ClipboardItem: Codable, Equatable {
    let id: UUID
    let kind: ClipboardKind
    let timestamp: Date
    let text: String?       // .text: the copied string; .image: nil
    let imageFile: String?  // .image: PNG filename relative to the store's images dir

    var preview: String {
        switch kind {
        case .text:
            let t = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? "(empty)" : t
        case .image:
            return "Image"
        }
    }
}
