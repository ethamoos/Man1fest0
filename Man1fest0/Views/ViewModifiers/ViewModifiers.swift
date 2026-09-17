//
//  ViewModifiers.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/08/2024.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Styles supported by the SectionHeading modifier.
enum SectionHeadingStyle {
    case standard      // simple bold text with padding
    case divider       // thin divider above the heading
    case accentBar     // narrow accent bar at the leading edge
    case boxed         // rounded rectangle background (subtle card)
    case pill          // capsule/pill label
    case band          // full-width colored band
}

/// Preset shorthand names for common section heading combinations.
/// Use these with `Text("Title").sectionHeading(preset: .standard)`
enum SectionHeadingPreset {
    case standard    // default lightweight heading
    case bold        // high-contrast band-style heading (strong)
    case minimal     // compact heading with divider
    case accent      // accent bar to the left
    case boxedCard   // boxed rounded card style
    case pillBlue    // pill with blue tint
    case bandStrong  // full-width accent band
}

/// A consistent heading style used across the app for section headings.
/// Use `Text("Title").sectionHeading()` or pass `style:` to choose a variant.
struct SectionHeading: ViewModifier {
    var style: SectionHeadingStyle = .standard
    var size: CGFloat = 14
    var weight: Font.Weight = .bold
    var color: Color = .primary
    var paddingEdges: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    var background: Color? = nil
    var accentColor: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .standard:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(color)
                .padding(paddingEdges)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background)
                .accessibilityAddTraits(.isHeader)

        case .divider:
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
            }
            .padding(paddingEdges)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .accessibilityAddTraits(.isHeader)

        case .accentBar:
            HStack(spacing: 8) {
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(accentColor ?? Color.accentColor)
                    .cornerRadius(2)
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(paddingEdges)
            .background(background)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)

        case .boxed:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(color)
                .padding(paddingEdges)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(background ?? Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06))
                )
                .accessibilityAddTraits(.isHeader)

        case .pill:
            HStack(spacing: 8) {
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill((background ?? Color.accentColor.opacity(0.12))))
            .accessibilityAddTraits(.isHeader)

        case .band:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(paddingEdges)
                .background(background ?? Color.accentColor)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

extension View {
    /// Apply the standard app section heading styling with an optional style variant.
    /// - Parameters: style: one of SectionHeadingStyle. Defaults to `.standard`.
    func sectionHeading(
        style: SectionHeadingStyle = .standard,
        size: CGFloat = 14,
        weight: Font.Weight = .bold,
        color: Color = .primary,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        background: Color? = nil,
        accentColor: Color? = nil
    ) -> some View {
        self.modifier(SectionHeading(style: style, size: size, weight: weight, color: color, paddingEdges: padding, background: background, accentColor: accentColor))
    }

    /// Convenience shorthand that maps `SectionHeadingPreset` names to specific combinations
    /// of `SectionHeadingStyle` and parameters. Returns an `AnyView` wrapper so the API is
    /// simple to call from any place in the views.
    func sectionHeading(preset: SectionHeadingPreset) -> some View {
        switch preset {
        case .standard:
            return AnyView(self.sectionHeading(style: .standard))
        case .bold:
            // Strong band with accent color for high-visibility headers
            return AnyView(self.sectionHeading(style: .band, size: 16, weight: .semibold, color: .white, background: Color.accentColor))
        case .minimal:
            // Compact divider-based heading
            return AnyView(self.sectionHeading(style: .divider, size: 13, weight: .semibold, color: .primary))
        case .accent:
            // Small leading accent bar
            return AnyView(self.sectionHeading(style: .accentBar, size: 14, weight: .semibold, color: .primary, background: nil, accentColor: Color.accentColor))
        case .boxedCard:
            // Subtle rounded rectangle card
            #if os(iOS)
            let bg = Color(.secondarySystemBackground)
            #elseif os(macOS)
            let bg = Color(NSColor.windowBackgroundColor)
            #else
            let bg = Color.gray.opacity(0.08)
            #endif
            return AnyView(self.sectionHeading(style: .boxed, size: 14, weight: .semibold, color: .primary, background: bg))
        case .pillBlue:
            return AnyView(self.sectionHeading(style: .pill, size: 13, weight: .semibold, color: .primary, background: Color.blue.opacity(0.12)))
        case .bandStrong:
            return AnyView(self.sectionHeading(style: .band, size: 15, weight: .semibold, color: .white, background: Color.blue))
        }
    }
}

/// Reusable text field with consistent outline styling.
/// Use `OutlinedTextField("placeholder", text: $binding)` to create a text field with a blue border.
struct OutlinedTextField: View {
    private let title: String
    @Binding private var text: String
    private let cornerRadius: CGFloat
    private let lineWidth: CGFloat
    private let strokeColor: Color

    init(
        _ title: String,
        text: Binding<String>,
        cornerRadius: CGFloat = 8,
        lineWidth: CGFloat = 2,
        strokeColor: Color = .blue
    ) {
        self.title = title
        self._text = text
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.strokeColor = strokeColor
    }

    var body: some View {
        TextField(title, text: $text)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
    }
}

// MARK: - Script-safe text handling
//
// macOS/iOS text controls silently apply "smart" punctuation substitution
// (curly quotes, em/en dashes, ellipsis characters, non-breaking spaces).
// These are invisible in the UI but break shell/script syntax when the text
// is saved to Jamf and executed on a device. `ScriptTextSanitizer` normalizes
// known smart-punctuation to their plain ASCII equivalents and (optionally)
// strips any other non-ASCII characters, and `PlainTextEditor` is a drop-in
// replacement for SwiftUI's `TextEditor` that disables smart substitution at
// the source (NSTextView/UITextView) and sanitizes on every change as a
// backstop (e.g. for pasted content).

/// Utilities for keeping script/command text restricted to ASCII-safe characters.
enum ScriptTextSanitizer {

    /// Maps common "smart" punctuation (curly quotes, dashes, ellipsis, NBSP)
    /// to their plain ASCII equivalents.
    static let smartPunctuationMap: [Character: String] = [
        "\u{201C}": "\"", "\u{201D}": "\"", "\u{201E}": "\"", "\u{201F}": "\"", // “ ” „ ‟
        "\u{2018}": "'",  "\u{2019}": "'",  "\u{201A}": "'",  "\u{201B}": "'",  // ‘ ’ ‚ ‛
        "\u{2013}": "-",  "\u{2014}": "-",  "\u{2212}": "-",                    // – — −
        "\u{2026}": "...",                                                     // …
        "\u{00A0}": " "                                                        // non-breaking space
    ]

    /// Normalizes smart punctuation to ASCII equivalents and, by default,
    /// strips any remaining non-ASCII characters so the result is guaranteed
    /// safe to embed in a shell script or Jamf XML payload.
    /// - Parameters:
    ///   - input: the raw text (e.g. from a text editor or paste operation).
    ///   - stripNonASCII: when true (default), removes any character that
    ///     survives punctuation normalization but is still outside ASCII.
    static func sanitize(_ input: String, stripNonASCII: Bool = true) -> String {
        guard !input.isEmpty else { return input }
        var result = String()
        result.reserveCapacity(input.count)
        for character in input {
            if let replacement = smartPunctuationMap[character] {
                result.append(replacement)
            } else {
                result.append(character)
            }
        }
        if stripNonASCII {
            result = String(result.unicodeScalars.filter { $0.isASCII })
        }
        return result
    }

    /// Returns true if the string contains any character outside standard ASCII.
    static func containsNonASCII(_ input: String) -> Bool {
        input.unicodeScalars.contains { !$0.isASCII }
    }
}

#if os(macOS)
/// A `TextEditor` replacement for editing script/command content.
/// Disables macOS's automatic quote/dash/text substitution and spelling
/// correction at the `NSTextView` level, and normalizes any text that still
/// slips through (e.g. via paste) to plain ASCII using `ScriptTextSanitizer`.
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    var sanitizeOnChange: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = font
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = [.width]
        textView.string = ScriptTextSanitizer.sanitize(text, stripNonASCII: false)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        // Re-assert these on every update in case system defaults changed them.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isEditable = isEnabled
        textView.isSelectable = true
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        init(_ parent: PlainTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard parent.sanitizeOnChange else {
                parent.text = textView.string
                return
            }
            let sanitized = ScriptTextSanitizer.sanitize(textView.string)
            if sanitized != textView.string {
                let selectedRanges = textView.selectedRanges
                textView.string = sanitized
                textView.selectedRanges = selectedRanges
            }
            parent.text = sanitized
        }
    }
}
#else
/// A `TextEditor` replacement for editing script/command content.
/// Disables iOS's automatic quote/dash/text substitution and autocorrection
/// at the `UITextView` level, and normalizes any text that still slips
/// through (e.g. via paste) to plain ASCII using `ScriptTextSanitizer`.
struct PlainTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    var sanitizeOnChange: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.text = ScriptTextSanitizer.sanitize(text, stripNonASCII: false)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.isEditable = isEnabled
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PlainTextEditor
        init(_ parent: PlainTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            guard parent.sanitizeOnChange else {
                parent.text = textView.text
                return
            }
            let sanitized = ScriptTextSanitizer.sanitize(textView.text)
            if sanitized != textView.text {
                let selectedRange = textView.selectedRange
                textView.text = sanitized
                textView.selectedRange = selectedRange
            }
            parent.text = sanitized
        }
    }
}
#endif
