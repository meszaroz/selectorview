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
#import "MZScrollInfo.h"
#import "CALayer+Anchor.h"

@interface MZSelectorView(ResetClear)

- (void)clearAllItems;
- (void)resetAllItems;
- (void)resetItems:(NSArray<MZSelectorItem*>*)items;
- (void)resetContentOffset;
- (void)resetAllItemTransforms;
- (void)resetItemTransforms:(NSArray<MZSelectorItem*>*)items;

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
@property (nonatomic, readonly) NSUInteger   numberOfItems;
@property (nonatomic, readonly) CGFloat      minimalItemDistance;
@property (nonatomic, readonly) UIEdgeInsets itemInsets;

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
- (BOOL)transformItem:(MZSelectorViewItem*)item atPoint:(CGPoint)point;

@end

@interface MZSelectorView(Position)

- (BOOL)positionAllItems;
- (BOOL)positionDisplayingItems;
- (BOOL)positionItems:(NSArray<MZSelectorItem*>*)items;

@end


@interface MZSelectorView () <UIScrollViewDelegate, MZSelectorItemDelegate> {
    UIView *_contentView;
    
    NSLayoutConstraint *_contentConstraintHeight;
    
    NSMutableArray<MZSelectorItem *> *_items;
    
    MZScrollInfo *_scrollInfo;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

static const CGFloat kDefaultAnimationDuration = 0.5;
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
- (CGPoint)originOfViewItem:(MZSelectorViewItem * _Nonnull)item {
    NSInteger index = [self indexOfViewItem:item];
    return index != NSNotFound ?
        _items[index].origin :
        CGPointZero;
}

- (nullable __kindof MZSelectorViewItem *)viewItemAtIndex:(NSUInteger)index {
    MZSelectorViewItem *out = nil;
    
    if (index < self.numberOfItems) {
        if (_items.count < index) {
            [self prepareItems];
        }
        out = _items[index].item;
    }
    
    return out;
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
        if (item.hasItem) {
            item.item.contentView.layer.transform = CATransform3DIdentity;
        }
        
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
- (void)reloadData {
    [self clearAllItems      ];
    [self prepareItems       ];
    [self calculatePositions ];
    [self adjustContentOffset];
    [self setupItems         ];
    
    [self scrollViewDidScroll:_scrollView];
}

- (BOOL)prepareItems {
    BOOL out = _items.count == 0;
    if (out) {
        NSUInteger numberOfItems = self.numberOfItems;
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            [_items addObject:[MZSelectorItem itemWithDelegate:self]];
        }
    }
    return out;
}

- (void)calculatePositions {
    [self updateLayout];
    
    [self calculateAndUpdateContentHeight];
    [self calculateItemOrigins           ];
}

- (void)calculateAndUpdateContentHeight {
    [self setContentHeight:MAX(self.bounds.size.height,
                               self.adjustedContentHeight)];
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

/* ToDo */
- (void)adjustContentOffset {
}

- (void)setupItems {
    [self positionAllItems      ]; /* ToDo: loades all items -> no lazy load */
    [self resetAllItemTransforms];
    [self transformAllItems     ];
}

- (void)updateLayout {
    UIView *view = self.superview ?
        self.superview :
        self;
    [view layoutIfNeeded];
}

#pragma mark - view item activation/deactivation
- (BOOL)activateViewItemAtIndex:(NSUInteger)index {
    BOOL out = self.superview && !_activeViewItem && index < _items.count;
    
    if (out) {
        _scrollView.scrollEnabled = NO;
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willActivateViewItemAtIndex:)]) {
            [_delegate selectorView:self willActivateViewItemAtIndex:index];
        }
        
        MZSelectorViewItem *item = _items[index].item;
        item.selected = YES;
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [self repositionItemsAroundActiveViewItem:item];
                         }
                         completion:^(BOOL finished) {
                             item.active = YES;
                             [displayLink invalidate];
                             
                             if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didActivateViewItemAtIndex:)]) {
                                 [_delegate selectorView:self didActivateViewItemAtIndex:index];
                             }
                         }];
    }
    
    return out;
}

- (void)repositionItemsAroundActiveViewItem:(MZSelectorViewItem*)item {
    NSUInteger index = [self indexOfViewItem:item];
    
    if (index != NSNotFound) {
        NSMutableArray<MZSelectorViewItem*> *prevItems = [NSMutableArray array];
        NSMutableArray<MZSelectorViewItem*> *nextItems = [NSMutableArray array];
        
        for (NSUInteger i = 0; i < _items.count; ++i) {
            /**/ if (i < index) { [prevItems addObject:_items[i].item]; }
            else if (i > index) { [nextItems addObject:_items[i].item]; }
        }
        
        CGFloat prevOffset = [item convertPoint:item.bounds.origin toView:self].y;
        CGFloat nextOffset = nextItems.count > 0 ?
            self.bounds.size.height - [item convertPoint:nextItems.firstObject.bounds.origin toView:self].y:
            0;
        
        /* reposition effected items */
        for (MZSelectorViewItem *item in prevItems) { item.layer.position = CGPointMake(item.layer.position.x, item.layer.position.y - prevOffset); }
        for (MZSelectorViewItem *item in nextItems) { item.layer.position = CGPointMake(item.layer.position.x, item.layer.position.y + nextOffset); }
        
        /* resize active item */
        item.frame = CGRectMake(0, _scrollView.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
        item.contentView.layer.transform = CATransform3DIdentity;
    }
}

- (BOOL)deactivateActiveViewItem {
    return [self deactivateViewItemAtIndex:[self indexOfViewItem:_activeViewItem]];
}

- (BOOL)deactivateViewItemAtIndex:(NSUInteger)index {
    BOOL out = self.superview && [self isItemActiveAtIndex:index];
    
    if (out) {
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willDeactivateViewItemAtIndex:)]) {
            [_delegate selectorView:self willDeactivateViewItemAtIndex:index];
        }
        
        MZSelectorViewItem *item = _items[index].item;
        item.active = NO;

        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [self setupItems];
                         }
                         completion:^(BOOL finished) {
                             item.selected = NO;
                             _scrollView.scrollEnabled = YES;
                             [displayLink invalidate];
                             
                             if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didDeactivateViewItemAtIndex:)]) {
                                 [_delegate selectorView:self didDeactivateViewItemAtIndex:index];
                             }
                         }];
    }

    return out;
}

- (BOOL)isItemActiveAtIndex:(NSUInteger)index {
    return _activeViewItem && index < _items.count && _items[index].item == _activeViewItem && _activeViewItem.isActive;
}

- (void)updateFrame:(CADisplayLink*)displayLink {
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self checkItemDisplayingStates];
    [self transformDisplayingItems];
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
        /* 1. layout items without reloading them */
        [self resetLayout];
        
        /* 2. reposition items after rotation
         * -   active: move inactive items offscreen like on previous orientation
         * - inactive: do nothing */
        [self repositionItemsAroundActiveViewItem:_activeViewItem];
        
        /* 3. update scroll info orientation info after layout, so that the scroll change can be fixed */
        [_scrollInfo updateInterfaceOrientation];
    }
}

- (void)resetLayout {
    /* 1. calculate relative scroll positions for restoring after ex. rotation
     * -   active: returns relative location on screen         -> position before activation (relative to screen)
     * - inactive: returns relative location in scroll content -> position in center of visible content */
    CGPoint scrollPosition = [self referenceRelativeScrollPosition];
    
    /* 2. apply identity transform -> layout can be performed only if no 3D transform is applied to the layer */
    [self resetAllItemTransforms];
    
    /* 3. recalculate positions (min. view distances can be different for different orientations) -> ex. rotation */
    [self calculatePositions    ];
    
    /* 4. position items and execute transform */
    [self setupItems            ];
    
    /* 5. adjust scroll positions for changed layout */
    [self adjustScrollPositionToReferenceRelativeScrollPosition:scrollPosition];
}

#pragma mark - adjust scroll positions for layout
- (CGPoint)referenceRelativeScrollPosition {
    CGPoint out = CGPointZero;
    
    UIInterfaceOrientation interfaceOrientation = _scrollInfo.activeInterfaceOrientation;
    NSUInteger index = [self indexOfViewItem:_activeViewItem];
    /* active */
    if (index != NSNotFound) {
        out = [MZSCrollInfoHandler relativeScreenPositionOfPointInScrollViewContent:_items[index].origin
                                                                           fromInfo:_scrollInfo
                                                            forInterfaceOrientation:interfaceOrientation];
    }
    /* inactive */
    else {
        MZScrollInfoData *data = _scrollInfo.data[@(_scrollInfo.activeInterfaceOrientation)];
        out = [MZSCrollInfoHandler relativePositionOfPointInScrollViewContent:CGPointMake(0.0, data.contentOffset.y + data.viewSize.height / 2)
                                                                     fromInfo:_scrollInfo
                                                      forInterfaceOrientation:interfaceOrientation];
    }
    
    return out;
}

- (void)adjustScrollPositionToReferenceRelativeScrollPosition:(CGPoint)position {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSUInteger index = [self indexOfViewItem:_activeViewItem];
    /* active */
    if (index != NSNotFound) {
        _scrollView.contentOffset = [MZSCrollInfoHandler contentOffsetOfRelativeScreenPosition:position
                                                          inRelationToPointInScrollViewContent:_items[index].origin
                                                                                      fromInfo:_scrollInfo
                                                                       forInterfaceOrientation:interfaceOrientation];
    }
    /* inactive */
    else {
        MZScrollInfoData *data = _scrollInfo.data[@(interfaceOrientation)];
        _scrollView.contentOffset = [MZSCrollInfoHandler contentOffsetOfRelativeScreenPosition:CGPointMake(0.0, 0.5)
                                                          inRelationToPointInScrollViewContent:CGPointMake(0.0, data.contentSize.height * position.y)
                                                                                      fromInfo:_scrollInfo
                                                                       forInterfaceOrientation:interfaceOrientation];
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
    [self setupOrientationChange    ];
    [self setupTapGuestureRecognizer];
    [self setupScrollView           ];
    [self setupContentView          ];
    [self setupItemList             ];
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
        if (items[i].hasItem) {
            MZSelectorViewItem *item = items[i].item;
            out &= [self transformItem:item atPoint:[self originOfViewItem:item]];
        }
    }
    return out;
}

- (BOOL)transformItem:(MZSelectorViewItem*)item atPoint:(CGPoint)point {
    BOOL out = item
        && _layout && [_layout respondsToSelector:@selector(selectorView:transformViewItemContentView:atIndex:andPoint:)];
    if (out) {
        [_layout selectorView:self
     transformViewItemContentView:item.contentView
                      atIndex:[self indexOfViewItem:item]
                     andPoint:point];
    }
    return out;
}

@end

@implementation MZSelectorView(Position)

- (BOOL)positionAllItems {
    return [self positionItems:_items];
}

- (BOOL)positionDisplayingItems {
    return [self positionItems:[self displayingItems]];
}

- (BOOL)positionItems:(NSArray<MZSelectorItem*>*)items {
    BOOL out = !CGSizeEqualToSize(self.bounds.size, CGSizeZero);
    if (out) {
        for (NSUInteger i = 0; i < items.count; ++i) {
            items[i].item.frame = CGRectMake(items[i].origin.x,
                                             items[i].origin.y,
                                             self.bounds.size.width,
                                             self.bounds.size.height);
        }
    }
    return out;
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
                      self.scrollView.contentOffset.y - offset,
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

- (void)clearAllItems {
    [self resetAllItems];
    [_items removeAllObjects];
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

- (void)resetItemTransforms:(NSArray<MZSelectorItem*>*)items {
    for (MZSelectorItem *item in items) {
        if (item.hasItem && item.item.superview == self.scrollView) {
            item.item.contentView.layer.transform = CATransform3DIdentity;
        }
    }
    /* calculate frames */
    [self updateLayout];
}

@end

@implementation MZSelectorView(Private)

- (void)setActiveViewItem:(MZSelectorViewItem *)activeViewItem {
    NSAssert((_activeViewItem && !activeViewItem) || !_activeViewItem, @"First active item has to be deactivated!");
    _activeViewItem = activeViewItem;
}

@end

