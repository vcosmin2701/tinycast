import SwiftUI

/// The chip Tab opens on a browser row, as a `PaletteHeaderAccessory` the palette renders
/// without reading. docs/features/launcher.md#search-the-web-from-an-app-row
@MainActor
enum AppSearchAccessory {
    /// The one field name, so the palette's focus state and the screen agree on what Tab lands on.
    static let field = "webSearch"

    /// The one rule both the strip and ↵ read. An empty query declines: the search field
    /// still owes its own prompt the full width.
    static func offers(entry: AppEntry, query: String, settings: AppSettings) -> Bool {
        guard settings.webSearchEnabled, entry.handlesWebLinks else { return false }
        return !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func make(
        entry: AppEntry,
        query: String,
        settings: AppSettings,
        value: Binding<String>,
        focus: FocusState<String?>.Binding,
        onSubmit: @escaping () -> Void
    ) -> PaletteHeaderAccessory? {
        guard offers(entry: entry, query: query, settings: settings) else { return nil }

        return PaletteHeaderAccessory(
            width: AppSearchField.totalWidth(for: value.wrappedValue),
            fieldNames: [field],
            // Never blocks ↵: an empty field means the row was activated to open the app itself.
            firstIncompleteField: nil,
            view: AnyView(
                AppSearchField(
                    icon: entry.iconSource, fileURL: entry.url, appName: entry.name, text: value,
                    focused: focus, onSubmit: onSubmit)),
            // Only once Tab lands here: before that the query is what the user is reading.
            hidesQuery: focus.wrappedValue == field)
    }
}

/// The browser's own icon, then what to search for in it — no field chrome, so the icon reads as a
/// token in the query line rather than as a second search box.
private struct AppSearchField: View {
    let icon: EntryIcon
    let fileURL: URL
    let appName: String
    @Binding var text: String
    @FocusState.Binding var focused: String?
    let onSubmit: () -> Void
    @Environment(PaletteState.self) private var vm

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            EntryIconView(source: icon, fileURL: fileURL)
                .frame(width: Theme.Size.headerIconSlot, height: Theme.Size.headerIconSlot)
            TextField(
                "", text: $text,
                prompt: Text(Self.prompt).foregroundStyle(Theme.Colors.textTertiary)
            )
            .textFieldStyle(.plain)
            .font(Theme.Typography.searchField)
            .tint(.white)
            .onSubmit(onSubmit)
            .frame(width: Self.fieldWidth(for: text))
            .focused($focused, equals: AppSearchAccessory.field)
            .help("Search the web in \(appName)")
        }
        // The panel needs it before the field editor eats the key, so it can't be derived later.
        .onChange(of: isEmptyAndFocused, initial: true) { vm.headerFieldIsEmpty = isEmptyAndFocused }
        .onDisappear { vm.headerFieldIsEmpty = false }
    }

    private var isEmptyAndFocused: Bool {
        text.isEmpty && focused == AppSearchAccessory.field
    }

    static let prompt = "Search the web…"

    /// Grows with the typed text like the search field, so the caret never runs off the end.
    static func fieldWidth(for text: String) -> CGFloat {
        let measured = text.isEmpty ? prompt : text
        let width = (measured as NSString)
            .size(withAttributes: [.font: Theme.Typography.searchFieldNSFont]).width
        // +3pt so the caret sits after the last glyph rather than on top of it.
        return min(max(width + 3, 40), 320)
    }

    static func totalWidth(for text: String) -> CGFloat {
        Theme.Size.headerIconSlot + Theme.Spacing.sm + fieldWidth(for: text)
    }
}
