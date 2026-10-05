import UIKit
import WebKit

// The display itself lives on Netlify; this app only shows it full screen.
// `?app` tells the page it is running inside the wrapper.
let siteURL = URL(string: "https://retro-spectrum.netlify.app/?app")!

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.isIdleTimerDisabled = true          // it's a display: never let the screen sleep
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = DisplayViewController()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = true
    }
}

final class DisplayViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private var webView: WKWebView!

    // No status bar, no home indicator, and edge swipes need a second swipe so they aren't triggered by accident.
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: siteURL))
    }

    // The page asks for audio input (the line in). Grant it for our own site only; iOS still shows
    // its own one-time microphone permission prompt for the app.
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(origin.host == siteURL.host ? .grant : .deny)
    }

    // No network yet (e.g. right after power-on): keep retrying rather than showing a blank screen.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.webView.load(URLRequest(url: siteURL))
        }
    }

    // If iOS kills the web content process in the background, reload instead of staying blank.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.load(URLRequest(url: siteURL))
    }
}
