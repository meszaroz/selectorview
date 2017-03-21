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
#import "MZScrollInfo.h"
#import "CALayer+Anchor.h"

@interface MZSelectorView () <UIScrollViewDelegate> {
    UIView *_contentView;
    
    NSLayoutConstraint *_contentConstraintHeight;
    
    NSMutableArray<MZSelectorViewItem *> *_items;
    NSMutableArray<NSValue            *> *_positions;
    
    MZScrollInfo *_scrollInfo;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

static const CGFloat kDefaultAnimationDuration = 0.5;
static const UIEdgeInsets kDefaultitemInsets = { 40.0, 0.0, 80.0, 0.0 };

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
    _items     = [NSMutableArray array];
    _positions = [NSMutableArray array];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollInfo deregisterDefaultObservers];
}

#pragma mark - functions
- (CGPoint)originOfItem:(MZSelectorViewItem * _Nonnull)item {
    NSInteger index = [_items indexOfObject:item];
    return index != NSNotFound ?
        _positions[index].CGPointValue :
        CGPointZero;
}

- (nullable __kindof MZSelectorViewItem *)itemAtIndex:(NSUInteger)index {
    MZSelectorViewItem *out = nil;
    
    if (index < self.numberOfItems) {
        if (_items.count < index) {
            [self loadItems];
        }
        out = _items[index];
    }
    
    return out;
}

#pragma mark - configure
- (void)reloadData {
    [self resetSelector     ];
    [self calculatePositions];
    [self loadItems         ];
    [self setupItems        ];
}

- (void)resetSelector {
    [self resetPositions    ];
    [self resetItems        ];
    [self resetContentOffset];
}

- (void)resetPositions {
    [_positions removeAllObjects];
}

- (void)resetItems {
    for (UIView *item in _items) {
        [item removeFromSuperview];
    }
    [_items removeAllObjects];
}

- (void)resetContentOffset {
    _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x, 0.0);
}

- (void)resetItemTransforms {
    for (MZSelectorViewItem *item in _items) {
        if (item.superview == _scrollView) {
            item.contentView.layer.transform = CATransform3DIdentity;
        }
    }
    /* calculate frames */
    [self updateLayout];
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
    [self resetPositions];
    
    NSUInteger   numberOfItems = self.numberOfItems;
    UIEdgeInsets itemInsets    = self.itemInsets;
    CGFloat      itemDistance  = [self adjustedItemDistance];
    
    BOOL out = numberOfItems > 0 && itemDistance > 0.1;
    if (out) {
        CGFloat x = itemInsets.left;
        CGFloat y = itemInsets.top;
        
        [_positions addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        for (NSUInteger i = 0; i < numberOfItems-1; ++i) {
            y += itemDistance;
            [_positions addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
    }
    
    return out;
}

- (void)setupItems {
    [self positionItems      ];
    [self resetItemTransforms];
    [self transformAllItems  ];
}

- (BOOL)loadItems {
    BOOL out = _items.count == 0;
    if (out) {
        NSUInteger numberOfItems = self.numberOfItems;
        
        if (_dataSource) {
            for (NSUInteger i = 0; i < numberOfItems; ++i) {
                MZSelectorViewItem *item = [_dataSource selectorView:self itemAtIndex:i];
                item.selectorView = self;
                
                NSAssert([item isKindOfClass:MZSelectorViewItem.class], @"Unsupported Item type!");

                [item removeFromSuperview];
                [_scrollView addSubview:item];
                [_items addObject:item];                
            }
        }
    }
    return out;
}

- (BOOL)positionItems {
    UIEdgeInsets itemInsets = self.itemInsets;
    BOOL out = !CGSizeEqualToSize(self.bounds.size, CGSizeZero) && _positions.count == _items.count;
    if (out) {
       for (NSUInteger i = 0; i < _items.count; ++i) {
            _items[i].frame = CGRectMake(itemInsets.left,
                                         _positions[i].CGPointValue.y,
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

- (BOOL)transformItems:(NSArray<MZSelectorViewItem*>*)items {
    BOOL out = items.count > 0;
    for (NSUInteger i = 0; out && i < items.count; ++i) {
        MZSelectorViewItem *item = items[i];
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
                      atIndex:[_items indexOfObject:item]
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
    UIEdgeInsets insets = kDefaultitemInsets;
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
        
        MZSelectorViewItem *item = _items[index];
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
    NSUInteger index = [_items indexOfObject:item];
    
    if (index != NSNotFound) {
        NSMutableArray<MZSelectorViewItem*> *prevItems = [NSMutableArray array];
        NSMutableArray<MZSelectorViewItem*> *nextItems = [NSMutableArray array];
        
        for (NSUInteger i = 0; i < _items.count; ++i) {
            /**/ if (i < index) { [prevItems addObject:_items[i]]; }
            else if (i > index) { [nextItems addObject:_items[i]]; }
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
    return [self deactivateItemAtIndex:[_items indexOfObject:_activeItem]];
}

- (BOOL)deactivateItemAtIndex:(NSUInteger)index {
    BOOL out = self.superview && [self isItemActiveAtIndex:index];
    
    if (out) {
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        if (_delegate && [_delegate respondsToSelector:@selector(selectorView:willDeactivateItemAtIndex:)]) {
            [_delegate selectorView:self willDeactivateItemAtIndex:index];
        }
        
        MZSelectorViewItem *item = _items[index];
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
    return _activeItem && index < _items.count && _items[index] == _activeItem && _activeItem.isActive;
}

- (void)updateFrame:(CADisplayLink*)displayLink {
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self transformAllItems];
}

#pragma mark - orientation change
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    /* execute only once */
    if (_scrollInfo.activeInterfaceOrientation != [[UIApplication sharedApplication] statusBarOrientation]) {
        /* 1. layout items without reloading them */
        [self resetLayout];
        
        /* 2. reposition items after rotation
         *   active: move inactive items offscreen like on previous orientation
         * inactive: do nothing */
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
    
    NSUInteger index = [_items indexOfObject:_activeItem];
    /* active */
    if (index != NSNotFound) {
        out = [MZSCrollInfoHandler relativeScreenPositionOfPointInScrollViewContent:_positions[index].CGPointValue
                                                                           fromInfo:_scrollInfo
                                                            forInterfaceOrientation:_scrollInfo.activeInterfaceOrientation];
    }
    /* inactive */
    else {
        MZScrollInfoData *data = _scrollInfo.data[@(_scrollInfo.activeInterfaceOrientation)];
        out = [MZSCrollInfoHandler relativePositionOfPointInScrollViewContent:CGPointMake(0.0, data.contentOffset.y + data.viewSize.height / 2)
                                                                     fromInfo:_scrollInfo
                                                      forInterfaceOrientation:_scrollInfo.activeInterfaceOrientation];
    }
    
    return out;
}

- (void)adjustScrollPositionToReferenceRelativeScrollPosition:(CGPoint)position {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSUInteger index = [_items indexOfObject:_activeItem];
    /* active */
    if (index != NSNotFound) {
        _scrollView.contentOffset = [MZSCrollInfoHandler contentOffsetOfRelativeScreenPosition:position
                                                          inRelationToPointInScrollViewContent:_positions[index].CGPointValue
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
        [_items indexOfObject:(MZSelectorViewItem*)view] :
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

