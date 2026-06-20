import SwiftUI

// Renders Riz's reply as native interactive cards: prose (with bold/bullets), bar charts,
// progress bars, stat chips and tables. The model emits markdown + ```ryze-chart/progress/stats``` blocks.
enum RizBlock {
    case text(String)
    case chart([(String, Double)])
    case progress([(String, Double, Double)])
    case stats([(String, String)])
    case table([[String]])
}

private func rizNum(_ s: String) -> Double { Double(s.filter { $0.isNumber || $0 == "." }) ?? 0 }

private func rizParse(_ s: String) -> [RizBlock] {
    var blocks: [RizBlock] = []
    var buf: [String] = []
    func flush() { let t = buf.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines); if !t.isEmpty { blocks.append(.text(t)) }; buf = [] }
    let lines = s.components(separatedBy: "\n")
    var i = 0
    while i < lines.count {
        let raw = lines[i]
        let t = raw.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("```") {
            let kind = t.dropFirst(3).trimmingCharacters(in: .whitespaces).lowercased()
            var body: [String] = []; i += 1
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") { body.append(lines[i]); i += 1 }
            if i < lines.count { i += 1 }
            flush()
            if kind.contains("chart") { blocks.append(.chart(rizPairs(body))) }
            else if kind.contains("progress") { blocks.append(.progress(rizProgress(body))) }
            else if kind.contains("stat") { blocks.append(.stats(rizStats(body))) }
            else { buf = body; flush() }
            continue
        }
        if t.hasPrefix("|") {
            var rows: [String] = []
            while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") { rows.append(lines[i]); i += 1 }
            flush(); blocks.append(.table(rizTable(rows))); continue
        }
        buf.append(raw); i += 1
    }
    flush()
    return blocks
}
private func rizPairs(_ body: [String]) -> [(String, Double)] {
    body.compactMap { l in let p = l.split(separator: ":", maxSplits: 1); guard p.count == 2 else { return nil }; return (p[0].trimmingCharacters(in: .whitespaces), rizNum(String(p[1]))) }
}
private func rizProgress(_ body: [String]) -> [(String, Double, Double)] {
    body.compactMap { l in
        let p = l.split(separator: ":", maxSplits: 1); guard p.count == 2 else { return nil }
        let rhs = String(p[1]); let parts = rhs.split(separator: "/")
        if parts.count == 2 { return (p[0].trimmingCharacters(in: .whitespaces), rizNum(String(parts[0])), rizNum(String(parts[1]))) }
        return (p[0].trimmingCharacters(in: .whitespaces), rizNum(rhs), 100)
    }
}
private func rizStats(_ body: [String]) -> [(String, String)] {
    body.flatMap { $0.components(separatedBy: "|") }.compactMap { l in let p = l.split(separator: ":", maxSplits: 1); guard p.count == 2 else { return nil }; return (p[0].trimmingCharacters(in: .whitespaces), p[1].trimmingCharacters(in: .whitespaces)) }
}
private func rizTable(_ rows: [String]) -> [[String]] {
    var out: [[String]] = []
    for r in rows {
        var cells = r.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        if cells.first == "" { cells.removeFirst() }
        if cells.last == "" { cells.removeLast() }
        if cells.isEmpty { continue }
        if cells.allSatisfy({ c in !c.isEmpty && c.allSatisfy { $0 == "-" || $0 == ":" } }) { continue }
        out.append(cells)
    }
    return out
}

struct RizRichText: View {
    let text: String
    private let palette: [Color] = [Brand.coral, Brand.mint, Brand.violet, Brand.sky, Brand.pink, Brand.yellow]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(rizParse(text).enumerated()), id: \.offset) { _, b in block(b) }
        }
    }
    @ViewBuilder private func block(_ b: RizBlock) -> some View {
        switch b {
        case .text(let t): textBlock(t)
        case .chart(let items): chartBlock(items)
        case .progress(let items): progressBlock(items)
        case .stats(let items): statsBlock(items)
        case .table(let rows): tableBlock(rows)
        }
    }
    private func md(_ s: String) -> Text {
        if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) { return Text(a) }
        return Text(s)
    }
    @ViewBuilder private func textBlock(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(t.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                let ln = line.trimmingCharacters(in: .whitespaces)
                if ln.isEmpty { Color.clear.frame(height: 2) }
                else if ln.hasPrefix("- ") || ln.hasPrefix("* ") || ln.hasPrefix("• ") {
                    HStack(alignment: .top, spacing: 7) { Text("•").foregroundColor(Brand.yellow); md(String(ln.dropFirst(2))); Spacer(minLength: 0) }
                } else if ln.hasPrefix("#") {
                    md(ln.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)).font(.system(size: 16, weight: .bold))
                } else { md(ln) }
            }
        }
    }
    private func chartBlock(_ items: [(String, Double)]) -> some View {
        let mx = items.map { $0.1 }.max() ?? 1
        return VStack(spacing: 9) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                HStack(spacing: 10) {
                    Text(it.0).font(.system(size: 12)).foregroundColor(Brand.text).frame(width: 80, alignment: .leading).lineLimit(1).minimumScaleFactor(0.8)
                    GeometryReader { gx in ZStack(alignment: .leading) { Capsule().fill(Brand.hairline); Capsule().fill(palette[i % palette.count]).frame(width: max(8, gx.size.width * CGFloat(it.1 / mx))) } }.frame(height: 10)
                    Text(money(it.1)).font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.text).frame(width: 66, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }.padding(12).background(Brand.bg).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.hairline, lineWidth: 1))
    }
    private func progressBlock(_ items: [(String, Double, Double)]) -> some View {
        VStack(spacing: 11) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                VStack(alignment: .leading, spacing: 5) {
                    HStack { md(it.0).font(.system(size: 13, weight: .medium)).foregroundColor(Brand.text); Spacer(); Text("\(Int(it.1 / max(1, it.2) * 100))%").font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.yellow) }
                    ProgressBar(value: it.1 / max(1, it.2))
                    if it.2 != 100 { Text("\(money(it.1)) of \(money(it.2))").font(.system(size: 11)).foregroundColor(Brand.mute) }
                }
            }
        }.padding(12).background(Brand.bg).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.hairline, lineWidth: 1))
    }
    private func statsBlock(_ items: [(String, String)]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                VStack(alignment: .leading, spacing: 2) { Text(it.1).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.text).lineLimit(1).minimumScaleFactor(0.7); Text(it.0).font(.system(size: 11)).foregroundColor(Brand.mute).lineLimit(1) }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(11).background(Brand.bg).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.hairline, lineWidth: 1))
            }
        }
    }
    private func tableBlock(_ rows: [[String]]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { ri, row in
                HStack(spacing: 8) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        md(cell).font(.system(size: 12, weight: ri == 0 ? .bold : .regular)).foregroundColor(ri == 0 ? Brand.text : Brand.mute).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(.vertical, 8).padding(.horizontal, 10)
                if ri < rows.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
            }
        }.background(Brand.bg).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.hairline, lineWidth: 1))
    }
}
