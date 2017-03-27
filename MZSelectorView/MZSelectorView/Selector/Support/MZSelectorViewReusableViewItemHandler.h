//
//  MZSelectorViewReusableViewItemHandler.h
//  MZSelectorView
//
//  Created by Zoltan Meszaros on 3/27/17.
//  Copyright © 2017 Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MZSelectorViewItem;

@interface MZSelectorViewReusableViewItemHandler : NSObject

- (void)registerClass:(Class)viewItemClass forViewItemReuseIdentifier:(NSString *)identifier;

- (__kindof MZSelectorViewItem *)dequeueReusableViewItemWithIdentifier:(NSString *)identifier;

- (void)clear;

@end
