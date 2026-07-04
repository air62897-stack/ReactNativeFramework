import UIKit
import React
import ReactNativeFramework

class RNBridgeManager: NSObject, RNViewProvider {
    static let shared = RNBridgeManager()
    private var factory: RCTRootViewFactory?
    private var turboDelegate: RNTurboModuleDelegate?
    private var jsConfig: RNJSRuntimeConfigurator?
    private var initialized = false
    private var initTime: Date?

    func initializeReactNative(metroServerURL: String) {
        guard !initialized else { return }
        initialized = true; initTime = Date()

        let url = "\(metroServerURL)/src/registry.bundle?platform=ios&dev=true&minify=false&modulesOnly=false&runModule=true"
        guard let bundleURL = URL(string: url) else { return }
        print("[RNEmbed] Init: \(url)")

        let cfg = RCTRootViewFactoryConfiguration(bundleURL: bundleURL, newArchEnabled: true)
        cfg.bundleURLBlock = { URL(string: url) }
        jsConfig = RNJSRuntimeConfigurator()
        cfg.jsRuntimeConfiguratorDelegate = jsConfig

        var d: RNTurboModuleDelegate?
        factory = RNTurboModuleDelegate.createRootViewFactory(with: cfg, delegate: &d)
        turboDelegate = d
        factory?.initializeReactHost(launchOptions: nil, bundleConfiguration: RCTBundleConfiguration(), devMenuConfiguration: RCTDevMenuConfiguration())
        print("[RNEmbed] Factory initialized")
    }

    func createReactView(moduleName: String, initialProperties: [String: Any]?) -> UIView? {
        guard let f = factory else { return nil }

        // 等待至少 3s 让 host 完全初始化
        if let t = initTime, Date().timeIntervalSince(t) < 3 {
            Thread.sleep(forTimeInterval: 3 - Date().timeIntervalSince(t))
        }

        let v = f.view(withModuleName: moduleName, initialProperties: initialProperties ?? [:], launchOptions: nil)
        v.backgroundColor = .white
        print("[RNEmbed] View created: \(moduleName)")
        return v
    }
}
