//
//  MZSelectorViewItem.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "PureLayout.h"
#import "MZSelectorItem.h"
#import "MZSelectorViewItem_p.h"
#import "MZSelectorViewItem.h"
#import "CALayer+Anchor.h"
#import "UIView+UserInteraction.h"

@interface MZSelectorViewItem() {
    __weak MZSelectorItem *_item;
    UIView *_activeView;
}
@end

@implementation MZSelectorViewItem

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
    _contentView = [UIView new];
    [self addSubview:_contentView];
    [_contentView setSubviewUserInteractionsEnabled:NO];
}

- (void)setFrame:(CGRect)frame {
    super.frame = frame;
    if (_contentView) {
        _contentView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
}

- (void)setSelected:(BOOL)selected {
    if (_item) {
        _item.selected = selected;
    }
}

- (BOOL)isSelected {
    return _item && _item.isSelected;
}

@end

@implementation MZSelectorViewItem(Private)

- (void)setItem:(MZSelectorItem *)item {
    if (_item != item) {
        _item = item;
        [self setActivePrivate];
    }
}

- (MZSelectorItem*)item {
    return _item;
}

- (void)setActive:(BOOL)active {
    if (_item) {
        _item.active = active;
    }
}

- (void)setActivePrivate {
    if (_item) {
        static CGPoint lastAnchorPoint = { 0.5, 0.5 };
        /**/ if ( _item.active && _item.view) {
            if (_contentView) {
                [_contentView removeFromSuperview];
                _activeView = _contentView;
                _contentView = nil;
            }
            if (![_item.view.subviews containsObject:_activeView]) {
                lastAnchorPoint = _activeView.layer.anchorPoint;
                [_activeView.layer setCorrectedAnchorPoint:CGPointMake(0.5, 0.5)];
                [_item.view addSubview:_activeView];
                [_activeView autoPinEdgesToSuperviewEdges];
            }
            [_activeView setSubviewUserInteractionsEnabled:YES];
        }
        else if (!_item.active) {
            if (_activeView) {
                [_activeView removeFromSuperview];
                _contentView = _activeView;
                _activeView = nil;
            }
            if (![self.subviews containsObject:_contentView]) {
                [self addSubview:_contentView];
                _contentView.translatesAutoresizingMaskIntoConstraints = YES;
                [_contentView.layer setCorrectedAnchorPoint:lastAnchorPoint];
            }
            [_contentView setSubviewUserInteractionsEnabled:NO];
        }
    }
}

- (BOOL)isActive {
    return _item && _item.active;
}

- (void)setSelectedPrivate {
}

@end
