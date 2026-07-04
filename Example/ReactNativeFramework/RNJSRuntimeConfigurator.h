#import <Foundation/Foundation.h>
#import <React_RCTAppDelegate/RCTJSRuntimeConfiguratorProtocol.h>
@interface RNJSRuntimeConfigurator : NSObject <RCTJSRuntimeConfiguratorProtocol>
/// 在任何 RN 初始化之前调用，设置 feature flags 避免 runtime 报错
+ (void)earlyInitialize;
@end
