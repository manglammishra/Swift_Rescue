//
// SwiftRescueWebView.swift
// SwiftRescue
//
// Native WebKit container embedding the SwiftRescue React/Vite Tactical Frontend
//

import SwiftUI
import WebKit

#if os(macOS)
import AppKit

struct SwiftRescueWebView: NSViewRepresentable {
    let activeRoute: String
    var onSOSBroadcast: (() -> Void)? = nil
    var onHazardReport: (() -> Void)? = nil

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "swiftRescue")
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        loadContent(in: webView, route: activeRoute)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.currentRoute != activeRoute {
            context.coordinator.currentRoute = activeRoute
            loadContent(in: nsView, route: activeRoute)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func loadContent(in webView: WKWebView, route: String) {
        // Try live dev server first (if running on 5173)
        let localhostURLString = "http://localhost:5173" + (route.hasPrefix("/") ? route : "/" + route)
        if let liveURL = URL(string: localhostURLString) {
            let request = URLRequest(url: liveURL, timeoutInterval: 1.5)
            webView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: SwiftRescueWebView
        weak var webView: WKWebView?
        var currentRoute: String = ""

        init(_ parent: SwiftRescueWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let body = message.body as? String {
                if body.contains("SOS") {
                    parent.onSOSBroadcast?()
                } else if body.contains("HAZARD") {
                    parent.onHazardReport?()
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Localhost not responding; seamlessly fallback to local offline bundle
            loadOfflineBundle(in: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loadOfflineBundle(in: webView)
        }

        private func loadOfflineBundle(in webView: WKWebView) {
            let fileManager = FileManager.default

            // Check bundle resources
            if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("web/index.html"),
               fileManager.fileExists(atPath: resourceURL.path) {
                webView.loadFileURL(resourceURL, allowingReadAccessTo: resourceURL.deletingLastPathComponent())
                return
            }

            // Fallback to repository web_dist path
            let localDevPath = "/Users/manglammishra/Documents/Swift_Resucue1/bitchat/web_dist/index.html"
            if fileManager.fileExists(atPath: localDevPath) {
                let localURL = URL(fileURLWithPath: localDevPath)
                webView.loadFileURL(localURL, allowingReadAccessTo: localURL.deletingLastPathComponent())
            }
        }
    }
}
#else
// Stub for iOS builds if needed
struct SwiftRescueWebView: View {
    let activeRoute: String
    var onSOSBroadcast: (() -> Void)? = nil
    var onHazardReport: (() -> Void)? = nil

    var body: some View {
        Text("Tactical Web HUD (macOS only)")
    }
}
#endif
