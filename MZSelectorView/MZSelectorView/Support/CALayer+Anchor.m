//
//  CALayer+Anchor.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 15..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "CALayer+Anchor.h"

@implementation CALayer(Anchor)

- (void)setCorrectedAnchorPoint:(CGPoint)anchorPoint {
    CGPoint newPoint = CGPointMake(self.bounds.size.width  * anchorPoint.x,
                                   self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width  * self.anchorPoint.x,
                                   self.bounds.size.height * self.anchorPoint.y);
    
    CGPoint position = self.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    self.position = position;
    self.anchorPoint = anchorPoint;
}

- (void)setSyncCorrectedAnchorPoint:(CGPoint)anchorPoint {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setCorrectedAnchorPoint:anchorPoint];
    });
}

@end
