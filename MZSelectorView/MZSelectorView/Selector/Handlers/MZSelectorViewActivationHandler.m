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
- (BOOL)selectorView:(MZSelectorView *)selectorView activateItemAtIndex:(NSUInteger)index animated:(BOOL)animated {
    BOOL out = selectorView && selectorView.superview && ![selectorView.items selectedItem] && index < selectorView.items.count;
    
    if (out) {
        [self adjustContentOffsetOfItemAtIndex:index inSelectorView:selectorView];
        [self storeScrollPositionOfItemAtIndex:index inSelectorView:selectorView];
        _selectorView = selectorView;
        
        selectorView.scrollView.scrollEnabled = NO;
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:willActivateViewItemAtIndex:)]) {
            [selectorView.delegate selectorView:selectorView willActivateViewItemAtIndex:index];
        }
        
        MZSelectorItem *item = selectorView.items[index];
        item.selected = YES;
        
        void(^layoutBlock)() = ^{
            [selectorView resetItemTransform:item];
            [selectorView updateLayout];
        };

        void(^finishBlock)(BOOL) = ^(BOOL finished) {
            [displayLink invalidate];
            item.active = YES;
            if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:didActivateViewItemAtIndex:)]) {
                [selectorView.delegate selectorView:selectorView didActivateViewItemAtIndex:index];
            }
        };
        
        if (animated) {
            [UIView animateWithDuration:kDefaultAnimationDuration
                             animations:layoutBlock
                             completion:finishBlock];
        }
        else {
            layoutBlock();
            finishBlock(YES);
        }
    }
    
    return out;
}

- (BOOL)deactivateSelectedItemInSelectorView:(MZSelectorView *)selectorView animated:(BOOL)animated {
    return [self selectorView:selectorView deactivateItemAtIndex:[selectorView.items indexOfSelectedItem] animated:animated];
}

- (BOOL)selectorView:(MZSelectorView *)selectorView deactivateItemAtIndex:(NSUInteger)index animated:(BOOL)animated {
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
        item.active   = NO;
        item.selected = NO;
        
        void(^layoutBlock)() = ^{
            [selectorView updateLayout            ];
            [selectorView transformDisplayingItems];
        };
        
        void(^finishBlock)(BOOL) = ^(BOOL finished) {
            [displayLink invalidate];
            _selectorView = nil;
            selectorView.scrollView.scrollEnabled = YES;
            if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:didDeactivateViewItemAtIndex:)]) {
                [selectorView.delegate selectorView:selectorView didDeactivateViewItemAtIndex:index];
            }
        };
        
        if (animated) {
            [UIView animateWithDuration:kDefaultAnimationDuration
                             animations:layoutBlock
                             completion:finishBlock];
        }
        else {
            layoutBlock();
            finishBlock(YES);
        }
    }
    
    return out;
}

- (BOOL)shouldTransformItem:(MZSelectorItem *)item inSelectorView:(MZSelectorView *)selectorView {
    return !item.selected;
}

- (void)updateFrame:(CADisplayLink*)displayLink {
}

- (void)adjustContentOffsetOfItemAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView*)selectorView {
    MZSelectorItem *item = selectorView.items[index];
    if (![selectorView.displayingViewItems containsObject:item.item]) {
        selectorView.scrollView.contentOffset = CGPointMake(selectorView.scrollView.contentOffset.x,
                                                            selectorView.defaultFrames[index].CGRectValue.origin.y - selectorView.itemInsets.top);
    }
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
