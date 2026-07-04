#import "RNTurboModuleDelegate.h"
#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import <jsi/jsi.h>

// 文件作用域 HostObject（避免 lambda make_shared C++20 问题）
class _RCTEventEmitterStub : public facebook::jsi::HostObject {
public:
    facebook::jsi::Value get(facebook::jsi::Runtime &rt, const facebook::jsi::PropNameID &name) override {
        return facebook::jsi::Function::createFromHostFunction(rt, name, 3,
            [](facebook::jsi::Runtime &, const facebook::jsi::Value &, const facebook::jsi::Value *, size_t) {
                return facebook::jsi::Value::undefined(); });
    }
    void set(facebook::jsi::Runtime &, const facebook::jsi::PropNameID &, const facebook::jsi::Value &) override {}
    std::vector<facebook::jsi::PropNameID> getPropertyNames(facebook::jsi::Runtime &) override { return {}; }
};
#import <React_RCTAppDelegate/RCTRootViewFactory.h>
#import <React_NativeModulesApple/ReactCommon/RCTTurboModuleManager.h>
#import <react/nativemodule/defaults/DefaultTurboModules.h>
#if __has_include(<React/RCTImagePlugins.h>)
#import <React/RCTImagePlugins.h>
#elif __has_include(<React_RCTImage/RCTImage/RCTImagePlugins.h>)
#import <React_RCTImage/RCTImage/RCTImagePlugins.h>
#endif
#if __has_include(<React/RCTNetworkPlugins.h>)
#import <React/RCTNetworkPlugins.h>
#elif __has_include(<React_RCTNetwork/RCTNetwork/RCTNetworkPlugins.h>)
#import <React_RCTNetwork/RCTNetwork/RCTNetworkPlugins.h>
#endif
#if __has_include(<React/RCTImageLoader.h>)
#import <React/RCTImageLoader.h>
#elif __has_include(<React_RCTImage/RCTImage/RCTImageLoader.h>)
#import <React_RCTImage/RCTImage/RCTImageLoader.h>
#endif
#if __has_include(<React/RCTBundleAssetImageLoader.h>)
#import <React/RCTBundleAssetImageLoader.h>
#elif __has_include(<React_RCTImage/RCTImage/RCTBundleAssetImageLoader.h>)
#import <React_RCTImage/RCTImage/RCTBundleAssetImageLoader.h>
#endif
#if __has_include(<React/RCTLocalAssetImageLoader.h>)
#import <React/RCTLocalAssetImageLoader.h>
#elif __has_include(<React_RCTImage/RCTImage/RCTLocalAssetImageLoader.h>)
#import <React_RCTImage/RCTImage/RCTLocalAssetImageLoader.h>
#endif
#if __has_include(<React/RCTGIFImageDecoder.h>)
#import <React/RCTGIFImageDecoder.h>
#elif __has_include(<React_RCTImage/RCTImage/RCTGIFImageDecoder.h>)
#import <React_RCTImage/RCTImage/RCTGIFImageDecoder.h>
#endif
#if __has_include(<React/RCTNetworking.h>)
#import <React/RCTNetworking.h>
#elif __has_include(<React_RCTNetwork/RCTNetwork/RCTNetworking.h>)
#import <React_RCTNetwork/RCTNetwork/RCTNetworking.h>
#endif
#if __has_include(<React/RCTHTTPRequestHandler.h>)
#import <React/RCTHTTPRequestHandler.h>
#elif __has_include(<React_RCTNetwork/RCTNetwork/RCTHTTPRequestHandler.h>)
#import <React_RCTNetwork/RCTNetwork/RCTHTTPRequestHandler.h>
#endif
#if __has_include(<React/RCTDataRequestHandler.h>)
#import <React/RCTDataRequestHandler.h>
#elif __has_include(<React_RCTNetwork/RCTNetwork/RCTDataRequestHandler.h>)
#import <React_RCTNetwork/RCTNetwork/RCTDataRequestHandler.h>
#endif
#if __has_include(<React/RCTFileRequestHandler.h>)
#import <React/RCTFileRequestHandler.h>
#elif __has_include(<React_RCTNetwork/RCTNetwork/RCTFileRequestHandler.h>)
#import <React_RCTNetwork/RCTNetwork/RCTFileRequestHandler.h>
#endif

@interface RNTurboModuleDelegate () <RCTTurboModuleManagerDelegate>
@end

@implementation RNTurboModuleDelegate

+ (RCTRootViewFactory *)createRootViewFactoryWithConfiguration:(RCTRootViewFactoryConfiguration *)cfg delegate:(RNTurboModuleDelegate **)del {
    RNTurboModuleDelegate *d = [[RNTurboModuleDelegate alloc] init];
    *del = d;
    return [[RCTRootViewFactory alloc] initWithTurboModuleDelegate:d hostDelegate:(id)d configuration:cfg];
}
- (Class)getModuleClassFromName:(const char *)n {
    Class c = RCTImageClassProvider(n); if (c) return c;
    c = RCTNetworkClassProvider(n); if (c) return c;
    return nil;
}
- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)c {
    if (c == NSClassFromString(@"RCTImageLoader"))
        return (id<RCTTurboModule>)[[RCTImageLoader alloc] initWithRedirectDelegate:nil
            loadersProvider:^(id _){ return @[[[NSClassFromString(@"RCTBundleAssetImageLoader") alloc] init],[[NSClassFromString(@"RCTLocalAssetImageLoader") alloc] init]]; }
            decodersProvider:^(id _){ return @[[[NSClassFromString(@"RCTGIFImageDecoder") alloc] init]]; }];
    if (c == NSClassFromString(@"RCTNetworking"))
        return (id<RCTTurboModule>)[[RCTNetworking alloc] initWithHandlersProvider:^(id _){ return @[[[NSClassFromString(@"RCTHTTPRequestHandler") alloc] init],[[NSClassFromString(@"RCTDataRequestHandler") alloc] init],[[NSClassFromString(@"RCTFileRequestHandler") alloc] init]]; }];
    return nil;
}
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)n jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)j {
    return facebook::react::DefaultTurboModules::getTurboModule(n, j);
}

- (void)hostDidStart:(id)h {}
- (void)host:(id)h didInitializeRuntime:(facebook::jsi::Runtime &)runtime {
    auto emitter = std::shared_ptr<_RCTEventEmitterStub>(new _RCTEventEmitterStub());
    auto factory = facebook::jsi::Function::createFromHostFunction(runtime,
        facebook::jsi::PropNameID::forAscii(runtime, "f"), 0,
        [emitter](facebook::jsi::Runtime &rt, const facebook::jsi::Value &, const facebook::jsi::Value *, size_t) {
            return facebook::jsi::Object::createFromHostObject(rt, emitter); });
    runtime.global().getPropertyAsFunction(runtime, "RN$registerCallableModule").call(runtime, "RCTEventEmitter", factory);
    runtime.global().getPropertyAsFunction(runtime, "RN$registerCallableModule").call(runtime, "RCTDeviceEventEmitter", factory);
    runtime.global().getPropertyAsFunction(runtime, "RN$registerCallableModule").call(runtime, "RCTNativeAppEventEmitter", factory);
}

@end
