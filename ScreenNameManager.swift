import UIKit

class ScreenNameManager {

    private static let nameKey = "playerScreenName"
    private static let promptedKey = "hasPromptedForScreenName"

    static var current: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var hasBeenPrompted: Bool {
        get { UserDefaults.standard.bool(forKey: promptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: promptedKey) }
    }

    static var needsInitialPrompt: Bool { !hasBeenPrompted }

    static func promptForScreenName(from view: UIView,
                                    title: String = "Choose a Screen Name",
                                    message: String = "This name appears on the leaderboard.\nNo account needed.",
                                    completion: @escaping () -> Void) {
        guard let vc = view.findViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Your screen name"
            field.text = current
            field.autocapitalizationType = .words
            field.autocorrectionType = .no
            field.returnKeyType = .done
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let name, !name.isEmpty {
                current = name
            }
            hasBeenPrompted = true
            completion()
        })
        alert.addAction(UIAlertAction(title: "Skip", style: .cancel) { _ in
            hasBeenPrompted = true
            completion()
        })
        vc.present(alert, animated: true)
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}
