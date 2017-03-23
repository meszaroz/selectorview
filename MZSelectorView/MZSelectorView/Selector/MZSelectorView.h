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

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView transformViewItemContentView:(UIView * _Nonnull)view atIndex:(NSUInteger)index andPoint:(CGPoint)point;

@end

@interface MZSelectorView : UIView

@property (strong, nonatomic, nullable) UIScrollView *scrollView;

@property (weak, nonatomic, nullable) id<MZSelectorViewDataSource    > dataSource;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegate      > delegate;
@property (weak, nonatomic, nullable) id<MZSelectorViewDelegateLayout> layout;

@property (strong, nonatomic, readonly, nullable)         MZSelectorViewItem    *activeViewItem;
@property (strong, nonatomic, readonly, nonnull ) NSArray<MZSelectorViewItem *> *displayingViewItems;

@property (nonatomic, readonly) NSUInteger   numberOfItems;
@property (nonatomic, readonly) CGFloat      minimalItemDistance;
@property (nonatomic, readonly) UIEdgeInsets itemInsets;

- (BOOL)activateViewItemAtIndex:(NSUInteger)index;
- (BOOL)deactivateActiveViewItem;

- (nullable __kindof MZSelectorViewItem *)viewItemAtIndex:(NSUInteger)index;

- (CGPoint)originOfViewItem:(MZSelectorViewItem * _Nonnull)viewItem;

- (BOOL)reloadData;

@end
