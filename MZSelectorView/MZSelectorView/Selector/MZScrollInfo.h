//
//  MZScrollInfo.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MZScrollInfoData : NSObject

@property (nonatomic) CGSize  viewSize;
@property (nonatomic) CGSize  contentSize;
@property (nonatomic) CGPoint contentOffset;

- (instancetype)initWithScrollView:(UIScrollView*)scrollView;

- (void)configureWithScrollView:(UIScrollView*)scrollView;
- (void)reset;

@end

@interface MZScrollInfoData(Logic)

- (CGPoint)absolutePositionInScrollContentOfScrollViewRelativePosition:(CGPoint)position;
- (CGPoint)relativePositionInScrollContentOfScrollViewRelativePosition:(CGPoint)position;
- (CGPoint)relativePositionInScrollContentOfAbsolutePositionInScrollContent:(CGPoint)position;
- (CGPoint)relativePositionInScrollViewOfAbsolutePositionInScrollContent:(CGPoint)position;
- (CGPoint)contentOffsetOfRelativeScrollViewPosition:(CGPoint)relViewPosition inRelationToAbsolutePositionInScrollContent:(CGPoint)absContentPosition;
- (CGPoint)limitedContentOffset:(CGPoint)contentOffset;

@end

@interface MZScrollInfo : NSObject {
    NSDictionary<NSNumber*, MZScrollInfoData*> *_data;
}

@property (weak,   nonatomic          ) UIScrollView *scrollView;
@property (        nonatomic, readonly) UIInterfaceOrientation  activeInterfaceOrientation;
@property (strong, nonatomic, readonly) NSDictionary<NSNumber*, MZScrollInfoData*> *data;

- (void)updateInterfaceOrientation;
- (void)updateData;

- (void)reset;

@end

@interface MZScrollInfo(Notification)

- (void)registerDefaultObservers;
- (void)deregisterDefaultObservers;

/* general */
- (void)registerDefaultObserversForScrollView:(UIScrollView*)scrollView;
- (void)deregisterDefaultObserversForScrollView:(UIScrollView*)scrollView;

@end

