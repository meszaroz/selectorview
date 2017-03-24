//
//  MZSelectorViewActivationHandler.m
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewActivationHandler.h"
#import "MZSelectorViewItem.h"
#import "MZSelectorItem.h"
#import "MZScrollInfo.h"

@interface NSArray(Item)

- (MZSelectorItem*)selectedItem;
- (MZSelectorItem*)activeItem;
- (NSUInteger)indexOfSelectedItem;
- (NSUInteger)indexOfActiveItem;

@end

@implementation MZSelectorViewActivationHandler

- (NSArray<NSValue*>*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    NSUInteger      selectedIndex = [selectorView.items indexOfSelectedItem];
    MZSelectorItem *selectedItem  = [selectorView.items selectedItem       ];
    
    NSMutableArray<MZSelectorItem*> *prevItems = [NSMutableArray array];
    NSMutableArray<MZSelectorItem*> *nextItems = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < selectorView.items.count; ++i) {
        /**/ if (i < selectedIndex) { [prevItems addObject:selectorView.items[i]]; }
        else if (i > selectedIndex) { [nextItems addObject:selectorView.items[i]]; }
    }
    
    CGFloat prevOffset = 0.0;
    CGFloat nextOffset = 0.0;
    
    if (selectedItem) {
        MZSelectorViewItem * selectedViewItem = selectedItem.item;
        MZSelectorViewItem *firstNextViewItem = nextItems.count > 0 && nextItems.firstObject.hasItem ?
            nextItems.firstObject.item :
            nil;
        
        prevOffset = [selectedViewItem convertPoint:selectedViewItem.bounds.origin toView:selectorView].y;
        nextOffset = firstNextViewItem ?
            selectorView.bounds.size.height - [selectedViewItem convertPoint:firstNextViewItem.bounds.origin toView:selectorView].y :
            0;
    }
    
    /* previous */
    for (MZSelectorItem *item in prevItems) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(item.origin.x,
                                                           item.origin.y - prevOffset,
                                                           selectorView.bounds.size.width,
                                                           selectorView.bounds.size.height)]];
    }
    
    /* selected */
    if (selectedItem) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(0.0,
                                                           selectorView.scrollView.contentOffset.y,
                                                           selectorView.bounds.size.width,
                                                           selectorView.bounds.size.height)]];
    }
    
    /* next */
    for (MZSelectorItem *item in nextItems) {
        [out addObject:[NSValue valueWithCGRect:CGRectMake(item.origin.x,
                                                           item.origin.y + nextOffset,
                                                           selectorView.bounds.size.width,
                                                           selectorView.bounds.size.height)]];
    }
    
    return out;
}

- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView {
    /* 1. calculate relative scroll positions for restoring after ex. rotation
     * - active: returns relative location on screen -> position before activation (relative to screen) */
    CGPoint scrollPosition = [self.class referenceRelativeScrollPositionInSelectorView:selectorView];
    
    /* 2. calculate content height and origins - needed before scroll position adjusting, because it uses the info of the new positions */
    [selectorView calculateDimensions];
    
    /* 3. adjust scroll positions for changed layout */
    [self.class adjustScrollPositionToReferenceRelativeScrollViewPosition:scrollPosition inSelectorView:selectorView];
}

#pragma mark - adjust scroll positions for layout
+ (CGPoint)referenceRelativeScrollPositionInSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@(selectorView.scrollInfo.activeInterfaceOrientation)];
    MZSelectorItem *item = [selectorView.items activeItem];
    
    return item ?
        [data relativePositionInScrollViewOfAbsolutePositionInScrollContent:item.origin]: /* active */
        CGPointZero;                                                                      /* inactive */
}

+ (void)adjustScrollPositionToReferenceRelativeScrollViewPosition:(CGPoint)position inSelectorView:(MZSelectorView *)selectorView {
    MZScrollInfoData *data = selectorView.scrollInfo.data[@([[UIApplication sharedApplication] statusBarOrientation])];
    MZSelectorItem *item = [selectorView.items activeItem];
    
    if (item) {
        selectorView.scrollView.contentOffset = [data contentOffsetOfRelativeScrollViewPosition:position
                                                    inRelationToAbsolutePositionInScrollContent:item.origin];
    }
}

@end

@implementation MZSelectorViewActivationHandler(Interface)

- (MZSelectorItem*)activeItemInSelectorView:(MZSelectorView *)selectorView {
    return selectorView && selectorView.items ?
        [selectorView.items activeItem] :
        nil;
}

static const CGFloat kDefaultAnimationDuration = 0.5;

#pragma mark - view item activation/deactivation
- (BOOL)activateViewItemAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView *)selectorView {
    BOOL out = selectorView && selectorView.superview && ![selectorView.items activeItem] && index < selectorView.items.count;
    
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

- (BOOL)deactivateActiveViewItemInSelectorView:(MZSelectorView *)selectorView {
    return [self deactivateViewItemAtIndex:[selectorView.items indexOfActiveItem] inSelectorView:selectorView];
}

- (BOOL)deactivateViewItemAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView *)selectorView {
    BOOL out = selectorView && selectorView.superview && [self isItemActiveAtIndex:index inSelectorView:selectorView];
    
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
                             [selectorView updateLayout];
                             [selectorView transformItem:selectorView.items[index]];
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

- (BOOL)isItemActiveAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView *)selectorView {
    return selectorView && index < selectorView.items.count && selectorView.items[index].item.active;
}

@end

@implementation NSArray(Item)

- (MZSelectorItem*)selectedItem {
    NSUInteger index = [self indexOfSelectedItem];
    return index != NSNotFound ? self[index] : nil;
}

- (NSUInteger)indexOfSelectedItem {
    return [self indexOfItemWithBlock:^BOOL(MZSelectorViewItem *viewItem) { return viewItem.isSelected; }];
}

- (MZSelectorItem*)activeItem {
    NSUInteger index = [self indexOfActiveItem];
    return index != NSNotFound ? self[index] : nil;
}

- (NSUInteger)indexOfActiveItem {
    return [self indexOfItemWithBlock:^BOOL(MZSelectorViewItem *viewItem) { return viewItem.isActive;   }];
}

- (NSUInteger)indexOfItemWithBlock:(BOOL(^)(MZSelectorViewItem* viewItem))block {
    return [self indexOfObjectPassingTest:^BOOL(MZSelectorItem*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return block && obj.hasItem && block(obj.item);
    }];
}

@end
