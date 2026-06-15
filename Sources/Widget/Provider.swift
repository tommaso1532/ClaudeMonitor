import WidgetKit
import SwiftUI

struct ClaudeEntry: TimelineEntry {
    let date: Date
    let data: ClaudeData?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ClaudeEntry {
        ClaudeEntry(date: Date(), data: DataStore.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeEntry) -> Void) {
        completion(ClaudeEntry(date: Date(), data: DataStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeEntry>) -> Void) {
        let data = DataStore.load()
        let secs = Double(data?.settings.refreshSeconds ?? 600)
        let next = Date().addingTimeInterval(max(secs, 60))
        let entry = ClaudeEntry(date: Date(), data: data)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
