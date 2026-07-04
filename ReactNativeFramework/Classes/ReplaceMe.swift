import UIKit

/// 宿主 App 需实现此协议，提供 RN 视图创建能力
@objc public protocol RNViewProvider: AnyObject {
    /// 初始化 React Native 运行时
    @objc func initializeReactNative(metroServerURL: String)
    /// 创建 RN 视图
    @objc func createReactView(moduleName: String, initialProperties: [String: Any]?) -> UIView?
}

@objc public class RNEmbedder: NSObject {
    @objc public static let shared = RNEmbedder()
    @objc public var metroServerURL: String = "http://127.0.0.1:8081"
    @objc public var moduleName: String = "main"
    @objc public weak var viewProvider: RNViewProvider?
    private var initialized = false

    private func ensureInit() {
        guard !initialized else { return }
        initialized = true
        viewProvider?.initializeReactNative(metroServerURL: metroServerURL)
    }

    @objc @discardableResult
    public func show(in vc: UIViewController, screenName: String? = nil, initialProperties: [String: Any]? = nil) -> UIView {
        ensureInit()
        let name = screenName ?? moduleName
        guard let rv = viewProvider?.createReactView(moduleName: name, initialProperties: initialProperties) else {
            return UIView()
        }
        rv.frame = vc.view.bounds
        rv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(rv)
        return rv
    }

    @objc public func createViewController(screenName: String? = nil, initialProperties: [String: Any]? = nil) -> UIViewController {
        let v = UIViewController(); v.view.backgroundColor = .white
        show(in: v, screenName: screenName, initialProperties: initialProperties)
        return v
    }
}
