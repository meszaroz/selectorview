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

@interface MZSelectorView () <UIScrollViewDelegate> {
    UIView *_contentView;
    
    NSLayoutConstraint *_contentConstraintHeight;
    
    NSMutableArray<MZSelectorItem *> *_items;
    
    MZScrollInfo *_scrollInfo;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

static const CGFloat kDefaultAnimationDuration = 0.5;
static const UIEdgeInsets kDefaultItemInsets = { 40.0, 0.0, 80.0, 0.0 };

static const CGFloat kItemShowDistanceFromEdge = 50.0;
static const CGFloat kItemHideDistanceFromEdge = 100.0;

@implementation MZSelectorView(ShowHide)

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
    return item
        && (   ( item.displaying && CGRectIntersectsRect(self.currentHideFrame, item.item.frame))
            || (!item.displaying && CGRectIntersectsRect(self.currentShowFrame, item.item.frame)));
}

@end

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
    [self setupOrientationChange    ];
    [self setupTapGuestureRecognizer];
    [self setupScrollView           ];
    [self setupContentView          ];
    [self setupItemList             ];
    
    [self reloadData];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollInfo deregisterDefaultObservers];
}

#pragma mark - functions
- (CGPoint)originOfItem:(MZSelectorViewItem * _Nonnull)item {
    NSInteger index = [self indexOfItem:item];
    return index != NSNotFound ?
        _items[index].origin :
        CGPointZero;
}

- (nullable __kindof MZSelectorViewItem *)itemAtIndex:(NSUInteger)index {
    MZSelectorViewItem *out = nil;
    
    if (index < self.numberOfItems) {
        if (_items.count < index) {
            [self prepareItems];
        }
        out = _items[index].item;
    }
    
    return out;
}

- (NSUInteger)indexOfItem:(MZSelectorViewItem * _Nonnull)item {
    return [_items indexOfObjectPassingTest:^BOOL(MZSelectorItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.item == item;
    }];
}

#pragma mark - configure
- (void)reloadData {
    [self resetSelector     ];
    [self prepareItems      ];
    [self calculatePositions];
    [self setupItems        ];
    
    [self scrollViewDidScroll:_scrollView];
}

- (void)resetSelector {
    [self resetOrigins      ];
    [self resetItems        ];
    [self resetContentOffset]; /* ToDo: try to adjust -  */
}

- (void)resetOrigins {
    for (MZSelectorItem *item in _items) {
        [item resetOrigin];
    }
}

- (void)resetItems {
    for (MZSelectorItem *item in _items) {
        [item reset];
    }
    [_items removeAllObjects];
}

- (void)resetContentOffset {
    _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x, 0.0);
}

- (void)resetItemTransforms {
    for (MZSelectorItem *item in _items) {
        if (item.item.superview == _scrollView) {
            item.item.contentView.layer.transform = CATransform3DIdentity;
        }
    }
    /* calculate frames */
    [self updateLayout];
}

- (BOOL)prepareItems {
    BOOL out = _items.count == 0;
    if (out) {
        NSUInteger numberOfItems = self.numberOfItems;
        
        for (NSUInteger i = 0; i < numberOfItems; ++i) {
            MZSelectorItem *item = [MZSelectorItem new];
            
            __weak typeof(self) weakSelf = self;
            item.factory = ^MZSelectorViewItem* (MZSelectorItem *item) {
                MZSelectorViewItem *out = nil;
                if (weakSelf && weakSelf.dataSource) {
                    out = [weakSelf.dataSource selectorView:self itemAtIndex:i];
                    out.selectorView = weakSelf;
                    
                    NSAssert([out isKindOfClass:MZSelectorViewItem.class], @"Unsupported Item type!");
                    
                    [out removeFromSuperview];
                    [weakSelf.scrollView addSubview:out];
                }
                return out;
            };
            
            [_items addObject:item];
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
    [self setContentHeight:MAX( self.bounds.size.height,
                               [self adjustedContentHeight])];
}

- (BOOL)calculateItemOrigins {
    NSUInteger numberOfItems = self.numberOfItems;
    CGFloat itemDistance  = [self adjustedItemDistance];
    CGFloat y = self.itemInsets.top;
    
    BOOL out = numberOfItems > 0 && itemDistance > 0.1;
    
    for (NSUInteger i = 0; i < numberOfItems; ++i) {
        y += i == 0 ? 0 : itemDistance;
        _items[i].origin = CGPointMake(0,out ? y : 0);
    }
    
    return out;
}

- (void)setupItems {
    [self positionItems      ];
    [self resetItemTransforms];
    [self transformAllItems  ];
}

- (BOOL)positionItems {
    BOOL out = !CGSizeEqualToSize(self.bounds.size, CGSizeZero);
    if (out) {
       for (NSUInteger i = 0; i < _items.count; ++i) {
            _items[i].item.frame = CGRectMake(_items[i].origin.x,
                                              _items[i].origin.y,
                                              self.bounds.size.width,
                                              self.bounds.size.height);
        }
    }
    return out;
}

- (void)updateLayout {
    UIView *view = self.superview ? self.superview : self;
    [view layoutIfNeeded];
}

- (BOOL)transformAllItems {
    return [self transformItems:_items];
}

/* ToDo: fix  */
- (BOOL)transformItems:(NSArray<MZSelectorItem*>*)items {
    BOOL out = items.count > 0;
    for (NSUInteger i = 0; out && i < items.count; ++i) {
        MZSelectorViewItem *item = items[i].item;
        out &= [self transformItem:item atPoint:[self originOfItem:item]];
    }
    return out;
}

- (BOOL)transformItem:(MZSelectorViewItem*)item atPoint:(CGPoint)point {
    BOOL out = item
        && _layout && [_layout respondsToSelector:@selector(selectorView:transformItemContentView:atIndex:andPoint:)];
    if (out) {
        [_layout selectorView:self
     transformItemContentView:item.contentView
                      atIndex:[self indexOfItem:item]
                     andPoint:point];
    }
    return out;
}

#pragma mark - adjust/calculate properties -> move to extension
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
    
    return viewHeight < [self adjustedContentHeight] ?
        self.minimalItemDistance :
        (numberOfItems > 1 ?
            MAX(0, (viewHeight - itemInsets.bottom - itemInsets.top) / (numberOfItems-1)) :
            0);
}

- (UIEdgeInsets)adjusteditemInsets {
    UIEdgeInsets itemInsets = self.itemInsets;
    
    if (self.numberOfItems <= 1) {
        itemInsets.bottom = self.bounds.size.height - itemInsets.top;
    }
    
    return itemInsets;
}

#pragma mark - info
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

#pragma mark - activate
- (BOOL)activateItemAtIndex:(NSUInteger)index {
    BOOL out = self.superview && !_activeItem && index < _items.count;
    
    if (out) {
        _scrollView.scrollEnabled = NO;
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willActivateItemAtIndex:)]) {
            [_delegate selectorView:self willActivateItemAtIndex:index];
        }
        
        MZSelectorViewItem *item = _items[index].item;
        item.selected = YES;
        
        [UIView animateWithDuration:kDefaultAnimationDuration
                         animations:^{
                             [self repositionItemsAroundActiveItem:item];
                         }
                         completion:^(BOOL finished) {
                             item.active = YES;
                             [displayLink invalidate];
                             
                             if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didActivateItemAtIndex:)]) {
                                 [_delegate selectorView:self didActivateItemAtIndex:index];
                             }
                         }];
    }
    
    return out;
}

- (void)repositionItemsAroundActiveItem:(MZSelectorViewItem*)item {
    NSUInteger index = [self indexOfItem:item];
    
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

- (BOOL)deactivateActiveItem {
    return [self deactivateItemAtIndex:[self indexOfItem:_activeItem]];
}

- (BOOL)deactivateItemAtIndex:(NSUInteger)index {
    BOOL out = self.superview && [self isItemActiveAtIndex:index];
    
    if (out) {
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willDeactivateItemAtIndex:)]) {
            [_delegate selectorView:self willDeactivateItemAtIndex:index];
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
                             
                             if (_delegate && [_delegate respondsToSelector:@selector(selectorView:didDeactivateItemAtIndex:)]) {
                                 [_delegate selectorView:self didDeactivateItemAtIndex:index];
                             }
                         }];
    }

    return out;
}

- (BOOL)isItemActiveAtIndex:(NSUInteger)index {
    return _activeItem && index < _items.count && _items[index].item == _activeItem && _activeItem.isActive;
}

- (void)updateFrame:(CADisplayLink*)displayLink {
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self transformAllItems];
}

- (void)handleItemVisibilityChangeNotifications {
    for (MZSelectorItem *item in _items) {
        /* SHOW */
        /**/ if (!item.displaying &&  [self isItemDisplaying:item]) {
            item.displaying = YES;
        }
        /* HIDE */
        else if ( item.displaying && ![self isItemDisplaying:item]) {
            item.displaying = NO;
        }
        
        /* if changed -> send notification -> add observer */
        /* 1. transform to identity */
        /* 2. call delegate */
        /* 3. updateLayout if any change */
        
        /* 3. - execute transform - */
        
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
        [self repositionItemsAroundActiveItem:_activeItem];
        
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
    [self resetItemTransforms ];
    
    /* 3. recalculate positions (min. view distances can be different for different orientations) -> ex. rotation */
    [self calculatePositions  ];
    
    /* 4. position items and execute transform */
    [self setupItems          ];
    
    /* 5. adjust scroll positions for changed layout */
    [self adjustScrollPositionToReferenceRelativeScrollPosition:scrollPosition];
}

#pragma mark - adjust scroll positions for layout
- (CGPoint)referenceRelativeScrollPosition {
    CGPoint out = CGPointZero;
    
    UIInterfaceOrientation interfaceOrientation = _scrollInfo.activeInterfaceOrientation;
    NSUInteger index = [self indexOfItem:_activeItem];
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
    NSUInteger index = [self indexOfItem:_activeItem];
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
        [self indexOfItem:(MZSelectorViewItem*)view] :
        NSNotFound;
    
    if (index != NSNotFound) {
        [self activateItemAtIndex:index];
    }
}

@end

@implementation MZSelectorView(Private)

- (void)setActiveItem:(MZSelectorViewItem *)activeItem {
    NSAssert((_activeItem && !activeItem) || !_activeItem, @"First active item has to be deactivated!");
    _activeItem = activeItem;
}

@end

