import Foundation

@main
struct WebSearchTest {
    static func main() {
        var failures = 0

        func check(_ description: String, _ condition: @autoclosure () -> Bool) {
            if condition() {
                print("PASS  \(description)")
            } else {
                print("FAIL  \(description)")
                failures += 1
            }
        }

        func url(
            _ typed: String, _ template: String = "https://www.google.com/search?q={query}"
        ) -> String? {
            WebSearchQuery.url(for: typed, template: template)?.absoluteString
        }

        // Every shipped engine builds a URL, and none of them lost its placeholder.
        for engine in WebSearchEngine.allCases where engine != .custom {
            let template = engine.template ?? ""
            check("\(engine.rawValue) keeps {query}", template.contains(WebSearchQuery.placeholder))
            check(
                "\(engine.rawValue) builds a URL",
                WebSearchQuery.url(for: "swift", template: template) != nil)
        }
        check("custom has no built-in template", WebSearchEngine.custom.template == nil)
        check(
            "engine raw values are unique",
            Set(WebSearchEngine.allCases.map(\.rawValue)).count == WebSearchEngine.allCases.count)

        check("a plain word searches", url("swift") == "https://www.google.com/search?q=swift")
        check(
            "a space encodes", url("hello world") == "https://www.google.com/search?q=hello%20world")

        // The reason encoding is unreserved-only: none of these may restructure the URL.
        check("separators encode", url("a&b=c") == "https://www.google.com/search?q=a%26b%3Dc")
        check("a plus can't read as a space", url("a+b") == "https://www.google.com/search?q=a%2Bb")
        check(
            "path and fragment encode",
            url("a/b?c#d") == "https://www.google.com/search?q=a%2Fb%3Fc%23d")
        check(
            "utf-8 encodes",
            url("naïve café") == "https://www.google.com/search?q=na%C3%AFve%20caf%C3%A9")
        check(
            "unreserved characters stay literal",
            url("-._~") == "https://www.google.com/search?q=-._~")

        check("the query is trimmed", url("  swift  ") == "https://www.google.com/search?q=swift")
        check("an empty query has nothing to search for", url("") == nil)
        check("whitespace alone has nothing to search for", url("   ") == nil)

        // An explicit scheme is a destination; anything else is a search, however host-like it looks.
        check(
            "an https link opens as typed",
            url("https://github.com/a?b=c") == "https://github.com/a?b=c")
        check("an http link opens as typed", url("http://example.com") == "http://example.com")
        // Why plain http is neither refused nor upgraded: a dev host is a real thing to type.
        check(
            "a localhost port opens as typed",
            url("http://localhost:3000/x") == "http://localhost:3000/x")
        check("the scheme match is case-blind", url("HTTPS://Example.com") == "HTTPS://Example.com")
        check(
            "a bare dotted word searches",
            url("node.js") == "https://www.google.com/search?q=node.js")
        check(
            "a bare host searches", url("github.com") == "https://www.google.com/search?q=github.com"
        )
        check(
            "a spaced pseudo-link is a search, not a broken URL",
            url("https://a b.com") == "https://www.google.com/search?q=https%3A%2F%2Fa%20b.com")
        check(
            "a hostless scheme is a search, not a broken URL",
            url("https://") == "https://www.google.com/search?q=https%3A%2F%2F")

        check("a template without {query} builds nothing", url("swift", "no placeholder") == nil)
        check(
            "extra template parameters survive",
            url("swift", "https://kagi.com/search?q={query}&l=1")
                == "https://kagi.com/search?q=swift&l=1")
        check(
            "every placeholder is replaced",
            url("a", "https://x.test/{query}/{query}") == "https://x.test/a/a")

        check(
            "a sound template is usable",
            WebSearchQuery.isUsable(template: "https://x.test/?q={query}"))
        check(
            "a placeholderless template is not",
            !WebSearchQuery.isUsable(template: "https://x.test/?q="))
        check("an empty template is not", !WebSearchQuery.isUsable(template: ""))
        check("a template with no scheme is not", !WebSearchQuery.isUsable(template: "{query}"))

        print(failures == 0 ? "\nweb-search-test passed." : "\n\(failures) check(s) failed.")
        exit(failures == 0 ? 0 : 1)
    }
}
