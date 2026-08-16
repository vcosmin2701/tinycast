import Foundation

/// The engine a launcher web search hands its query to. Raw values persist, so they never change.
enum WebSearchEngine: String, CaseIterable, Identifiable, Sendable {
    case google
    case duckDuckGo = "duckduckgo"
    case bing
    case brave
    case ecosia
    case startpage
    case kagi
    case perplexity
    case yandex
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .google: return "Google"
        case .duckDuckGo: return "DuckDuckGo"
        case .bing: return "Bing"
        case .brave: return "Brave Search"
        case .ecosia: return "Ecosia"
        case .startpage: return "Startpage"
        case .kagi: return "Kagi"
        case .perplexity: return "Perplexity"
        case .yandex: return "Yandex"
        case .custom: return "Custom…"
        }
    }

    /// Nil for `.custom`, whose template is the user's own and lives in settings.
    var template: String? {
        switch self {
        case .google: return "https://www.google.com/search?q={query}"
        case .duckDuckGo: return "https://duckduckgo.com/?q={query}"
        case .bing: return "https://www.bing.com/search?q={query}"
        case .brave: return "https://search.brave.com/search?q={query}"
        case .ecosia: return "https://www.ecosia.org/search?q={query}"
        case .startpage: return "https://www.startpage.com/sp/search?query={query}"
        case .kagi: return "https://kagi.com/search?q={query}"
        case .perplexity: return "https://www.perplexity.ai/search?q={query}"
        case .yandex: return "https://yandex.com/search/?text={query}"
        case .custom: return nil
        }
    }
}
