import SwiftUI

/// The engine a browser row's Tab search hands its query to. docs/features/launcher.md
struct WebSearchSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        return Section {
            Toggle("Search the web from an app row", isOn: $settings.webSearchEnabled)
            Group {
                Picker("Search with", selection: $settings.webSearchEngine) {
                    ForEach(WebSearchEngine.allCases) { engine in
                        Text(engine.title).tag(engine)
                    }
                }
                if settings.webSearchEngine == .custom {
                    TextField(
                        "Template", text: $settings.webSearchCustomTemplate,
                        prompt: Text("https://example.com/search?q=\(WebSearchQuery.placeholder)"))
                    if !WebSearchQuery.isUsable(template: settings.webSearchCustomTemplate) {
                        Label(
                            "The template needs a \(WebSearchQuery.placeholder) for the typed text"
                                + " to land in.", systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }
            }
            .settingsEnabled(settings.webSearchEnabled)
        } header: {
            Text("Web Search")
        } footer: {
            Text(
                "Type an app name, press Tab, then type your search — it opens in that browser."
                    + " A full http:// or https:// link opens as typed instead of being searched for."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
