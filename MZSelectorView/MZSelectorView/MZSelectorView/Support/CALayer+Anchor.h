//
//  CALayer+Anchor.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 15..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CALayer(Anchor)

- (void)setCorrectedAnchorPoint:(CGPoint)anchorPoint;
- (void)setSyncCorrectedAnchorPoint:(CGPoint)anchorPoint;

@end
