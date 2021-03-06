//
//  MZSelectorView.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MZSelectorView;
@class MZSelectorViewItem;

@protocol MZSelectorViewDataSource<NSObject>

@required

- (NSUInteger)numberOfItemsInSelectorView:(MZSelectorView * _Nonnull)selectorView;
- (MZSelectorViewItem * _Nonnull)selectorView:(MZSelectorView * _Nonnull)selectorView viewItemAtIndex:(NSUInteger)index;

@end

@protocol MZSelectorViewDelegate<NSObject>

@optional

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willDisplayViewItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didEndDisplayingViewItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index;

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willActivateViewItemAtIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willDeactivateViewItemAtIndex:(NSUInteger)index;

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didActivateViewItemAtIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didDeactivateViewItemAtIndex:(NSUInteger)index;

@end

@protocol MZSelectorViewDelegateLayout<NSObject>

@optional

- (CGFloat)minimalItemDistanceInSelectorView:(MZSelectorView * _Nonnull)selectorView;

- (CGFloat)   topInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView;
- (CGFloat)bottomInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView;

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView transformContentLayer:(CALayer* _Nonnull)layer inViewItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index;

@end

/* ToDo: add deque reusable views */
@interface MZSelectorView : UIView

@property (strong, nonatomic, nullable) UIScrollView *scrollView;

@property (weak, nonatomic, nullable) id<MZSelectorViewDataSource    > dataSource;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegate      > delegate;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegateLayout> layout;

@property (        nonatomic, readonly, nonnull ) NSString *activeSelectionState; /* activate, reorder, insert, delete */
@property (strong, nonatomic, readonly, nullable) MZSelectorViewItem *selectedViewItem;
@property (strong, nonatomic, readonly, nonnull ) NSArray<MZSelectorViewItem *> *displayingViewItems;

@property (nonatomic, readonly) NSUInteger numberOfItems;
@property (nonatomic, readonly) CGFloat    minimalItemDistance;

- (BOOL)activateViewItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (BOOL)deactivateActiveViewItemAnimated:(BOOL)animated;

- (nullable __kindof MZSelectorViewItem *)viewItemAtIndex:(NSUInteger)index;

- (BOOL)reloadData;

@end

@interface MZSelectorView(Reusable)

- (void)registerClass:(Class _Nonnull)viewItemClass forViewItemReuseIdentifier:(NSString * _Nonnull)identifier;

- (__kindof MZSelectorViewItem * _Nullable)dequeueReusableViewItemWithIdentifier:(NSString * _Nonnull)identifier;

@end
