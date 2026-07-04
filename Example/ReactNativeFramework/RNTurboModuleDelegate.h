#import <Foundation/Foundation.h>
@class RCTRootViewFactoryConfiguration, RCTRootViewFactory;
@interface RNTurboModuleDelegate : NSObject
+ (RCTRootViewFactory *)createRootViewFactoryWithConfiguration:(RCTRootViewFactoryConfiguration *)configuration
                                                      delegate:(RNTurboModuleDelegate * _Nullable * _Nonnull)delegate;
@end
