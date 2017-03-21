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

@implementation MZSCrollInfoHandler

+ (CGPoint)relativePositionOfPointInScrollViewContent:(CGPoint)point
                                             fromInfo:(MZScrollInfo*)info
                              forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGPoint out = CGPointZero;
    MZScrollInfoData *data = info.data[@(interfaceOrientation)];
    if (data && data.contentSize.width > 0.1 && data.contentSize.height > 0.1) {
        out = CGPointMake(point.x / data.contentSize.width,
                          point.y / data.contentSize.height);
    }
    return out;
}

+ (CGPoint)relativeScreenPositionOfPointInScrollViewContent:(CGPoint)point
                                                   fromInfo:(MZScrollInfo*)info
                                    forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGPoint out = CGPointZero;
    MZScrollInfoData *data = info.data[@(interfaceOrientation)];
    if (data && data.viewSize.width > 0.1 && data.viewSize.height > 0.1) {
        out = CGPointMake((point.x - data.contentOffset.x) / data.viewSize.width,
                          (point.y - data.contentOffset.y) / data.viewSize.height);
    }
    return out;
}

+ (CGPoint)pointInScrollViewContentFromRelativePosition:(CGPoint)position
                                               fromInfo:(MZScrollInfo*)info
                                forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGPoint out = CGPointZero;
    MZScrollInfoData *data = info.data[@(interfaceOrientation)];
    if (data) {
        out = CGPointMake(data.contentSize.width  * position.x,
                          data.contentSize.height * position.y);
    }
    return out;
}

+ (CGPoint)contentOffsetOfRelativeScreenPosition:(CGPoint)position
            inRelationToPointInScrollViewContent:(CGPoint)point
                                        fromInfo:(MZScrollInfo*)info
                         forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGPoint out = CGPointZero;
    MZScrollInfoData *data = info.data[@(interfaceOrientation)];
    if (data && data.viewSize.width > 0.1 && data.viewSize.height > 0.1) {
        out = CGPointMake(point.x - (position.x * data.viewSize.width ),
                          point.y - (position.y * data.viewSize.height));
        out = [self limitedContentOffset:out fromInfo:info forInterfaceOrientation:interfaceOrientation];
    }
    return out;
}

+ (CGPoint)limitedContentOffset:(CGPoint)contentOffset
                       fromInfo:(MZScrollInfo*)info
        forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGPoint out = CGPointZero;
    MZScrollInfoData *data = info.data[@(interfaceOrientation)];
    if (data
        && data.contentSize.width > 0.1 && data.contentSize.height > 0.1
        && data.viewSize   .width > 0.1 && data.viewSize   .height > 0.1) {
        out = CGPointMake(MAX(MIN(MAX(data.contentSize.width  - data.viewSize.width , 0), contentOffset.x), 0),
                          MAX(MIN(MAX(data.contentSize.height - data.viewSize.height, 0), contentOffset.y), 0));
    }
    return out;
}

@end

