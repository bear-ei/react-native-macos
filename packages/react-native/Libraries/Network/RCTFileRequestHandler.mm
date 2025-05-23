/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTFileRequestHandler.h>

#if !TARGET_OS_OSX // [macOS]
#import <MobileCoreServices/MobileCoreServices.h>
#else // [macOS
#import <CoreServices/CoreServices.h>
#endif // macOS]

#import <React/RCTUtils.h>
#import <ReactCommon/RCTTurboModule.h>

#import "RCTNetworkPlugins.h"

@interface RCTFileRequestHandler () <RCTTurboModule>
@end

@implementation RCTFileRequestHandler {
  NSOperationQueue *_fileQueue;
}

RCT_EXPORT_MODULE()

- (void)invalidate
{
  [_fileQueue cancelAllOperations];
  _fileQueue = nil;
}

- (BOOL)canHandleRequest:(NSURLRequest *)request
{
  return [request.URL.scheme caseInsensitiveCompare:@"file"] == NSOrderedSame && !RCTIsBundleAssetURL(request.URL);
}

- (NSOperation *)sendRequest:(NSURLRequest *)request withDelegate:(id<RCTURLRequestDelegate>)delegate
{
  // Lazy setup
  if (!_fileQueue) {
    _fileQueue = [NSOperationQueue new];
    _fileQueue.maxConcurrentOperationCount = 4;
  }

  NSBlockOperation *op = [NSBlockOperation new];
  __weak NSBlockOperation *weakOp = op;
  [op addExecutionBlock:^{
    NSBlockOperation *strongOp = weakOp; // Strong reference to avoid deallocation during execution
    if (strongOp == nil || [strongOp isCancelled]) {
      return;
    }
    // Get content length
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager new];
    NSDictionary<NSString *, id> *fileAttributes = [fileManager attributesOfItemAtPath:request.URL.path error:&error];
    if (!fileAttributes) {
      [delegate URLRequest:strongOp didCompleteWithError:error];
      return;
    }

    // Get mime type
    NSString *fileExtension = [request.URL pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType =
        (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);

    // Send response
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL
                                                        MIMEType:contentType
                                           expectedContentLength:[fileAttributes[NSFileSize] ?: @-1 integerValue]
                                                textEncodingName:nil];

    [delegate URLRequest:strongOp didReceiveResponse:response];

    // Load data
    NSData *data = [NSData dataWithContentsOfURL:request.URL options:NSDataReadingMappedIfSafe error:&error];
    if (data) {
      [delegate URLRequest:strongOp didReceiveData:data];
    }
    [delegate URLRequest:strongOp didCompleteWithError:error];
  }];

  [_fileQueue addOperation:op];
  return op;
}

- (void)cancelRequest:(NSOperation *)op
{
  [op cancel];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return nullptr;
}

@end

Class RCTFileRequestHandlerCls(void)
{
  return RCTFileRequestHandler.class;
}
