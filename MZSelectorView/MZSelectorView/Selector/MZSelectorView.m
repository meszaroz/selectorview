//
//  MZSelectorView.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "PureLayout.h"
#import "MZSelectorView_p.h"
#import "MZSelectorView.h"
#import "MZSelectorViewItem_p.h"
#import "MZSelectorViewItem.h"
#import "MZSelectorItem.h"
#import "MZSelectorViewHandlerController.h"
#import "MZScrollInfo.h"
#import "CALayer+Anchor.h"

@interface MZSelectorView () <UIScrollViewDelegate, MZSelectorItemDelegate> {
    UIView *_contentView;
    NSLayoutConstraint *_contentConstraintHeight;
    NSMutableArray<MZSelectorItem *> *_items;
    MZScrollInfo *_scrollInfo;
    UITapGestureRecognizer *_tapGestureRecognizer;
    
    MZSelectorViewHandlerController *_handlerController;
}
@end

static const UIEdgeInsets kDefaultItemInsets = { 40.0, 0.0, 80.0, 0.0 };

@implementation MZSelectorView

#pragma mark - initialize
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self setupComponents];
    [self reloadData     ];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollInfo deregisterDefaultObservers];
}

#pragma mark - functions
- (MZSelectorViewItem*)selectedViewItem {
    MZSelectorItem *item = _items ? [_items selectedItem] : nil;
    return item ? item.item : nil;
}

- (CGPoint)originOfViewItem:(MZSelectorViewItem * _Nonnull)item {
    NSInteger index = [self indexOfViewItem:item];
    return index != NSNotFound ?
        _items[index].origin :
        CGPointZero;
}

- (nullable __kindof MZSelectorViewItem *)viewItemAtIndex:(NSUInteger)index {
    NSUInteger numberOfItems = self.numberOfItems;
    return index < numberOfItems && _items.count == numberOfItems ?
        _items[index].item :
        nil;
}

- (NSUInteger)indexOfViewItem:(MZSelectorViewItem * _Nonnull)item {
    return [_items indexOfObjectPassingTest:^BOOL(MZSelectorItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return item && obj.item == item;
    }];
}

- (NSArray<MZSelectorViewItem *> *)displayingViewItems {
    NSMutableArray<MZSelectorViewItem *> *out = [NSMutableArray array];
    for (MZSelectorItem *item in [self displayingItems]) {
        [out addObject:item.item];
    }
    return out;
}

- (NSArray<MZSelectorItem *> *)displayingItems {
    return [_items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MZSelectorItem* _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.displaying;
    }]];
}

#pragma mark - MZSelectorItemDelegate
- (MZSelectorViewItem*)createSelectorViewItemForSelectorItem:(MZSelectorItem*)item {
    MZSelectorViewItem *out = nil;
    if (_dataSource) {
        NSUInteger index = [_items indexOfObject:item];
        if (index != NSNotFound) {
            out = [_dataSource selectorView:self viewItemAtIndex:index];
            out.selectorView = self;
            
            NSAssert([out isKindOfClass:MZSelectorViewItem.class], @"Unsupported Item type!");
            
            [out removeFromSuperview];
            [_scrollView addSubview:out];
        }
    }
    return out;
}

- (void)displayStatusChangedOfSelectorItem:(MZSelectorItem*)item {
    NSUInteger index = [_items indexOfObject:item];
    if (index != NSNotFound) {
        /* 1. Transform to identity -> correct autolayout function */
        [self resetItemTransform:item];
        
        /* 2. Notify delegate of change in displaying status -> optimization possibilities */
        /**/ if ( item.displaying) { /* Show */
            if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willDisplayViewItem:atIndex:)]) {
                [_delegate selectorView:self willDisplayViewItem:item.item atIndex:index];
            }
        }
        else if (!item.displaying) { /* Hide */
            if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didEndDisplayingViewItem:atIndex:)]) {
                [_delegate selectorView:self didEndDisplayingViewItem:item.item atIndex:index];
            }
        }
    
        /* 3. updateLayout if any change */
        [item.item layoutIfNeeded];
    }
}

#pragma mark - configure
- (BOOL)reloadData {
    BOOL out = !_items || ![_items selectedItem]; /* reload only if nothing selected */
    if (out) {
        [self reloadAllItems];
        [self reloadView    ];
        /* ToDo: try to adjust content offset */
    }
    return out;
}

- (void)reloadView {
    [self resetAllItemTransforms];
    [self updateLayout          ];
    [self scrollViewDidScroll:_scrollView];
}

#pragma mark - view item activation/deactivation
- (BOOL)activateViewItemAtIndex:(NSUInteger)index {
    return [_handlerController activateHandlerWithName:kActivationHandlerName
                                        inSelectorView:self
                                     withSelectedIndex:index];
}

- (BOOL)deactivateActiveViewItem {
    return [_handlerController activateHandlerWithName:kDefaultHandlerName
                                        inSelectorView:self
                                     withSelectedIndex:NSNotFound];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self checkItemDisplayingStates];
    [self transformDisplayingItems ];
}

- (void)checkItemDisplayingStates {
    for (MZSelectorItem *item in _items) {
        if ((!item.displaying &&  [self isItemDisplaying:item])     /* Show */
         || ( item.displaying && ![self isItemDisplaying:item])) {  /* Hide */
            [item toggleDisplaying];
        }
    }
}

#pragma mark - orientation change
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    /* execute only once */
    if (_scrollInfo.activeInterfaceOrientation != [[UIApplication sharedApplication] statusBarOrientation]) {
        [self adjustContentOffsetForAppliedRotation];
        [self reloadView];
    }
}

#pragma mark - tap
- (void)tapAction:(UITapGestureRecognizer*)gesture {
    UIView *view = gesture.view;
    view = [view hitTest:[gesture locationInView:view] withEvent:nil];
    
    view = view.superview;
    while (view && ![view isKindOfClass:MZSelectorViewItem.class]) {
        view = view.superview;
    }
    
    NSUInteger index = view ?
        [self indexOfViewItem:(MZSelectorViewItem*)view] :
        NSNotFound;
    
    if (index != NSNotFound) {
        [self activateViewItemAtIndex:index];
    }
}

@end

@implementation MZSelectorView(Setup)

- (void)setupComponents {
    [self setupHandlers             ];
    [self setupOrientationChange    ];
    [self setupTapGuestureRecognizer];
    [self setupScrollView           ];
    [self setupContentView          ];
    [self setupItemList             ];
}

- (void)setupHandlers {
    _handlerController = [[MZSelectorViewHandlerController alloc] initWithIdleHandler:  [MZSelectorViewDefaultHandler    new]
                                                                 andSelectionHandlers:@[[MZSelectorViewActivationHandler new]]];
}

- (void)setupOrientationChange {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)setupTapGuestureRecognizer {
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    _tapGestureRecognizer.numberOfTapsRequired    = 1;
    _tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:_tapGestureRecognizer];
}

- (void)setupScrollView {
    _scrollView = [UIScrollView new];
    _scrollView.delegate = self;
    _scrollView.alwaysBounceVertical = YES;
    [self addSubview:_scrollView];
    [_scrollView autoPinEdgesToSuperviewEdges];
    
    _scrollInfo = [MZScrollInfo new];
    _scrollInfo.scrollView = _scrollView;
    [_scrollInfo registerDefaultObservers];
}

- (void)setupContentView {
    _contentView = [UIView new];
    [_scrollView addSubview:_contentView];
    _contentConstraintHeight = [_contentView autoSetDimension:ALDimensionHeight toSize:0];
    [_contentView autoPinEdgesToSuperviewEdges];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0
                                                      constant:0.0]];
}

- (void)setupItemList {
    _items = [NSMutableArray array];
}

@end

@implementation MZSelectorView(Info)

- (CGFloat)contentHeight {
    return _contentConstraintHeight ?
        _contentConstraintHeight.constant :
        0.0;
}

- (void)setContentHeight:(CGFloat)size {
    if (_contentConstraintHeight) {
        _contentConstraintHeight.constant = size;
    }
}

- (NSUInteger)numberOfItems {
    return _dataSource != nil ?
        [_dataSource numberOfItemsInSelectorView:self] :
        0;
}

- (CGFloat)minimalItemDistance {
    return _layout && [_layout respondsToSelector:@selector(minimalItemDistanceInSelectorView:)] ?
        [_layout minimalItemDistanceInSelectorView:self] :
        MAX(20.0, self.bounds.size.height / 4);
}

- (UIEdgeInsets)itemInsets {
    UIEdgeInsets insets = kDefaultItemInsets;
    if (_layout) {
        if ([_layout respondsToSelector:@selector(topInsetInSelectorView:)]) {
            insets.top    = [_layout    topInsetInSelectorView:self];
        }
        if ([_layout respondsToSelector:@selector(bottomInsetInSelectorView:)]) {
            insets.bottom = [_layout bottomInsetInSelectorView:self];
        }
    }
    return insets;
}

@end

@implementation MZSelectorView(Adjust)

- (CGFloat)adjustedContentHeight {
    NSUInteger   numberOfItems = self.numberOfItems;
    UIEdgeInsets itemInsets    = self.itemInsets;
    
    return numberOfItems > 0 && self.bounds.size.height > 0.1 ?
        itemInsets.top + itemInsets.bottom + (self.minimalItemDistance * (numberOfItems-1)) :
        0;
}

- (CGFloat)adjustedItemDistance {
    NSUInteger   numberOfItems = self.numberOfItems;
    UIEdgeInsets itemInsets    = self.itemInsets;
    CGFloat      viewHeight    = self.bounds.size.height;
    
    return viewHeight < self.adjustedContentHeight ?
        self.minimalItemDistance :
        (numberOfItems > 1 ?
            MAX(0, (viewHeight - itemInsets.bottom - itemInsets.top) / (numberOfItems-1)) :
            0);
}

- (UIEdgeInsets)adjustedItemInsets {
    UIEdgeInsets itemInsets = self.itemInsets;
    if (self.numberOfItems <= 1) {
        itemInsets.bottom = self.bounds.size.height - itemInsets.top;
    }
    return itemInsets;
}

@end

@implementation MZSelectorView(Transform)

- (BOOL)transformAllItems {
    return [self transformItems:_items];
}

- (BOOL)transformDisplayingItems {
    return [self transformItems:[self displayingItems]];
}

/* ToDo: fix  */
- (BOOL)transformItems:(NSArray<MZSelectorItem*>*)items {
    BOOL out = items.count > 0;
    for (NSUInteger i = 0; out && i < items.count; ++i) {
        out &= [self transformItem:items[i]];
    }
    return out;
}

- (BOOL)transformItem:(MZSelectorItem*)item {
    BOOL out = item && item.hasItem
        && _layout && [_layout respondsToSelector:@selector(selectorView:transformContentLayer:inViewItem:atIndex:)];
    if (out) {
        [_layout selectorView:self
        transformContentLayer:item.item.contentView.layer
                   inViewItem:item.item
                      atIndex:[_items indexOfObject:item]];
    }
    return out;
}

@end

@implementation MZSelectorView(Layout)

- (BOOL)layoutAllItems {
    return [self layoutItems:_items];
}

- (BOOL)layoutDisplayingItems {
    return [self layoutItems:[self displayingItems]];
}

- (BOOL)layoutItems:(NSArray<MZSelectorItem*>*)items {
    BOOL out = !CGSizeEqualToSize(self.bounds.size, CGSizeZero);
    if (out) {
        NSArray<NSValue*> *frames = self.calculatedFrames;
        for (NSUInteger i = 0; i < items.count; ++i) {
            NSUInteger index = [_items indexOfObject:items[i]];
            if (index != NSNotFound && index < frames.count/* && [items[i] hasItem]*/) {
                items[i].item.frame = frames[index].CGRectValue;
            }
        }
    }
    return out;
}

/* ToDo */
- (void)adjustContentOffset {
}

- (void)adjustContentOffsetForAppliedRotation {
    [self.activeHandler handleRotationOfSelectorView:self];
    [_scrollInfo updateInterfaceOrientation];
}

- (void)updateLayout {
    [self calculateDimensions     ];
    [self calculateAndUpdateFrames];
    [self layoutViews             ];
}

- (void)calculateDimensions {
    [self calculateAndUpdateContentHeight];
    [self calculateItemOrigins           ];
}

- (void)calculateAndUpdateContentHeight {
    self.contentHeight = MAX(self.bounds.size.height, self.adjustedContentHeight);
    [self layoutViews];
}

- (BOOL)calculateItemOrigins {
    NSUInteger numberOfItems = self.numberOfItems;
    CGFloat itemDistance  = self.adjustedItemDistance;
    CGFloat y = self.itemInsets.top;
    
    BOOL out = numberOfItems > 0 && itemDistance > 0.1;
    
    for (NSUInteger i = 0; i < numberOfItems; ++i) {
        y += i == 0 ? 0 : itemDistance;
        _items[i].origin = CGPointMake(0,out ? y : 0);
    }
    
    return out;
}

- (void)calculateAndUpdateFrames {
    [self layoutAllItems];
}

- (NSArray<NSValue*>*)calculatedFrames {
    return [self.activeHandler calculatedFramesInSelectorView:self];
}

- (void)layoutViews {
    UIView *view = self.superview ?
        self.superview :
        self;
    
    [view layoutIfNeeded];
}

@end

@implementation MZSelectorView(ShowHide)

static const CGFloat kItemShowDistanceFromEdge = 10.0;
static const CGFloat kItemHideDistanceFromEdge = 20.0;

- (CGRect)currentShowFrame {
    return [self currentFrameForEdgeOffset:kItemShowDistanceFromEdge];
}

- (CGRect)currentHideFrame {
    return [self currentFrameForEdgeOffset:kItemHideDistanceFromEdge];
}

- (CGRect)currentFrameForEdgeOffset:(CGFloat)offset {
    return CGRectMake(0,
                      _scrollView.contentOffset.y - offset,
                      self.bounds.size.width,
                      self.bounds.size.height + 2 * offset);
}

- (BOOL)isItemDisplaying:(MZSelectorItem*)item {
    BOOL out = item != nil;
    if (out) {
        CGRect itemFrame = CGRectMake(item.origin.x,
                                      item.origin.y,
                                      self.bounds.size.width,
                                      self.bounds.size.height);
        out = ( item.displaying && CGRectIntersectsRect(self.currentHideFrame, itemFrame))
           || (!item.displaying && CGRectIntersectsRect(self.currentShowFrame, itemFrame));
    }    
    return out;
}

@end

@implementation MZSelectorView(ResetClear)

- (void)reloadAllItems {
    [self   clearAllItems];
    [self prepareAllItems];
}

- (void)clearAllItems {
    [self resetAllItems];
    [_items removeAllObjects];
}

- (BOOL)prepareAllItems {
    BOOL out = _items.count == 0;
    if (out) {
        NSUInteger numberOfItems = self.numberOfItems;
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            [_items addObject:[MZSelectorItem itemWithDelegate:self]];
        }
    }
    return out;
}

- (void)resetAllItems {
    [self resetItems:_items];
}

- (void)resetItems:(NSArray<MZSelectorItem*>*)items {
    for (MZSelectorItem *item in items) {
        [item reset];
    }
}

- (void)resetContentOffset {
    self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, 0.0);
}

- (void)resetAllItemTransforms {
    [self resetItemTransforms:_items];
}

- (void)resetDisplayingItemTransforms {
    [self resetItemTransforms:[self displayingItems]];
}

- (void)resetItemTransforms:(NSArray<MZSelectorItem*>*)items {
    for (MZSelectorItem *item in items) {
        [self resetItemTransform:item];
    }
}

- (void)resetItemTransform:(MZSelectorItem*)item {
    if (item && item.hasItem && item.item.superview == self.scrollView) {
        item.item.contentView.layer.transform = CATransform3DIdentity;
    }
}

@end

@implementation MZSelectorView(Private)

- (id<MZSelectorViewActionHandler>)activeHandler {
    return _handlerController.activeHandler;
}

- (NSMutableArray<MZSelectorItem *> *)items {
    return _items;
}

- (MZScrollInfo *)scrollInfo {
    return _scrollInfo;
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

- (NSUInteger)indexOfItemWithBlock:(BOOL(^)(MZSelectorViewItem* viewItem))block {
    return [self indexOfObjectPassingTest:^BOOL(MZSelectorItem*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return block && obj.hasItem && block(obj.item);
    }];
}

@end

