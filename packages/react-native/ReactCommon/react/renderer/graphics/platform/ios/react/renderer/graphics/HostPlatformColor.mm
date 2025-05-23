/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "HostPlatformColor.h"

#import <Foundation/Foundation.h>
#import <React/RCTUIKit.h> // [macOS]
#import <react/utils/ManagedObjectWrapper.h>
#import <string>

using namespace facebook::react;

NS_ASSUME_NONNULL_BEGIN

namespace facebook::react {

namespace {
RCTUIColor *_Nullable UIColorFromInt32(int32_t intColor) // [macOS]
{
  CGFloat a = CGFloat((intColor >> 24) & 0xFF) / 255.0;
  CGFloat r = CGFloat((intColor >> 16) & 0xFF) / 255.0;
  CGFloat g = CGFloat((intColor >> 8) & 0xFF) / 255.0;
  CGFloat b = CGFloat(intColor & 0xFF) / 255.0;
  return [RCTUIColor colorWithRed:r green:g blue:b alpha:a]; // [macOS]
}

RCTUIColor *_Nullable UIColorFromDynamicColor(const facebook::react::DynamicColor &dynamicColor) // [macOS]
{
  int32_t light = dynamicColor.lightColor;
  int32_t dark = dynamicColor.darkColor;
  int32_t highContrastLight = dynamicColor.highContrastLightColor;
  int32_t highContrastDark = dynamicColor.highContrastDarkColor;

  RCTUIColor *lightColor = UIColorFromInt32(light); // [macOS]
  RCTUIColor *darkColor = UIColorFromInt32(dark); // [macOS]
  RCTUIColor *highContrastLightColor = UIColorFromInt32(highContrastLight); // [macOS]
  RCTUIColor *highContrastDarkColor = UIColorFromInt32(highContrastDark); // [macOS]

  if (lightColor != nil && darkColor != nil) {
#if !TARGET_OS_OSX // [macOS]
    UIColor *color = [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(UITraitCollection *_Nonnull collection) {
      if (collection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        if (collection.accessibilityContrast == UIAccessibilityContrastHigh && highContrastDark != 0) {
          return highContrastDarkColor;
        } else {
          return darkColor;
        }
      } else {
        if (collection.accessibilityContrast == UIAccessibilityContrastHigh && highContrastLight != 0) {
          return highContrastLightColor;
        } else {
          return lightColor;
        }
      }
    }];
    return color;
#else // [macOS
    NSColor *color = [NSColor colorWithName:nil dynamicProvider:^NSColor * _Nonnull(NSAppearance * _Nonnull appearance) {
      NSMutableArray<NSAppearanceName> *appearances = [NSMutableArray arrayWithArray:@[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]];
      if (highContrastLightColor != nil) {
        [appearances addObject:NSAppearanceNameAccessibilityHighContrastAqua];
      }
      if (highContrastDarkColor != nil) {
        [appearances addObject:NSAppearanceNameAccessibilityHighContrastDarkAqua];
      }
      NSAppearanceName bestMatchingAppearance = [appearance bestMatchFromAppearancesWithNames:appearances];
      if (bestMatchingAppearance == NSAppearanceNameAqua) {
        return lightColor;
      } else if (bestMatchingAppearance == NSAppearanceNameDarkAqua) {
        return darkColor;
      } else if (bestMatchingAppearance == NSAppearanceNameAccessibilityHighContrastAqua) {
        return highContrastLightColor;
      } else if (bestMatchingAppearance == NSAppearanceNameAccessibilityHighContrastDarkAqua) {
        return highContrastDarkColor;
      } else {
        return lightColor;
      }
    }];
    return color;
#endif // macOS]
  } else {
    return nil;
  }

  return nil;
}

int32_t ColorFromUIColor(RCTUIColor *color) // [macOS]
{
  float ratio = 255;
  CGFloat rgba[4];
#if !TARGET_OS_OSX // [macOS
  [color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
#else // [macOS
  // [NSColor getRed:green:blue:alpha]` wil throw an exception if the colorspace is not SRGB,
  [[color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
#endif // macOS]
  return ((int32_t)round((float)rgba[3] * ratio) & 0xff) << 24 | ((int)round((float)rgba[0] * ratio) & 0xff) << 16 |
      ((int)round((float)rgba[1] * ratio) & 0xff) << 8 | ((int)round((float)rgba[2] * ratio) & 0xff);
}

int32_t ColorFromUIColor(const std::shared_ptr<void> &uiColor)
{
  RCTUIColor *color = (RCTUIColor *)unwrapManagedObject(uiColor); // [macOS]
  if (color) {
#if !TARGET_OS_OSX // [macOS]
    UITraitCollection *currentTraitCollection = [UITraitCollection currentTraitCollection];
    color = [color resolvedColorWithTraitCollection:currentTraitCollection];
#endif // [macOS]
    return ColorFromUIColor(color);
  }

  return 0;
}

RCTUIColor *_Nullable UIColorFromComponentsColor(const facebook::react::ColorComponents &components) // [macOS]
{
  if (components.colorSpace == ColorSpace::DisplayP3) {
    return [RCTUIColor colorWithDisplayP3Red:components.red // [macOS]
                                       green:components.green
                                        blue:components.blue
                                       alpha:components.alpha];
  }
  return [RCTUIColor colorWithRed:components.red green:components.green blue:components.blue alpha:components.alpha]; // [macOS]
}
} // anonymous namespace

Color::Color(int32_t color)
{
  uiColor_ = wrapManagedObject(UIColorFromInt32(color));
}

Color::Color(const DynamicColor &dynamicColor)
{
  uiColor_ = wrapManagedObject(UIColorFromDynamicColor(dynamicColor));
}

Color::Color(const ColorComponents &components)
{
  uiColor_ = wrapManagedObject(UIColorFromComponentsColor(components));
}

Color::Color(std::shared_ptr<void> uiColor)
{
  uiColor_ = std::move(uiColor);
}

bool Color::operator==(const Color &other) const
{
  return (!uiColor_ && !other.uiColor_) ||
      (uiColor_ && other.uiColor_ &&
       [unwrapManagedObject(getUIColor()) isEqual:unwrapManagedObject(other.getUIColor())]);
}

bool Color::operator!=(const Color &other) const
{
  return !(*this == other);
}

int32_t Color::getColor() const
{
  return ColorFromUIColor(uiColor_);
}

float Color::getChannel(int channelId) const
{
  CGFloat rgba[4];
  RCTUIColor *color = (__bridge RCTUIColor *)getUIColor().get(); // [macOS]
  [color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
  return static_cast<float>(rgba[channelId]);
}

} // namespace facebook::react

NS_ASSUME_NONNULL_END
