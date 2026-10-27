import SwiftUI
import WebKit
import UniformTypeIdentifiers

class LocalWasmSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" {
            path = "/index.html"
        }
        
        guard let wwwURL = Bundle.main.resourceURL?.appendingPathComponent("www") else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        
        let fileURL = wwwURL.appendingPathComponent(String(path.dropFirst()))
        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        
        let ext = fileURL.pathExtension.lowercased()
        let mimeType: String
        switch ext {
        case "html": mimeType = "text/html"
        case "js":   mimeType = "application/javascript"
        case "wasm": mimeType = "application/wasm"
        case "css":  mimeType = "text/css"
        case "svg":  mimeType = "image/svg+xml"
        case "png":  mimeType = "image/png"
        case "ttf", "otf": mimeType = "font/ttf"
        default:     mimeType = "application/octet-stream"
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mimeType,
                "Access-Control-Allow-Origin": "*",
                "Cross-Origin-Opener-Policy": "same-origin",
                "Cross-Origin-Embedder-Policy": "require-corp"
            ]
        )!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

struct WebViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalWasmSchemeHandler(), forURLScheme: "wordcraft")
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        if let url = URL(string: "wordcraft://app/index.html") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@main
struct WordCraftApp: App {
    var body: some Scene {
        WindowGroup {
            WebViewContainer()
                .ignoresSafeArea(.all, edges: .all)
                .statusBar(hidden: true)
        }
    }
}