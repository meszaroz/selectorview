//
//  MZScrollInfo.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MZSelectorItem;
@class MZSelectorViewItem;

typedef MZSelectorViewItem* (^ItemFactory)(MZSelectorItem*);

@interface MZSelectorItem : NSObject

@property (strong, nonatomic) MZSelectorViewItem *item;
@property (        nonatomic) CGPoint origin;
@property (        nonatomic) BOOL displaying;

@property (strong, nonatomic) ItemFactory factory;

@end

@interface MZSelectorItem(Reset)

- (void)reset;
- (void)resetItem;
- (void)resetOrigin;
- (void)resetDisplaying;

@end

