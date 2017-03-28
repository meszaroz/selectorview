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
    CGPoint _scrollPosition;
}
@end

@implementation MZSelectorViewDefaultHandler

+ (NSString*)name {
    return kDefaultHandlerName;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _scrollPosition = CGPointZero;
    }
    return self;
}

- (NSArray<NSValue*>*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    for (MZSelectorItem *item in selectorView.items) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(item.origin.x,
                                                           item.origin.y,
                                                           selectorView.bounds.size.width,
                                                           selectorView.bounds.size.height)]];
    }
    
    return out;
}

- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView {
    return CGSizeMake(selectorView.frame.size.width, MAX(selectorView.bounds.size.height, selectorView.adjustedContentHeight));
}

- (CGPoint)adjustedContentOffsetOfSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    CGPoint scrollPosition = _scrollPosition;
    _scrollPosition = CGPointZero;
    
    return [data contentOffsetOfRelativeScrollViewPosition:CGPointMake(0.0, 0.5)
               inRelationToAbsolutePositionInScrollContent:CGPointMake(0.0, data.contentSize.height * scrollPosition.y)];
}

/* calculate relative scroll positions for restoring after ex. rotation
 * - inactive: returns relative location in scroll content -> position in center of visible content */
- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@(selectorView.scrollInfo.activeInterfaceOrientation)];
    _scrollPosition = [data relativePositionInScrollContentOfScrollViewRelativePosition:CGPointMake(0.0, 0.5)];
}

@end
