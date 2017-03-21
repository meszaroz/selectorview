//
//  UIView+AutoLayout.m
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 17..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <objc/runtime.h>
#import "UIView+UserInteraction.h"

@implementation UIView(UserInteraction)

/* ToDo: Store old values !!! of subviews */
- (void)setSubviewUserInteractionsEnabled:(BOOL)enabled {
    for (UIView *subview in self.subviews) {
        subview.userInteractionEnabled = enabled;
    }
}

@end
