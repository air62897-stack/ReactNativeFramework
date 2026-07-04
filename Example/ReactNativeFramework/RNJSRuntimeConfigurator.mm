#import "RNJSRuntimeConfigurator.h"
#import <React/RCTHermesInstanceFactory.h>
#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/featureflags/ReactNativeFeatureFlagsOverridesOSSStable.h>
@implementation RNJSRuntimeConfigurator

/// 必须在任何 RN 相关代码执行前调用，避免 InspectorFlags 报错
+ (void)earlyInitialize {
    facebook::react::ReactNativeFeatureFlags::dangerouslyForceOverride(
        std::make_unique<facebook::react::ReactNativeFeatureFlagsOverridesOSSStable>());
}

- (JSRuntimeFactoryRef)createJSRuntimeFactory {
    return jsrt_create_hermes_factory();
}
@end
