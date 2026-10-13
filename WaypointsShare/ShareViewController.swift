import UIKit
import Social
import UniformTypeIdentifiers

@objc(ShareViewController)
public class ShareViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        
        showProgressIndicator()
        processSharedItems()
    }

    private func showProgressIndicator() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 0.141, green: 0.294, blue: 0.231, alpha: 0.95)
        container.layer.cornerRadius = 14
        view.addSubview(container)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Saving to Waypoints…"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        container.addSubview(label)
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.startAnimating()
        container.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            
            spinner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            label.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    private func processSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments, !attachments.isEmpty else {
            completeExtension()
            return
        }

        let group = DispatchGroup()
        var extractedURL: String?
        var extractedText: String?
        var extractedImageName: String?

        for provider in attachments {
            // 1. URL
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        extractedURL = url.absoluteString
                    }
                    group.leave()
                }
            }
            // 2. Plain Text
            else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    if let text = item as? String {
                        extractedText = text
                    }
                    group.leave()
                }
            }
            // 3. Image
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                    let fileName = "share_\(UUID().uuidString).png"
                    if let url = item as? URL, let data = try? Data(contentsOf: url) {
                        if ShareExtensionQueue.saveSharedImage(data, fileName: fileName) {
                            extractedImageName = fileName
                        }
                    } else if let image = item as? UIImage, let data = image.pngData() {
                        if ShareExtensionQueue.saveSharedImage(data, fileName: fileName) {
                            extractedImageName = fileName
                        }
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            if extractedURL != nil || extractedText != nil || extractedImageName != nil {
                let sharedItem = ExtensionSharedItem(
                    urlString: extractedURL,
                    text: extractedText,
                    imageFileName: extractedImageName
                )
                ShareExtensionQueue.enqueue(sharedItem)
            }
            self?.completeExtension()
        }
    }

    private func completeExtension() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
