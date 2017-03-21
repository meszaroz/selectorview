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
- (MZSelectorViewItem * _Nonnull)selectorView:(MZSelectorView * _Nonnull)selectorView itemAtIndex:(NSUInteger)index;

@end

@protocol MZSelectorViewDelegate<NSObject>

@optional
/*
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willDisplayItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didEndDisplayingItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index;
*/
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willActivateItemAtIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView willDeactivateItemAtIndex:(NSUInteger)index;

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didActivateItemAtIndex:(NSUInteger)index;
- (void)selectorView:(MZSelectorView * _Nonnull)selectorView didDeactivateItemAtIndex:(NSUInteger)index;

@end

@protocol MZSelectorViewDelegateLayout<NSObject>

@optional

- (CGFloat)minimalItemDistanceInSelectorView:(MZSelectorView * _Nonnull)selectorView;

- (CGFloat)   topInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView;
- (CGFloat)bottomInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView;

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView transformItemContentView:(UIView * _Nonnull)view atIndex:(NSUInteger)index andPoint:(CGPoint)point;

@end

@interface MZSelectorView : UIView

@property (strong, nonatomic, nullable) UIScrollView *scrollView;

@property (weak, nonatomic, nullable) id<MZSelectorViewDataSource    > dataSource;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegate      > delegate;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegateLayout> layout;

@property (strong, nonatomic, readonly, nullable) MZSelectorViewItem *activeItem;
@property (nonatomic, readonly) NSUInteger numberOfItems;
@property (nonatomic, readonly) CGFloat minimalItemDistance;
@property (nonatomic, readonly) UIEdgeInsets itemInsets;

- (BOOL)activateItemAtIndex:(NSUInteger)index;
- (BOOL)deactivateActiveItem;

- (nullable __kindof MZSelectorViewItem *)itemAtIndex:(NSUInteger)index;

- (CGPoint)originOfItem:(MZSelectorViewItem * _Nonnull)item;

- (void)reloadData;

@end
