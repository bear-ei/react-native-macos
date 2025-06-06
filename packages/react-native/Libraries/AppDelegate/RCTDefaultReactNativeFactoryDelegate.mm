/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTDefaultReactNativeFactoryDelegate.h"
#import <ReactCommon/RCTHost.h>
#import "RCTAppSetupUtils.h"
#import "RCTDependencyProvider.h"

#import <react/nativemodule/defaults/DefaultTurboModules.h>

@implementation RCTDefaultReactNativeFactoryDelegate

@synthesize dependencyProvider;

- (NSURL *_Nullable)sourceURLForBridge:(nonnull RCTBridge *)bridge
{
  [NSException raise:@"RCTBridgeDelegate::sourceURLForBridge not implemented"
              format:@"Subclasses must implement a valid sourceURLForBridge method"];
  return nil;
}

- (UIViewController *)createRootViewController
{
  return [UIViewController new];
}

- (RCTBridge *)createBridgeWithDelegate:(id<RCTBridgeDelegate>)delegate launchOptions:(NSDictionary *)launchOptions
{
  return [[RCTBridge alloc] initWithDelegate:delegate launchOptions:launchOptions];
}

- (void)setRootView:(RCTPlatformView *)rootView toRootViewController:(RCTPlatformViewController *)rootViewController
{
  rootViewController.view = rootView;
}

- (void)customizeRootView:(RCTRootView *)rootView
{
  // Override point for customization after application launch.
}

- (RCTPlatformView *)createRootViewWithBridge:(RCTBridge *)bridge
                          moduleName:(NSString *)moduleName
                           initProps:(NSDictionary *)initProps
{
  BOOL enableFabric = self.fabricEnabled;
  RCTUIView *rootView = RCTAppSetupDefaultRootView(bridge, moduleName, initProps, enableFabric);

#if !TARGET_OS_OSX // [macOS]
  rootView.backgroundColor = [UIColor systemBackgroundColor];
#else // [macOS
  rootView.backgroundColor = [NSColor windowBackgroundColor];
#endif // macOS]

  return rootView;
}

- (RCTColorSpace)defaultColorSpace
{
  return RCTColorSpaceSRGB;
}

- (NSURL *_Nullable)bundleURL
{
  [NSException raise:@"RCTAppDelegate::bundleURL not implemented"
              format:@"Subclasses must implement a valid getBundleURL method"];
  return nullptr;
}

- (NSDictionary<NSString *, Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents
{
  return self.dependencyProvider ? self.dependencyProvider.thirdPartyFabricComponents : @{};
}

- (void)hostDidStart:(RCTHost *)host
{
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  return facebook::react::DefaultTurboModules::getTurboModule(name, jsInvoker);
}

#pragma mark - RCTArchConfiguratorProtocol

- (BOOL)newArchEnabled
{
#if RCT_NEW_ARCH_ENABLED
  return YES;
#else
  return NO;
#endif
}

- (BOOL)bridgelessEnabled
{
  return self.newArchEnabled;
}

- (BOOL)fabricEnabled
{
  return self.newArchEnabled;
}

- (BOOL)turboModuleEnabled
{
  return self.newArchEnabled;
}

- (Class)getModuleClassFromName:(const char *)name
{
  return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  return nullptr;
}

@end
