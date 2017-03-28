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
#import "MZSelectorViewReusableViewItemHandler.h"
#import "MZScrollInfo.h"
#import "CALayer+Anchor.h"

@interface MZSelectorView () <UIScrollViewDelegate, MZSelectorItemDelegate> {
    UIView *_contentView;
    NSLayoutConstraint *_contentConstraintHeight;
    NSMutableArray<MZSelectorItem *> *_items;
    MZScrollInfo *_scrollInfo;
    UITapGestureRecognizer *_tapGestureRecognizer;
    
    MZSelectorViewHandlerController *_actionHandlerController;
    
    MZSelectorViewReusableViewItemHandler *_reusableHandler;
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
- (NSString*)activeSelectionState {
    return [_actionHandlerController.activeHandler.class name];
}

- (MZSelectorViewItem*)selectedViewItem {
    MZSelectorItem *item = _items ? [_items selectedItem] : nil;
    return item ? item.item : nil;
}

- (nullable __kindof MZSelectorViewItem *)viewItemAtIndex:(NSUInteger)index {
    NSUInteger numberOfItems = self.numberOfItems;
    return index < numberOfItems && _items.count == numberOfItems ?
        _items[index].item :
        nil;
}

- (NSUInteger)indexOfViewItem:(MZSelectorViewItem * _Nonnull)item {
    return [_items indexOfObjectPassingTest:^BOOL(MZSelectorItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return item && obj.hasItem && obj.item == item;
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

- (void)setDataSource:(id<MZSelectorViewDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadData];
    }
}

- (void)setDelegate:(id<MZSelectorViewDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        [self reloadView];
    }
}

- (void)setLayout:(id<MZSelectorViewDelegateLayout>)layout {
    if (_layout != layout) {
        _layout = layout;
        [self reloadView];
    }
}

#pragma mark - MZSelectorItemDelegate
- (MZSelectorViewItem*)createSelectorViewItemForSelectorItem:(MZSelectorItem*)item {
    MZSelectorViewItem *out = nil;
    if (_dataSource) {
        NSUInteger index = [_items indexOfObject:item];
        if (index != NSNotFound) {
            out = [_dataSource selectorView:self viewItemAtIndex:index];
            
            NSAssert([out isKindOfClass:MZSelectorViewItem.class], @"Unsupported Item type!");
            
            out.selectorView = self;
            
            [self addViewItemToScrollView:out atIndex:index];
        }
    }
    return out;
}

- (void)addViewItemToScrollView:(MZSelectorViewItem*)view atIndex:(NSUInteger)index {
    MZSelectorItem *nextItem = nil;
    MZSelectorItem *prevItem = nil;
    
    /* ToDo: find next closest item -> move to function */
    NSInteger nextIndex = index, prevIndex = index;
    while (!nextItem && !prevItem && (prevIndex >= 0 || nextIndex < _items.count)) {
        if (prevIndex >= 0          ) { MZSelectorItem *tmp = _items[prevIndex--]; prevItem = tmp.hasItem ? tmp : prevItem; }
        if (nextIndex < _items.count) { MZSelectorItem *tmp = _items[nextIndex++]; nextItem = tmp.hasItem ? tmp : nextItem; }
    }
    
    /**/ if (nextItem && nextItem.hasItem) { [_scrollView insertSubview:view belowSubview:nextItem.item]; }
    else if (prevItem && prevItem.hasItem) { [_scrollView insertSubview:view aboveSubview:prevItem.item]; }
    else                                   { [_scrollView addSubview:view];                               }
}

- (void)displayStatusChangedOfSelectorItem:(MZSelectorItem*)item {
    NSUInteger index = [_items indexOfObject:item];
    if (index != NSNotFound) {
        [self resetItemTransform:item];
        /**/ if ( item.displaying) { /* Show */
            [self loadAndDisplayItem:item];
            if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willDisplayViewItem:atIndex:)]) {
                [_delegate selectorView:self willDisplayViewItem:item.item atIndex:index];
            }
            [item.item layoutIfNeeded];
        }
        else if (!item.displaying) { /* Hide */
            if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didEndDisplayingViewItem:atIndex:)]) {
                [_delegate selectorView:self didEndDisplayingViewItem:item.item atIndex:index];
            }
            [item resetItem];
        }
    }
}

#pragma mark - configure
- (BOOL)reloadData {
    BOOL out = _actionHandlerController.idle; /* reload only if idle */
    if (out) {
        [self layoutViews   ];
        [self reloadAllItems];
        [self reloadView    ];
        /* ToDo: try to adjust content offset */
    }
    return out;
}

- (void)reloadView {
    [self resetAllItemTransforms];
    [self updateLayout          ];
    [self handleScrollChange    ];
}

#pragma mark - view item activation/deactivation
- (BOOL)activateViewItemAtIndex:(NSUInteger)index {
    return [_actionHandlerController activateHandlerWithName:kActivationHandlerName
                                        inSelectorView:self
                                     withSelectedIndex:index];
}

- (BOOL)deactivateActiveViewItem {
    return [_actionHandlerController activateHandlerWithName:kDefaultHandlerName
                                        inSelectorView:self
                                     withSelectedIndex:NSNotFound];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleScrollChange];
}

- (void)checkItemDisplayingStates {
    if (self.hasViewSize) {
        for (MZSelectorItem *item in _items) {
            if ((!item.displaying &&  [self isItemDisplaying:item])     /* Show */
             || ( item.displaying && ![self isItemDisplaying:item])) {  /* Hide */
                [item toggleDisplaying];
            }
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
    
    /* ToDo: improve !!! */
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

@implementation MZSelectorView(Reusable)

- (void)registerClass:(Class _Nonnull)viewItemClass forViewItemReuseIdentifier:(NSString * _Nonnull)identifier {
    [_reusableHandler registerClass:viewItemClass forViewItemReuseIdentifier:identifier];
}

- (__kindof MZSelectorViewItem * _Nullable)dequeueReusableViewItemWithIdentifier:(NSString * _Nonnull)identifier {
    return [_reusableHandler dequeueReusableViewItemWithIdentifier:identifier];
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
    _actionHandlerController = [[MZSelectorViewHandlerController alloc] initWithIdleHandler:  [MZSelectorViewDefaultHandler    new]
                                                                       andSelectionHandlers:@[[MZSelectorViewActivationHandler new]]];
    _reusableHandler = [MZSelectorViewReusableViewItemHandler new];
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

- (BOOL)hasViewSize {
    return !CGSizeEqualToSize(self.bounds.size, CGSizeZero);
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
    NSUInteger   numberOfItems   = self.numberOfItems;
    UIEdgeInsets itemInsets      = self.itemInsets;
    CGFloat      viewHeight      = self.bounds.size.height;
    
    return viewHeight < self.adjustedContentHeight ?
        self.minimalItemDistance :
        (numberOfItems > 0 ?
            MAX(0, (viewHeight - itemInsets.bottom - itemInsets.top) / numberOfItems) :
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

- (BOOL)transformItems:(NSArray<MZSelectorItem*>*)items {
    BOOL out = items.count > 0;
    for (NSUInteger i = 0; i < items.count; ++i) {
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
    BOOL out = self.hasViewSize;
    if (out) {
        NSArray<NSValue*> *frames = self.calculatedFrames;
        for (NSUInteger i = 0; i < items.count; ++i) {
            NSUInteger index = [_items indexOfObject:items[i]];
            if (index != NSNotFound && index < frames.count && items[i].hasItem) {
                items[i].item.frame = frames[index].CGRectValue;
            }
        }
    }
    return out;
}

- (void)adjustContentOffsetForAppliedRotation {
    [self.activeHandler handleRotationOfSelectorView:self];
    [_scrollInfo updateInterfaceOrientation];
}

- (void)updateLayout {
    [self calculateAndUpdateDimensions];
    [self calculateAndUpdateFrames    ];
}

- (void)calculateAndUpdateDimensions {
    [self calculateAndUpdateContentHeight];
    [self calculateAndUpdateItemOrigins  ];
    [self calculateAndAdjustContentOffset];
}

- (void)calculateAndUpdateFrames {
    [self layoutDisplayingItems];
    [self layoutViews          ];
}

- (void)layoutViews {
    UIView *view = self.superview ?
        self.superview :
        self;
    
    [view layoutIfNeeded];
}

- (void)loadAndDisplayItem:(MZSelectorItem*)item {
    if (item && [item loadItemIfNeeded]) {
        [self layoutItems:@[item]];
    }
}

#pragma mark - properties
- (NSArray<NSValue*>*)calculatedFrames {
    return [self.activeHandler calculatedFramesInSelectorView:self];
}

- (NSArray<NSValue*>*)calculatedDefaultOrigins {
    NSMutableArray<NSValue*> *out = [NSMutableArray array];
    
    NSUInteger numberOfItems = self.numberOfItems;
    CGFloat itemDistance = self.adjustedItemDistance;
    CGFloat y = self.itemInsets.top;
    
    BOOL status = numberOfItems > 0 && itemDistance > 0.1;
    for (NSUInteger i = 0; i < numberOfItems; ++i) {
        y += i == 0 ? 0 : itemDistance;
        [out addObject:[NSValue valueWithCGPoint:CGPointMake(0,status ? y : 0)]];
    }
    
    return out;
}

#pragma mark - Layout Private
- (void)calculateAndUpdateContentHeight {
    _scrollView.contentSize = [self.activeHandler calculatedContentSizeOfSelectorView:self];
    self.contentHeight = _scrollView.contentSize.height;
}

- (void)calculateAndUpdateItemOrigins {
    NSArray<NSValue*> *origins = self.calculatedDefaultOrigins;
    for (NSUInteger i = 0; i < origins.count; ++i) {
        _items[i].defaultOrigin = origins[i].CGPointValue; /* updates frame */
    }
}

- (void)calculateAndAdjustContentOffset {
    if ([self.activeHandler respondsToSelector:@selector(adjustedContentOffsetOfSelectorView:)]) {
        _scrollView.contentOffset = [self.activeHandler adjustedContentOffsetOfSelectorView:self];
    }
}

@end

@implementation MZSelectorView(ShowHide)

static const CGFloat kItemShowDistanceFromEdge = 40.0;
static const CGFloat kItemHideDistanceFromEdge = 60.0;

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
        CGRect itemFrame = CGRectMake(item.defaultOrigin.x,
                                      item.defaultOrigin.y,
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
    return _actionHandlerController.activeHandler;
}

- (NSMutableArray<MZSelectorItem *> *)items {
    return _items;
}

- (MZScrollInfo *)scrollInfo {
    return _scrollInfo;
}

- (void)handleScrollChange {
    [self checkItemDisplayingStates];
    [self transformDisplayingItems ];
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

