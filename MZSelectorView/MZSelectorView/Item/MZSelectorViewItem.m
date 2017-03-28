//
//  MZSelectorViewItem.m
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
#import "CALayer+Anchor.h"
#import "UIView+UserInteraction.h"

@interface MZSelectorViewItem() {
    __weak MZSelectorView *_selectorView;
    
    BOOL _active;
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
    self.clipsToBounds = YES;    
    
    _contentView = [UIView new];
    [self addSubview:_contentView];
    _activeView = _contentView;
    
    self.selectorView = nil;
}

- (void)setFrame:(CGRect)frame {
    super.frame = frame;
    if (_contentView) {
        _contentView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
}

- (void)setActive:(BOOL)active {
    _active = active;
    [self setActivePrivate];
}

- (void)setActivePrivate {
    if (_selectorView) {
        static CGPoint lastAnchorPoint = { 0.5, 0.5 };
        /**/ if ( _active && _selectorView.superview) {
            [_contentView removeFromSuperview];
            
            _activeView = _contentView;
            _contentView = nil;
            
            lastAnchorPoint = _activeView.layer.anchorPoint;
            [_activeView.layer setCorrectedAnchorPoint:CGPointMake(0.5, 0.5)];
            [_selectorView addSubview:_activeView];
            [_activeView autoPinEdgesToSuperviewEdges];
            
            [_activeView setSubviewUserInteractionsEnabled:YES];
        }
        else if (!_active) {
            [_activeView removeFromSuperview];
            
            _contentView = _activeView;
            _activeView = nil;
            [self addSubview:_contentView];
            _contentView.translatesAutoresizingMaskIntoConstraints = YES;
            [_contentView.layer setCorrectedAnchorPoint:lastAnchorPoint];
            
            [_contentView setSubviewUserInteractionsEnabled:NO];
        }        
    }
}

@end

@implementation MZSelectorViewItem(Private)

- (void)setSelectorView:(MZSelectorView *)selectorView {
    if (_selectorView != selectorView) {
        NSAssert(_selectorView == nil, @"Only one selectorView assignment is allowed!");
        _selectorView = selectorView;
        [self resetSelected];
    }
}

- (MZSelectorView*)selectorView {
    return _selectorView;
}

- (void)resetSelected {
    self.selected = NO;
    self.active   = NO;
}

- (BOOL)isActive {
    return _active;
}

@end
