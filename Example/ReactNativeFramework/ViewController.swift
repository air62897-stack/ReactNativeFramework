import UIKit
import ReactNativeFramework

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "RN Framework Demo"
        view.backgroundColor = .white

        RNEmbedder.shared.viewProvider = RNBridgeManager.shared

        let h = makeBtn("HomeScreen", #selector(showHome))
        let p = makeBtn("ProfileScreen", #selector(showProfile))
        let s = UIStackView(arrangedSubviews: [h, p]); s.axis = .vertical; s.spacing = 20; s.alignment = .center; s.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(s)
        NSLayoutConstraint.activate([s.centerXAnchor.constraint(equalTo: view.centerXAnchor), s.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    private func makeBtn(_ t: String, _ a: Selector) -> UIButton {
        let b = UIButton(type: .system); b.setTitle(t, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium); b.addTarget(self, action: a, for: .touchUpInside); return b
    }
    @objc private func showHome() { RNEmbedder.shared.show(in: self, screenName: "HomeScreen") }
    @objc private func showProfile() { RNEmbedder.shared.show(in: self, screenName: "ProfileScreen") }
}
