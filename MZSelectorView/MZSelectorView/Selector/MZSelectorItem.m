//
//  MZSelectorItem.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorItem.h"
#import "MZSelectorViewItem.h"

@implementation MZSelectorItem

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (MZSelectorViewItem*)item {
    if (!_item && _factory) {
        _item = _factory(self);
    }
    return _item;
}

- (void)setDisplaying:(BOOL)displaying {
    if (_displaying != displaying) {
        [self willChangeValueForKey:@"displaying"];
        _displaying = displaying;
        [self  didChangeValueForKey:@"displaying"];
    }
}

@end

@implementation MZSelectorItem(Reset)

- (void)reset {
    [self resetItem      ];
    [self resetOrigin    ];
    [self resetDisplaying];
}

- (void)resetItem {
    if (_item) {
        [_item removeFromSuperview];
        _item = nil;
    }
}

- (void)resetOrigin {
    _origin = CGPointZero;
}

- (void)resetDisplaying {
    _displaying = NO;
}

@end
