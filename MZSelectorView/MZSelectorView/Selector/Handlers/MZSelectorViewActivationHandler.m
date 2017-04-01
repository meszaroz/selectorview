//
//  MZSelectorViewActivationHandler.m
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewActivationHandler.h"
#import "MZSelectorViewItem_p.h"
#import "MZSelectorViewItem.h"
#import "MZSelectorItem.h"
#import "MZScrollInfo.h"

NSString* kActivationHandlerName = @"ActivationHandler";
static const CGFloat kDefaultAnimationDuration = 0.5;


@interface MZSelectorViewActivationHandler() {
    NSValue *_scrollPosition;
    __weak MZSelectorView *_selectorView;
}
@end

@implementation MZSelectorViewActivationHandler

+ (NSString*)name {
    return kActivationHandlerName;
}

#pragma mark - view item activation/deactivation
- (BOOL)selectorView:(MZSelectorView *)selectorView activateItemAtIndex:(NSUInteger)index {
    BOOL out = selectorView && selectorView.superview && ![selectorView.items selectedItem] && index < selectorView.items.count;
    
    if (out) {
        _selectorView = selectorView;
        
        selectorView.scrollView.scrollEnabled = NO;
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:willActivateViewItemAtIndex:)]) {
            [selectorView.delegate selectorView:selectorView willActivateViewItemAtIndex:index];
        }
        
        MZSelectorItem *item = selectorView.items[index];
        item.item.selected = YES;
        
        /* store scroll position of selected item (must be after selected setter) */
        [self storeScrollPositionOfItemAtIndex:index inSelectorView:selectorView];
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [selectorView resetItemTransform:item];
                             [selectorView updateLayout];
                         }
                         completion:^(BOOL finished) {
                             [displayLink invalidate];
                             item.item.active = YES;
                             if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:didActivateViewItemAtIndex:)]) {
                                 [selectorView.delegate selectorView:selectorView didActivateViewItemAtIndex:index];
                             }
                         }];
    }
    
    return out;
}

- (BOOL)deactivateSelectedItemInSelectorView:(MZSelectorView *)selectorView {
    return [self selectorView:selectorView deactivateItemAtIndex:[selectorView.items indexOfSelectedItem]];
}

- (BOOL)selectorView:(MZSelectorView *)selectorView deactivateItemAtIndex:(NSUInteger)index {
    BOOL out = selectorView && selectorView.superview && [selectorView selectedViewItem];
    
    if (out) {
        [self clearScrollPosition];
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:willDeactivateViewItemAtIndex:)]) {
            [selectorView.delegate selectorView:selectorView willDeactivateViewItemAtIndex:index];
        }
        
        /* ToDo: reapply transform for other views */
        
        MZSelectorItem *item = selectorView.items[index];
        item.item.active   = NO;
        item.item.selected = NO;
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [selectorView updateLayout            ];
                             [selectorView transformDisplayingItems];
                         }
                         completion:^(BOOL finished) {
                             [displayLink invalidate];
                             _selectorView = nil;
                             selectorView.scrollView.scrollEnabled = YES;
                             if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:didDeactivateViewItemAtIndex:)]) {
                                 [selectorView.delegate selectorView:selectorView didDeactivateViewItemAtIndex:index];
                             }
                         }];
    }
    
    return out;
}

- (BOOL)shouldTransformItem:(MZSelectorItem *)item inSelectorView:(MZSelectorView *)selectorView {
    return !item.selected;
}

- (void)updateFrame:(CADisplayLink*)displayLink {
}

/* calculate relative scroll positions for restoring after ex. rotation
 * - active: returns relative location on screen -> position before activation (relative to screen) */
- (void)storeScrollPositionOfItemAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView*)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];    
    _scrollPosition = [NSValue valueWithCGPoint: index != NSNotFound ?
                       [data relativePositionInScrollViewOfAbsolutePositionInScrollContent:selectorView.defaultFrames[index].CGRectValue.origin] : /* active */
                       CGPointZero];                                                                                                               /* inactive */
}

- (void)clearScrollPosition {
    _scrollPosition = nil;
}

- (CGRectArray*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    NSUInteger selectedIndex = [selectorView.items indexOfSelectedItem];
    
    CGRectArray *referenceFrames = selectorView.referenceFrames;
    CGRect currentFrame  = selectedIndex != NSNotFound ?
        referenceFrames[selectedIndex].CGRectValue :
        CGRectNull;
    
    CGFloat prevOffset = !CGRectIsNull(currentFrame) ? currentFrame.origin.y - selectorView.scrollView.contentOffset.y                                   : 0.0;
    CGFloat nextOffset = !CGRectIsNull(currentFrame) ? selectorView.bounds.size.height + selectorView.scrollView.contentOffset.y - currentFrame.origin.y : 0.0;
    
    for (NSUInteger i = 0; i < referenceFrames.count; ++i) {
        NSValue *value = referenceFrames[i];
        /**/ if (i < selectedIndex) {
            [out addObject:[NSValue valueWithCGRect:CGRectMake(value.CGRectValue.origin.x,
                                                               value.CGRectValue.origin.y - prevOffset,
                                                               value.CGRectValue.size.width,
                                                               value.CGRectValue.size.height)]];
        }
        else if (i > selectedIndex) {
            [out addObject:[NSValue valueWithCGRect:CGRectMake(value.CGRectValue.origin.x,
                                                               value.CGRectValue.origin.y + nextOffset,
                                                               value.CGRectValue.size.width,
                                                               value.CGRectValue.size.height)]];
        }
        else {
            [out addObject:[NSValue valueWithCGRect:CGRectMake(0.0,
                                                               selectorView.scrollView.contentOffset.y,
                                                               currentFrame.size.width,
                                                               currentFrame.size.height)]];
        }
    }
    
    return out;
}

- (CGRectArray*)referenceFramesInSelectorView:(MZSelectorView *)selectorView {
    return selectorView.defaultFrames;
}

- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView {
    return CGSizeMake(selectorView.scrollView.contentSize.width,
                      MAX(selectorView.bounds.size.height, selectorView.adjustedContentHeight));
}

- (CGPoint)adjustedContentOffsetOfSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    NSUInteger index = [selectorView.items indexOfSelectedItem];
    return _scrollPosition && index != NSNotFound ?
        [data contentOffsetOfRelativeScrollViewPosition:_scrollPosition.CGPointValue
            inRelationToAbsolutePositionInScrollContent:selectorView.defaultFrames[index].CGRectValue.origin] :
        selectorView.scrollView.contentOffset;
}

@end
