//
//  MZSelectorViewHandlerController.m
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import <TransitionKit/TransitionKit.h>
#import "MZSelectorViewHandlerController.h"
#import "MZSelectorItem.h"
#import "MZScrollInfo.h"

static NSString *kTransitionSelectionView = @"TransitionSelectionView";
static NSString *kTransitionSelectedIndex = @"TransitionSelectedIndex";

@interface MZSelectorViewHandlerController() {
    id<MZSelectorViewActionHandler> _idleHandler;
    NSMutableDictionary<NSString*, id<MZSelectorViewActionHandler>> *_handlers;
    
    TKStateMachine *_stateMachine;
}
@end

@implementation MZSelectorViewHandlerController

- (instancetype)initWithIdleHandler:(id<MZSelectorViewActionHandler>)idleHandler
               andSelectionHandlers:(NSArray<id<MZSelectorViewActionHandler>>*)selectionHandlers {
    NSAssert(idleHandler != nil, @"Idle handler is needed!");
    
    self = [super init];
    if (self) {
        _idleHandler = idleHandler;
        _handlers = [NSMutableDictionary dictionary];
        
        NSMutableArray<id<MZSelectorViewActionHandler>> *handlers = [NSMutableArray arrayWithObject:idleHandler];
        [handlers addObjectsFromArray:selectionHandlers];
        
        NSMutableArray<TKState*> *states = [NSMutableArray array];
        NSMutableArray<TKEvent*> *events = [NSMutableArray array];
        
        /* States */
        for (id<MZSelectorViewActionHandler> handler in handlers) {
            TKState *state = [TKState stateWithName:[handler.class name]];
            
            [state setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
                if ([handler respondsToSelector:@selector(selectorView:activateItemAtIndex:)]) {
                    [handler selectorView: (MZSelectorView*)transition.userInfo[kTransitionSelectionView]
                      activateItemAtIndex:((NSNumber      *)transition.userInfo[kTransitionSelectedIndex]).integerValue];
                }
            }];
            
            [state setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
                if ([handler respondsToSelector:@selector(deactivateSelectedItemInSelectorView:)]) {
                    [handler deactivateSelectedItemInSelectorView:(MZSelectorView*)transition.userInfo[kTransitionSelectionView]];
                }
            }];
            
            [states addObject:state];
            [_handlers setValue:handler forKey:state.name];
        }
                     
                TKState   *idleState       =  states.firstObject;
        NSArray<TKState*> *selectionStates = [states subarrayWithRange:NSMakeRange(1, states.count-1)];
        
        /* Events */
        [events addObject:[TKEvent eventWithName:[idleHandler.class name] transitioningFromStates:selectionStates toState:idleState]];
        for (TKState *state in selectionStates) {
            [events addObject:[TKEvent eventWithName:state.name transitioningFromStates:@[idleState] toState:state]];
        }
        
        /* State Machine */
        _stateMachine = [TKStateMachine new];
        [_stateMachine addStates:states];
        [_stateMachine addEvents:events];
        
        _stateMachine.initialState = idleState;
        [_stateMachine activate];
        
    }
    return self;
}

- (BOOL)activateHandlerWithName:(NSString*)handlerName inSelectorView:(MZSelectorView*)selectorView withSelectedIndex:(NSUInteger)index {
    return [_stateMachine fireEvent:handlerName
                           userInfo:@{ kTransitionSelectionView : selectorView,
                                       kTransitionSelectedIndex : @(index) }
                              error:nil];
}

- (id<MZSelectorViewActionHandler>)activeHandler {
    return _handlers[_stateMachine.currentState.name];
}

@end

@implementation MZSelectorViewHandlerController(Idle)

- (BOOL)isIdle {
    return self.activeHandler == _idleHandler;
}

@end
