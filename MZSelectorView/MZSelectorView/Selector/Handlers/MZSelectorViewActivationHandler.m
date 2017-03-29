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

@implementation MZSelectorViewActivationHandler

+ (NSString*)name {
    return kActivationHandlerName;
}

#pragma mark - view item activation/deactivation
- (BOOL)selectorView:(MZSelectorView *)selectorView activateItemAtIndex:(NSUInteger)index {
    BOOL out = selectorView && selectorView.superview && ![selectorView.items selectedItem] && index < selectorView.items.count;
    
    if (out) {
        selectorView.scrollView.scrollEnabled = NO;
        
        if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:willActivateViewItemAtIndex:)]) {
            [selectorView.delegate selectorView:selectorView willActivateViewItemAtIndex:index];
        }
        
        MZSelectorViewItem *item = selectorView.items[index].item;
        item.selected = YES;
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [selectorView resetItemTransform:selectorView.items[index]];
                             [selectorView updateLayout];
                         }
                         completion:^(BOOL finished) {
                             item.active = YES;
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
        if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:willDeactivateViewItemAtIndex:)]) {
            [selectorView.delegate selectorView:selectorView willDeactivateViewItemAtIndex:index];
        }
        
        /* ToDo: reapply transform for other views */
        
        MZSelectorViewItem *item = selectorView.items[index].item;
        item.active   = NO;
        item.selected = NO;
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [selectorView updateLayout            ];
                             [selectorView transformDisplayingItems];
                         }
                         completion:^(BOOL finished) {
                             selectorView.scrollView.scrollEnabled = YES;
                             if (selectorView.delegate && [selectorView.delegate respondsToSelector:@selector(selectorView:didDeactivateViewItemAtIndex:)]) {
                                 [selectorView.delegate selectorView:selectorView didDeactivateViewItemAtIndex:index];
                             }
                         }];
    }
    
    return out;
}

- (NSArray<NSValue*>*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    NSUInteger      selectedIndex = [selectorView.items indexOfSelectedItem];
    MZSelectorItem *selectedItem  = [selectorView.items selectedItem       ];
    
    NSArray<NSValue*> *defaultFrames = selectorView.calculatedDefaultFrames;
    
    NSMutableArray<NSValue*> *prevFrames = [NSMutableArray array];
    NSMutableArray<NSValue*> *nextFrames = [NSMutableArray array];
    NSValue                  *currFrame  = nil;
    
    for (NSUInteger i = 0; i < defaultFrames.count; ++i) {
        /**/ if (i < selectedIndex) { [prevFrames addObject:defaultFrames[i]]; }
        else if (i > selectedIndex) { [nextFrames addObject:defaultFrames[i]]; }
        else if (!currFrame       ) {  currFrame = defaultFrames[i];           }
    }
    
    CGFloat prevOffset = 0.0;
    CGFloat nextOffset = 0.0;
    
    if (selectedItem) {
        prevOffset = currFrame ? currFrame.CGRectValue.origin.y - selectorView.scrollView.contentOffset.y                                   : 0.0;
        nextOffset = currFrame ? selectorView.bounds.size.height + selectorView.scrollView.contentOffset.y - currFrame.CGRectValue.origin.y : 0.0;
    }
    
    /* previous */
    for (NSValue *value in prevFrames) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(value.CGRectValue.origin.x,
                                                           value.CGRectValue.origin.y - prevOffset,
                                                           value.CGRectValue.size.width,
                                                           value.CGRectValue.size.height)]];
    }
    
    /* selected */
    if (selectedItem) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(0.0,
                                                           selectorView.scrollView.contentOffset.y,
                                                           currFrame.CGRectValue.size.width,
                                                           currFrame.CGRectValue.size.height)]];
    }
    
    /* next */
    for (NSValue *value in nextFrames) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(value.CGRectValue.origin.x,
                                                           value.CGRectValue.origin.y + nextOffset,
                                                           value.CGRectValue.size.width,
                                                           value.CGRectValue.size.height)]];
    }
    
    return out;
}

- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView {
    return CGSizeMake(selectorView.scrollView.contentSize.width,
                      MAX(selectorView.bounds.size.height, selectorView.adjustedContentHeight));
}

- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView {
    /* 1. calculate relative scroll positions for restoring after ex. rotation
     * - active: returns relative location on screen -> position before activation (relative to screen) */
    CGPoint scrollPosition = [self.class referenceRelativeScrollPositionInSelectorView:selectorView];
    
    /* 2. calculate content height and origins - needed before scroll position adjusting, because it uses the info of the new positions */
    [selectorView calculateAndUpdateDimensions];
    
    /* 3. adjust scroll positions for changed layout */
    [self.class adjustScrollPositionToReferenceRelativeScrollViewPosition:scrollPosition inSelectorView:selectorView];
}

#pragma mark - adjust scroll positions for layout
+ (CGPoint)referenceRelativeScrollPositionInSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@(selectorView.scrollInfo.activeInterfaceOrientation)];
    MZSelectorItem *item = [selectorView.items selectedItem];
    
    return item ?
        [data relativePositionInScrollViewOfAbsolutePositionInScrollContent:item.defaultOrigin]: /* active */
        CGPointZero;                                                                             /* inactive */
}

+ (void)adjustScrollPositionToReferenceRelativeScrollViewPosition:(CGPoint)position inSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    MZSelectorItem *item = [selectorView.items selectedItem];
    
    if (item) {
        selectorView.scrollView.contentOffset = [data contentOffsetOfRelativeScrollViewPosition:position
                                                    inRelationToAbsolutePositionInScrollContent:item.defaultOrigin];
    }
}

@end
