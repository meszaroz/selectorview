//
//  MZSelectorViewItem.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZSelectorViewItem.h"

@class MZSelectorItem;

@interface MZSelectorViewItem(Private)

@property (nonatomic, getter=isActive) BOOL active;
@property (weak, nonatomic) MZSelectorItem *item;

@end
