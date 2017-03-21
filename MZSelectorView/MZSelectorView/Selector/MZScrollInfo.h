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

@interface MZSCrollInfoHandler : NSObject

+ (CGPoint)relativePositionOfPointInScrollViewContent:(CGPoint)point
                                             fromInfo:(MZScrollInfo*)info
                              forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (CGPoint)relativeScreenPositionOfPointInScrollViewContent:(CGPoint)point
                                                   fromInfo:(MZScrollInfo*)info
                                    forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (CGPoint)pointInScrollViewContentFromRelativePosition:(CGPoint)point
                                               fromInfo:(MZScrollInfo*)info
                                forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (CGPoint)contentOffsetOfRelativeScreenPosition:(CGPoint)position
            inRelationToPointInScrollViewContent:(CGPoint)point
                                        fromInfo:(MZScrollInfo*)info
                         forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
@end

