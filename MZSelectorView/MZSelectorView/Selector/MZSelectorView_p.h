//
//  MZSelectorView.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZSelectorView.h"

@class MZSelectorItem;
@class MZSelectorViewItem;
@class MZScrollInfo;

@protocol MZSelectorViewActionHandler<NSObject>

+ (NSString*)name;

- (NSArray<NSValue*>*)calculatedFramesInSelectorView:(MZSelectorView *)selectorView;
- (CGSize)calculatedContentSizeOfSelectorView:(MZSelectorView *)selectorView;
- (void)handleRotationOfSelectorView:(MZSelectorView *)selectorView;

@optional
- (CGPoint)adjustedContentOffsetOfSelectorView:(MZSelectorView *)selectorView;
- (BOOL)selectorView:(MZSelectorView *)selectorView activateItemAtIndex:(NSUInteger)index;
- (BOOL)deactivateSelectedItemInSelectorView:(MZSelectorView *)selectorView;

@end

@interface NSArray(Item)

- (MZSelectorItem*)selectedItem;
- (NSUInteger)indexOfSelectedItem;

@end

@interface MZSelectorView(Private)

@property (strong, nonatomic, readonly) id<MZSelectorViewActionHandler> activeHandler;
@property (strong, nonatomic, readonly) NSMutableArray<MZSelectorItem *> *items; /* mutable, because of (later) delete and insert possibilities */
@property (strong, nonatomic, readonly) MZScrollInfo *scrollInfo;

- (void)handleScrollChange;

@end

@interface MZSelectorView(ResetClear)

- (void)reloadAllItems;
- (void)clearAllItems;
- (BOOL)prepareAllItems;

- (void)resetAllItems;
- (void)resetItems:(NSArray<MZSelectorItem*>*)items;
- (void)resetContentOffset;
- (void)resetAllItemTransforms;
- (void)resetDisplayingItemTransforms;
- (void)resetItemTransforms:(NSArray<MZSelectorItem*>*)items;
- (void)resetItemTransform:(MZSelectorItem*)item;

@end

@interface MZSelectorView(ShowHide)

- (CGRect)currentShowFrame;
- (CGRect)currentHideFrame;
- (CGRect)currentFrameForEdgeOffset:(CGFloat)offset;
- (BOOL)isItemDisplaying:(MZSelectorItem*)item;

@end

@interface MZSelectorView(Setup)

- (void)setupComponents;
- (void)setupOrientationChange;
- (void)setupTapGuestureRecognizer;
- (void)setupScrollView;
- (void)setupContentView;
- (void)setupItemList;

@end

@interface MZSelectorView(Info)

@property (nonatomic          ) CGFloat      contentHeight;
@property (nonatomic, readonly) UIEdgeInsets itemInsets;
@property (nonatomic, readonly) BOOL hasViewSize;

@end

@interface MZSelectorView(Adjust)

@property (nonatomic, readonly) CGFloat      adjustedContentHeight;
@property (nonatomic, readonly) CGFloat      adjustedItemDistance;
@property (nonatomic, readonly) UIEdgeInsets adjustedItemInsets; /* unused */

@end

@interface MZSelectorView(Transform)

- (BOOL)transformAllItems;
- (BOOL)transformDisplayingItems;
- (BOOL)transformItems:(NSArray<MZSelectorItem*>*)items;
- (BOOL)transformItem:(MZSelectorItem*)item;

@end

@interface MZSelectorView(Layout)

@property (nonatomic, readonly) NSArray<NSValue*> *calculatedDefaultOrigins;
@property (nonatomic, readonly) NSArray<NSValue*> *calculatedFrames;

- (void)updateLayout;
- (BOOL)layoutAllItems;
- (BOOL)layoutDisplayingItems;
- (BOOL)layoutItems:(NSArray<MZSelectorItem*>*)items;
- (void)layoutViews;

- (void)calculateAndUpdateDimensions;
- (void)adjustContentOffsetForAppliedRotation;

- (void)loadAndDisplayItem:(MZSelectorItem*)item;

@end

