//
//  MZScrollInfo.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZScrollInfo.h"

@implementation MZScrollInfoData

- (instancetype)init {
    return [self initWithScrollView:nil];
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
    self = [super init];
    if (self) {
        [self configureWithScrollView:scrollView];
    }
    return self;
}

- (void)configureWithScrollView:(UIScrollView *)scrollView {
    [self reset];
    if (scrollView) {
        _viewSize      = scrollView.bounds.size;
        _contentSize   = scrollView.contentSize;
        _contentOffset = scrollView.contentOffset;
    }
}

- (void)reset {
    _viewSize      = CGSizeZero;
    _contentSize   = CGSizeZero;
    _contentOffset = CGPointZero;
}

@end

@implementation MZScrollInfoData(Logic)

static const CGFloat kDefaultSizeMinLimit = 0.01;

- (CGPoint)absolutePositionInScrollContentOfScrollViewRelativePosition:(CGPoint)position {
    return CGPointMake(_contentOffset.x + _viewSize.width  / 2,
                       _contentOffset.y + _viewSize.height / 2);
}

- (CGPoint)relativePositionInScrollContentOfScrollViewCenter {
    return [self relativePositionInScrollContentOfScrollViewRelativePosition:CGPointMake(0.5, 0.5)];
}

- (CGPoint)relativePositionInScrollContentOfScrollViewRelativePosition:(CGPoint)position {
    CGPoint absolutePositionInScrollContent = [self absolutePositionInScrollContentOfScrollViewRelativePosition:position];
    return CGPointMake(_contentSize.width  > kDefaultSizeMinLimit ? absolutePositionInScrollContent.x / _contentSize.width  : 0.0,
                       _contentSize.height > kDefaultSizeMinLimit ? absolutePositionInScrollContent.y / _contentSize.height : 0.0);
}

- (CGPoint)relativePositionInScrollContentOfAbsolutePositionInScrollContent:(CGPoint)position {
    return CGPointMake(_contentSize.width  > kDefaultSizeMinLimit ? position.x / _contentSize.width  : 0.0,
                       _contentSize.height > kDefaultSizeMinLimit ? position.y / _contentSize.height : 0.0);
}

- (CGPoint)relativePositionInScrollViewOfAbsolutePositionInScrollContent:(CGPoint)position {
    return CGPointMake(_viewSize.width  > kDefaultSizeMinLimit ? (position.x - _contentOffset.x) / _viewSize.width  : 0.0,
                       _viewSize.height > kDefaultSizeMinLimit ? (position.y - _contentOffset.y) / _viewSize.height : 0.0);

}

- (CGPoint)contentOffsetOfRelativeScrollViewPosition:(CGPoint)relViewPosition inRelationToAbsolutePositionInScrollContent:(CGPoint)absContentPosition {
    CGPoint out = CGPointMake(_viewSize.width  > kDefaultSizeMinLimit ? absContentPosition.x - (relViewPosition.x * _viewSize.width ) : 0.0,
                              _viewSize.height > kDefaultSizeMinLimit ? absContentPosition.y - (relViewPosition.y * _viewSize.height) : 0.0);
    return [self limitedContentOffset:out];
}

- (CGPoint)limitedContentOffset:(CGPoint)contentOffset {
    return CGPointMake(_contentSize.width  > kDefaultSizeMinLimit && _viewSize.width  > kDefaultSizeMinLimit ?
                            MAX(MIN(MAX(_contentSize.width  - _viewSize.width , 0), contentOffset.x), 0) :
                            0.0,
                       _contentSize.height > kDefaultSizeMinLimit && _viewSize.height > kDefaultSizeMinLimit ?
                            MAX(MIN(MAX(_contentSize.height - _viewSize.height, 0), contentOffset.y), 0) :
                            0.0);
}

@end

@implementation MZScrollInfo

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView != scrollView) {
        _scrollView = scrollView;
        [self reset];
    }
}

- (NSDictionary<NSNumber*, MZScrollInfoData*> *)data {
    if (!_data) {
        _data = @{ @(UIInterfaceOrientationPortrait)           : [MZScrollInfoData new],
                   @(UIInterfaceOrientationPortraitUpsideDown) : [MZScrollInfoData new],
                   @(UIInterfaceOrientationLandscapeLeft)      : [MZScrollInfoData new],
                   @(UIInterfaceOrientationLandscapeRight)     : [MZScrollInfoData new] };
    }
    return _data;
}

- (void)updateInterfaceOrientation {
    _activeInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)updateData {
    if (_scrollView) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        MZScrollInfoData *data = self.data[@(interfaceOrientation)];
        if (data) {
            data.viewSize      = _scrollView.bounds.size;
            data.contentSize   = _scrollView.contentSize;
            data.contentOffset = _scrollView.contentOffset;
        }
    }
}

- (void)reset {
    [self.data enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, MZScrollInfoData *object, BOOL *stop) {
        [object reset];
    }];
}

@end

@implementation MZScrollInfo(Notification)

- (void)registerDefaultObservers {
    [self registerDefaultObserversForScrollView:_scrollView];
}

- (void)deregisterDefaultObservers {
    [self deregisterDefaultObserversForScrollView:_scrollView];
}

- (void)registerDefaultObserversForScrollView:(UIScrollView*)scrollView {
    if (scrollView) {
        [scrollView addObserver:self forKeyPath:@"frame"         options:0 context:nil]; /* not working */
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
        [scrollView addObserver:self forKeyPath:@"contentSize"   options:0 context:nil];
    }
}

- (void)deregisterDefaultObserversForScrollView:(UIScrollView*)scrollView {
    if (scrollView) {
        [scrollView removeObserver:self forKeyPath:@"frame"        ]; /* doesnt work :( */
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"contentSize"  ];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (_scrollView == object) {
        [self updateData];
    }
}

@end

