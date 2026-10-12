import Foundation

/// Extracts titles, links and snippets from the provider's results markup.
enum DuckDuckGoResultParser {
    static func parse(_ html: String) -> [SearchResult] {
        let titleLink = #/<a\b([^>]*\bclass="result__a"[^>]*)>(.*?)</a>/#.dotMatchesNewlines()
        let snippetLink = #/<a\b[^>]*\bclass="result__snippet"[^>]*>(.*?)</a>/#.dotMatchesNewlines()

        let titles = html.matches(of: titleLink)
        var results: [SearchResult] = []

        for (index, match) in titles.enumerated() {
            guard let href = match.output.1.firstMatch(of: #/\bhref="([^"]*)"/#)?.output.1,
                  let url = destination(from: HTMLText.decodeEntities(String(href)))
            else { continue }

            // The snippet, when present, sits between this title and the next one.
            let sectionEnd = index + 1 < titles.count ? titles[index + 1].range.lowerBound : html.endIndex
            let section = html[match.range.upperBound..<sectionEnd]
            let snippet = section.firstMatch(of: snippetLink).map { HTMLText.plain(String($0.output.1)) } ?? ""

            let title = HTMLText.plain(String(match.output.2))
            guard !title.isEmpty else { continue }
            results.append(SearchResult(title: title, url: url, snippet: snippet))
        }
        return results
    }

    /// Resolves the provider's redirect links to the real destination and
    /// drops anything that is not a plain web page (sponsored links included).
    private static func destination(from href: String) -> URL? {
        let absolute = href.hasPrefix("//") ? "https:" + href : href
        guard var url = URL(string: absolute) else { return nil }

        if url.host?.hasSuffix("duckduckgo.com") == true {
            guard url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == "l",
                  let target = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "uddg" })?.value,
                  let targetURL = URL(string: target)
            else { return nil }
            url = targetURL
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host?.isEmpty == false
        else { return nil }
        return url
    }
}

/// Conversions between HTML and plain text.
enum HTMLText {
    /// Removes tags, decodes entities and collapses whitespace.
    static func plain(_ html: String) -> String {
        let withoutTags = html.replacing(#/<[^>]*>/#, with: "")
        return decodeEntities(withoutTags)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        return text.replacing(#/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/#) { match -> String in
            let name = String(match.output.1)
            if name.hasPrefix("#x") || name.hasPrefix("#X") {
                return scalar(UInt32(name.dropFirst(2), radix: 16)) ?? String(match.output.0)
            }
            if name.hasPrefix("#") {
                return scalar(UInt32(name.dropFirst())) ?? String(match.output.0)
            }
            return namedEntities[name] ?? String(match.output.0)
        }
    }

    /// Makes text safe to place inside HTML content or a quoted attribute.
    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func scalar(_ code: UInt32?) -> String? {
        code.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "ntilde": "ñ", "Ntilde": "Ñ", "aacute": "á", "eacute": "é", "iacute": "í",
        "oacute": "ó", "uacute": "ú", "uuml": "ü", "iquest": "¿", "iexcl": "¡",
        "laquo": "«", "raquo": "»", "hellip": "…", "mdash": "—", "ndash": "–",
    ]
}
