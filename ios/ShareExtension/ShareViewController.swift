import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let appGroupId = "group.com.zoop.linkmanager"
    private let sharedKey = "ShareKey"

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedContent()
    }

    private func handleSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // URL 처리
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                        if let url = data as? URL {
                            self?.saveAndOpenApp(url.absoluteString)
                        }
                    }
                    return
                }

                // 텍스트 처리 (URL이 텍스트로 공유될 경우)
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (data, error) in
                        if let text = data as? String {
                            self?.saveAndOpenApp(text)
                        }
                    }
                    return
                }
            }
        }

        completeRequest()
    }

    private func saveAndOpenApp(_ content: String) {
        // UserDefaults에 공유 내용 저장 (App Group 사용)
        if let userDefaults = UserDefaults(suiteName: appGroupId) {
            userDefaults.set(content, forKey: sharedKey)
            userDefaults.synchronize()
        }

        // 메인 앱 열기
        let urlString = "zoop://share?url=\(content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            openURL(url)
        }

        completeRequest()
    }

    @objc private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }

        // Fallback for iOS 13+
        let selector = sel_registerName("openURL:")
        var responderChain: UIResponder? = self
        while responderChain != nil {
            if responderChain!.responds(to: selector) {
                responderChain!.perform(selector, with: url)
                return
            }
            responderChain = responderChain?.next
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
