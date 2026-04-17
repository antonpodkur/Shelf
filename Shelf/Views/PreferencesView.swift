import ServiceManagement
import SwiftUI

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 380, height: 200)
    }

    private var generalTab: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.full")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Shelf")
                .font(.title2.bold())

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("A lightweight file shelf for macOS.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Shelf] Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
