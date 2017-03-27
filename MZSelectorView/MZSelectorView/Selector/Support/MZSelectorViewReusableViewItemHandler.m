//
//  MZSelectorViewReusableViewItemHandler.m
//  MZSelectorView
//
//  Created by Zoltan Meszaros on 3/27/17.
//  Copyright © 2017 Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewReusableViewItemHandler.h"
#import "MZSelectorViewItem.h"

@interface MZSelectorViewReusableViewItemHandler() {
    NSMutableDictionary<NSString*,Class> *_factory;
    NSMutableArray<__kindof MZSelectorViewItem*> *_buffer;
}

@end

@implementation MZSelectorViewReusableViewItemHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _factory = [NSMutableDictionary dictionary];
        _buffer  = [NSMutableArray      array     ];
    }
    return self;
}

- (void)clear {
    [_factory removeAllObjects];
    [_buffer  removeAllObjects];
}

- (void)registerClass:(Class)viewItemClass forViewItemReuseIdentifier:(NSString *)identifier {
    NSAssert(viewItemClass && identifier, @"registerClass:forViewItemReuseIdentifier: inputs are wrong!");
    NSAssert(!_factory[identifier], @"registerClass:forViewItemReuseIdentifier: identifier already in use!");
    [_factory setValue:viewItemClass forKey:identifier];
}

- (__kindof MZSelectorViewItem *)dequeueReusableViewItemWithIdentifier:(NSString *)identifier {
    NSAssert(identifier != nil, @"dequeueReusableViewItemWithIdentifier: identifier must not be nil!");
    Class factory = _factory[identifier];
    NSAssert(factory != nil, @"dequeueReusableViewItemWithIdentifier: identifier is not registered!");
    MZSelectorViewItem *out = [self reusableItemWithViewItemClass:factory];
    if (!out) {
        out = [factory new];
        [_buffer addObject:out];
    }
    return out;
}

- (__kindof MZSelectorViewItem *)reusableItemWithViewItemClass:(Class)viewItemClass {
    NSUInteger index = [self indexOfItemWithViewItemClass:viewItemClass];
    return index != NSNotFound ?
        _buffer[index] :
        nil;
}

- (NSUInteger)indexOfItemWithViewItemClass:(Class)viewItemClass {
    return [_buffer indexOfObjectPassingTest:^BOOL(MZSelectorViewItem* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return viewItemClass && [obj isMemberOfClass:viewItemClass] && !obj.superview;
    }];
}

@end
