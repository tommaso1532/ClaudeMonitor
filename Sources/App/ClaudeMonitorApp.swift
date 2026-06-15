import SwiftUI

@main
struct ClaudeMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var model = AppModel.shared

    var body: some Scene {
        Window("ClaudeMonitor", id: "main") {
            ContentView().environmentObject(model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra(isInserted: Binding(get: { model.showMenuBar }, set: { _ in })) {
            MenuBarContent().environmentObject(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
