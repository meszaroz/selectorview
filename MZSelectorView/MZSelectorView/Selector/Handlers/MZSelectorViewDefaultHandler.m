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

@implementation MZSelectorViewDefaultHandler

+ (NSString*)name {
    return kDefaultHandlerName;
}

- (NSArray<NSValue*>*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    for (MZSelectorItem *item in selectorView.items) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(item.defaultOrigin.x,
                                                           item.defaultOrigin.y,
                                                           selectorView.bounds.size.width,
                                                           selectorView.bounds.size.height)]];
    }
    
    return out;
}

- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView {
    return CGSizeMake(selectorView.scrollView.contentSize.width,
                      MAX(selectorView.bounds.size.height, selectorView.adjustedContentHeight));
}

- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView {
    /* 1. calculate relative scroll positions for restoring after ex. rotation
     * - inactive: returns relative location in scroll content -> position in center of visible content */
    CGPoint scrollPosition = [self.class referenceRelativeScrollPositionInSelectorView:selectorView];
    
    /* 2. calculate content height and origins - needed before scroll position adjusting, because it uses the info of the new positions */
    [selectorView calculateAndUpdateDimensions];
    
    /* 3. adjust scroll positions for changed layout */
    [self.class adjustScrollPositionToReferenceRelativeScrollViewPosition:scrollPosition inSelectorView:selectorView];
}

#pragma mark - adjust scroll positions for layout
+ (CGPoint)referenceRelativeScrollPositionInSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@(selectorView.scrollInfo.activeInterfaceOrientation)];
    return [data relativePositionInScrollContentOfScrollViewRelativePosition:CGPointMake(0.0, 0.5)];
}

+ (void)adjustScrollPositionToReferenceRelativeScrollViewPosition:(CGPoint)position inSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    selectorView.scrollView.contentOffset = [data contentOffsetOfRelativeScrollViewPosition:CGPointMake(0.0, 0.5)
                                                inRelationToAbsolutePositionInScrollContent:CGPointMake(0.0, data.contentSize.height * position.y)];
}

@end
