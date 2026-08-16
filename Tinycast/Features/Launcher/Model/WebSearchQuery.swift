import Foundation

/// Turns typed text into the URL a browser is handed. Pure, so `web-search-test` drives the shipped
/// rules rather than a copy of them.
enum WebSearchQuery {
    static let placeholder = "{query}"

    /// Only an explicit `http(s)://` is a destination: a bare `node.js` is likelier a search
    /// than a host, and guessing wrong lands on a domain that doesn't resolve.
    static func url(for typed: String, template: String) -> URL? {
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let direct = directURL(trimmed) { return direct }
        guard template.contains(placeholder) else { return nil }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: unreserved) ?? trimmed
        let expanded = URL(string: template.replacingOccurrences(of: placeholder, with: encoded))
        return expanded.flatMap(webURL)
    }

    /// Whether a custom template can be searched with; the pane says so before it is ever used.
    static func isUsable(template: String) -> Bool {
        guard template.contains(placeholder) else { return false }
        return url(for: "tinycast", template: template) != nil
    }

    /// A link that doesn't parse falls through to being searched for, rather than failing to open.
    private static func directURL(_ trimmed: String) -> URL? {
        let lowered = trimmed.lowercased()
        guard lowered.hasPrefix("http://") || lowered.hasPrefix("https://") else { return nil }
        guard !trimmed.contains(" ") else { return nil }
        return URL(string: trimmed).flatMap(webURL)
    }

    private static func webURL(_ url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        return url.host?.isEmpty == false ? url : nil
    }

    /// RFC 3986 unreserved only: a `&`, `+` or `/` in the query can never restructure the URL.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
