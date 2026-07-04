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

    /// 默认端口，可自定义
    @objc public var metroPort: Int = 8081

    /// 真机调试时使用的 Mac 局域网 IP（如 192.168.x.x），nil 则走自动检测
    @objc public var customHost: String?

    /// 模块名
    @objc public var moduleName: String = "main"
    @objc public weak var viewProvider: RNViewProvider?
    private var initialized = false

    // MARK: - 自动检测 Metro 服务器地址

    /// 获取当前有效的 Metro 服务器 URL，自动区分模拟器 / 真机
    @objc public var resolvedMetroURL: String {
        let host: String
        if let custom = customHost {
            host = custom
        } else {
            #if targetEnvironment(simulator)
            host = "127.0.0.1"
            #else
            // 真机上尝试通过 hostname 解析 Mac 的局域网 IP
            host = Self.resolveMacHost() ?? "127.0.0.1"
            #endif
        }
        return "http://\(host):\(metroPort)"
    }

    /// 尝试通过设备名解析 Mac 在局域网中的 IP
    private static func resolveMacHost() -> String? {
    
        let macIP = "192.168.124.28"
        
        return macIP
        
        let deviceName = ProcessInfo.processInfo.hostName
        // 将设备名转换为 .local mDNS 域名
        let host = deviceName
            .replacingOccurrences(
                of: "\\.(iPhone|iPad|iPod|Watch|AppleTV|Mac)\\b",
                with: ".local",
                options: .regularExpression
            )
            .appending(".local")
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let info = result else {
            print("[RNEmbed] ⚠️ 无法自动解析 Mac IP，请在 RNEmbedder.shared.customHost 中手动设置")
            return nil
        }
        defer { freeaddrinfo(result) }
        if let addr = info.pointee.ai_addr {
            let sockAddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            var ipChars = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            var sinAddr = sockAddr.sin_addr
            if inet_ntop(AF_INET, &sinAddr, &ipChars, socklen_t(INET_ADDRSTRLEN)) != nil {
                let ip = String(cString: ipChars)
                if ip != "127.0.0.1" && !ip.hasPrefix("127.") {
                    print("[RNEmbed] Resolved Mac IP via \(host): \(ip)")
                    return ip
                }
            }
        }
        print("[RNEmbed] ⚠️ 无法自动解析 Mac IP，请在 RNEmbedder.shared.customHost 中手动设置")
        return nil
    }

    private func ensureInit() {
        guard !initialized else { return }
        initialized = true
        print("[RNEmbed] Metro URL: \(resolvedMetroURL)")
        viewProvider?.initializeReactNative(metroServerURL: resolvedMetroURL)
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
