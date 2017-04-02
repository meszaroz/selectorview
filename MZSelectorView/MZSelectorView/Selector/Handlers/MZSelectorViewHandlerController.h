//
//  MZSelectorViewHandlerController.h
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewHandlers.h"

@interface MZSelectorViewHandlerController : NSObject

- (instancetype)__unavailable init;
- (instancetype)initWithIdleHandler:(id<MZSelectorViewActionHandler>)idleHandler
               andSelectionHandlers:(NSArray<id<MZSelectorViewActionHandler>>*)selectionHandlers;

@property (strong, nonatomic, readonly) id<MZSelectorViewActionHandler> activeHandler;

- (BOOL)activateHandlerWithName:(NSString*)handlerName inSelectorView:(MZSelectorView*)selectorView withSelectedIndex:(NSUInteger)index animated:(BOOL)animated;

@end

@interface MZSelectorViewHandlerController(Idle)

@property (nonatomic, readonly, getter=isIdle) BOOL idle;

@end
