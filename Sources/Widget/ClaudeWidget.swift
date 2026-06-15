import WidgetKit
import SwiftUI

struct ClaudeWidget: Widget {
    let kind = "ClaudeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClaudeWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("ClaudeMonitor")
        .description("Active Claude accounts and their 5h / 7d usage.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
