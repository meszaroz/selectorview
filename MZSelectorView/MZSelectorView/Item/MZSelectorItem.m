//
//  MZSelectorItem.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorView.h"
#import "MZSelectorItem.h"
#import "MZSelectorViewItem_p.h"

@interface MZSelectorItem() {
    MZSelectorViewItem *_item;
}
@end

@implementation MZSelectorItem

+ (instancetype)itemWithView:(UIView<MZSelectorItemDelegate> *)view {
    return [[self alloc] initWithView:view];
}

- (instancetype)initWithView:(UIView<MZSelectorItemDelegate> *)view {
    NSAssert(view != nil, @"SelectorView parent is needed!");
    self = [super init];
    if (self) {
        _view = view;
        [self reset];
    }
    return self;
}

- (MZSelectorViewItem*)item {
    [self loadItemIfNeeded];
    return _item;
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
    [_view displayStatusChangedOfSelectorItem:self];
}

- (void)setSelected:(BOOL)selected {
    if (_selected != selected) {
        [self willChangeValueForKey:@"selected"];
        _selected = selected;
        [self setSelectedPrivate];
        [self  didChangeValueForKey:@"selected"];
    }
}

- (void)setSelectedPrivate {
    if (_item) {
        [_item setSelectedPrivate];
    }
}

- (void)setActive:(BOOL)active {
    if (_active != active) {
        [self willChangeValueForKey:@"active"];
        _active = active;
        [self setActivePrivate];
        [self  didChangeValueForKey:@"active"];
    }
}

- (void)setActivePrivate {
    /* load if active */
    if (_active && [self loadItemIfNeeded]) {
        [self toggleDisplaying];
    }
    
    /* configure item */
    if (_item) {
        [_item setActivePrivate];
    }
}


@end

@implementation MZSelectorItem(Reset)

- (void)reset {
    [self resetItem      ];
    [self resetSelected  ];
    [self resetActive    ];
    [self resetDisplaying];
}

- (void)resetItem {
    if (_item) {
        [_item removeFromSuperview];
        _item = nil;
    }
}

- (void)resetSelected {
    self.selected = NO;
}

- (void)resetActive {
    self.active = NO;
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
    BOOL out = !self.hasItem;
    if (out) {
        [self willChangeValueForKey:@"item"];
        _item = [_view createSelectorViewItemForSelectorItem:self];
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
