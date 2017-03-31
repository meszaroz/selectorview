//
//  MZSelectorViewDefaultHandler.m
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewDefaultHandler.h"
#import "MZSelectorItem.h"
#import "MZScrollInfo.h"

NSString* kDefaultHandlerName = @"DefaulHandler";

@interface MZSelectorViewDefaultHandler() {
    NSValue *_scrollPosition;
}
@end

@implementation MZSelectorViewDefaultHandler

+ (NSString*)name {
    return kDefaultHandlerName;
}

- (CGRectArray*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    return selectorView.defaultFrames;
}

- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView {
    return CGSizeMake(selectorView.scrollView.contentSize.width,
                      MAX(selectorView.bounds.size.height, selectorView.adjustedContentHeight));
}

- (CGRectArray*)referenceFramesInSelectorView:(MZSelectorView *)selectorView {
    return selectorView.defaultFrames;
}

- (CGPoint)adjustedContentOffsetOfSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    CGPoint out = _scrollPosition ?
        [data contentOffsetOfRelativeScrollViewPosition:CGPointMake(0.0, 0.5)
            inRelationToAbsolutePositionInScrollContent:CGPointMake(0.0, data.contentSize.height * _scrollPosition.CGPointValue.y)] :
        selectorView.scrollView.contentOffset;
    _scrollPosition = nil;
    return out;
}

/* calculate relative scroll positions for restoring after ex. rotation
 * - inactive: returns relative location in scroll content -> position in center of visible content */
- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@(selectorView.scrollInfo.activeInterfaceOrientation)];
    _scrollPosition = [NSValue valueWithCGPoint:[data relativePositionInScrollContentOfScrollViewRelativePosition:CGPointMake(0.0, 0.5)]];
}

@end
