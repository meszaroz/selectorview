//
//  MZSelectorViewItem.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 14..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MZSelectorViewItem : UIView

@property (nonatomic, readonly, nonnull) UIView *contentView;
@property (nonatomic, getter=isSelected) BOOL selected;

@end
