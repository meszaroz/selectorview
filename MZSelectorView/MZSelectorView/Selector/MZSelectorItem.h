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

/* delegate */
@protocol MZSelectorItemDelegate<NSObject>

- (MZSelectorViewItem*)createSelectorViewItemForSelectorItem:(MZSelectorItem*)item;
- (void)displayStatusChangedOfSelectorItem:(MZSelectorItem*)item;

@end

/* object */
@interface MZSelectorItem : NSObject

@property (strong, nonatomic, readonly) MZSelectorViewItem *item;
@property (        nonatomic          ) CGPoint defaultOrigin;
@property (        nonatomic          ) BOOL displaying;

@property (weak, nonatomic) id<MZSelectorItemDelegate> delegate;

+ (instancetype)itemWithDelegate:(id<MZSelectorItemDelegate>)delegate;
- (instancetype)initWithDelegate:(id<MZSelectorItemDelegate>)delegate;

@end

@interface MZSelectorItem(Reset)

- (void)reset;
- (void)resetItem;
- (void)resetDefaultOrigin;
- (void)resetDisplaying;

@end

@interface MZSelectorItem(Item)

@property (nonatomic, readonly) BOOL hasItem; /* won't load item, just check if already loaded */
- (BOOL)loadItemIfNeeded;

@end

@interface MZSelectorItem(Helper)

- (void)toggleDisplaying;

@end

