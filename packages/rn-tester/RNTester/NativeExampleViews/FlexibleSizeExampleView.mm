/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FlexibleSizeExampleView.h"

#import <React/RCTBridge.h>
#import <React/RCTRootView.h>
#import <React/RCTRootViewDelegate.h>
#import <React/RCTViewManager.h>


#import "AppDelegate.h"
#if TARGET_OS_OSX // [macOS
#define UITextView NSTextView
#endif // macOS]

@interface FlexibleSizeExampleViewManager : RCTViewManager

@end

@implementation FlexibleSizeExampleViewManager

RCT_EXPORT_MODULE();

- (RCTUIView *)view // [macOS]
{
  return [FlexibleSizeExampleView new];
}

@end

@interface FlexibleSizeExampleView () <RCTRootViewDelegate>

@end

@implementation FlexibleSizeExampleView {
  RCTRootView *_resizableRootView;
  UITextView *_currentSizeTextView;
  BOOL _sizeUpdated;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _sizeUpdated = NO;

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    _resizableRootView =
        (RCTRootView *)[appDelegate.rootViewFactory viewWithModuleName:@"RootViewSizeFlexibilityExampleApp"];

    [_resizableRootView setSizeFlexibility:RCTRootViewSizeFlexibilityHeight];

    _currentSizeTextView = [UITextView new];
#ifndef TARGET_OS_TV
    _currentSizeTextView.editable = NO;
#endif
    // [macOS Github#1642: Suppress analyzer error of nonlocalized string
    NSString *currentSizeTextViewString = NSLocalizedString(@"Resizable view has not been resized yet", nil);
#if !TARGET_OS_OSX
    _currentSizeTextView.text = currentSizeTextViewString; // [macOS]
#else
    _currentSizeTextView.string = currentSizeTextViewString;
#endif // macOS]
    _currentSizeTextView.textColor = [RCTUIColor blackColor]; // [macOS]
    _currentSizeTextView.backgroundColor = [RCTUIColor whiteColor]; // [macOS]
    _currentSizeTextView.font = [UIFont boldSystemFontOfSize:10];

    _resizableRootView.delegate = self;

    [self addSubview:_currentSizeTextView];
    [self addSubview:_resizableRootView];
  }
  return self;
}

- (void)layoutSubviews
{
  float textViewHeight = 60;
  float spacingHeight = 10;
  [_resizableRootView
      setFrame:CGRectMake(
                   0, textViewHeight + spacingHeight, self.frame.size.width, _resizableRootView.frame.size.height)];
  [_currentSizeTextView setFrame:CGRectMake(0, 0, self.frame.size.width, textViewHeight)];
}

- (NSArray<RCTUIView<RCTComponent> *> *)reactSubviews // [macOS]
{
  // this is to avoid unregistering our RCTRootView when the component is removed from RN hierarchy
  (void)[super reactSubviews];
  return @[];
}

#pragma mark - RCTRootViewDelegate

- (void)rootViewDidChangeIntrinsicSize:(RCTRootView *)rootView
{
  CGRect newFrame = rootView.frame;
  newFrame.size = rootView.intrinsicContentSize;

  if (!_sizeUpdated) {
    _sizeUpdated = TRUE;
#if !TARGET_OS_OSX // [macOS]
    _currentSizeTextView.text =
#else // [macOS
    _currentSizeTextView.string =
#endif // macOS]
        [NSString
            stringWithFormat:
                @"RCTRootViewDelegate: content with initially unknown size has appeared, updating root view's size so the content fits."];

  } else {
#if !TARGET_OS_OSX // [macOS]
    _currentSizeTextView.text =
#else // [macOS
    _currentSizeTextView.string =
#endif // macOS]
        [NSString stringWithFormat:
                      @"RCTRootViewDelegate: content size has been changed to (%ld, %ld), updating root view's size.",
                      (long)newFrame.size.width,
                      (long)newFrame.size.height];
  }

  rootView.frame = newFrame;
}

@end
