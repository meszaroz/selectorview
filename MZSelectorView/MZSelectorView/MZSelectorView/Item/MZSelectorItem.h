//
//  MZSelectorItem.h
//  MZScrollView
//
//  Created by Mészáros Zoltán on 2017. 03. 21..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MZSelectorView;
@class MZSelectorItem;
@class MZSelectorViewItem;

/* delegate */
@protocol MZSelectorItemDelegate<NSObject>

- (MZSelectorViewItem*)createSelectorViewItemForSelectorItem:(MZSelectorItem*)item;
- (void)displayStatusChangedOfSelectorItem:(MZSelectorItem*)item;

@end

/* object */
@interface MZSelectorItem : NSObject

@property (nonatomic, getter=isSelected  ) BOOL selected;
@property (nonatomic, getter=isActive    ) BOOL active;
@property (nonatomic, getter=isDisplaying) BOOL displaying;

@property (strong, nonatomic, readonly) MZSelectorViewItem *item;
@property (weak  , nonatomic, readonly) UIView<MZSelectorItemDelegate> *view;

+ (instancetype)itemWithView:(UIView<MZSelectorItemDelegate>*)view;
- (instancetype)initWithView:(UIView<MZSelectorItemDelegate>*)view;
- (instancetype)__unavailable init;

@end

@interface MZSelectorItem(Reset)

- (void)reset;
- (void)resetItem;

@end

@interface MZSelectorItem(Item)

@property (nonatomic, readonly) BOOL hasItem; /* won't load item, just check if already loaded */
- (BOOL)loadItemIfNeeded;

@end

@interface MZSelectorItem(Helper)

- (void)toggleDisplaying;

@end

