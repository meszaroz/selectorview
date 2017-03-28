//
//  MZSelectorItem.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorItem.h"
#import "MZSelectorViewItem.h"

@interface MZSelectorItem() {
    MZSelectorViewItem *_item;
}
@end

@implementation MZSelectorItem

+ (instancetype)itemWithDelegate:(id<MZSelectorItemDelegate>)delegate {
    return [[self alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id<MZSelectorItemDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        [self reset];
    }
    return self;
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (MZSelectorViewItem*)item {
    [self loadItemIfNeeded];
    return _item;
}

- (void)setDefaultOrigin:(CGPoint)defaultOrigin {
    if (!CGPointEqualToPoint(_defaultOrigin, defaultOrigin)) {
        [self willChangeValueForKey:@"defaultOrigin"];
        _defaultOrigin = defaultOrigin;
        [self setDefaultOriginPrivate];
        [self  didChangeValueForKey:@"defaultOrigin"];
    }
}

- (void)setDefaultOriginPrivate {
    if (_item) {
        CGRect frame = _item.frame;
        frame.origin = _defaultOrigin;
        _item.frame = frame;
    }
}

- (void)setDisplaying:(BOOL)displaying {
    if (_displaying != displaying) {
        [self willChangeValueForKey:@"displaying"];
        _displaying = displaying;
        [self setDisplayingPrivate];
        [self  didChangeValueForKey:@"displaying"];
    }
}

- (void)setDisplayingPrivate {
    if (_delegate) {
        [_delegate displayStatusChangedOfSelectorItem:self];
    }
}

@end

@implementation MZSelectorItem(Reset)

- (void)reset {
    [self resetItem         ];
    [self resetDefaultOrigin];
    [self resetDisplaying   ];
}

- (void)resetItem {
    if (_item) {
        [_item removeFromSuperview];
        _item = nil;
    }
}

- (void)resetDefaultOrigin {
    _defaultOrigin = CGPointZero;
}

- (void)resetDisplaying {
    _displaying = NO;
}

@end

@implementation MZSelectorItem(Item)

- (BOOL)hasItem {
    return _item != nil;
}

- (BOOL)loadItemIfNeeded {
    BOOL out = !self.hasItem && _delegate;
    if (out) {
        [self willChangeValueForKey:@"item"];
        _item = [_delegate createSelectorViewItemForSelectorItem:self];
        [self  didChangeValueForKey:@"item"];
    }
    return out && _item;
}

@end

@implementation MZSelectorItem(Helper)

- (void)toggleDisplaying {
    self.displaying = !self.displaying;
}

@end
