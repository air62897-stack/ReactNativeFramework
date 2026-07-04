#import "RNJSRuntimeConfigurator.h"
#import <React/RCTHermesInstanceFactory.h>
#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/featureflags/ReactNativeFeatureFlagsOverridesOSSStable.h>
@implementation RNJSRuntimeConfigurator
- (JSRuntimeFactoryRef)createJSRuntimeFactory {
    facebook::react::ReactNativeFeatureFlags::dangerouslyForceOverride(
        std::make_unique<facebook::react::ReactNativeFeatureFlagsOverridesOSSStable>());
    return jsrt_create_hermes_factory();
}
@end
