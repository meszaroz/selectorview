//
//  MZSelectorViewActivationHandler.h
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 24..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorView_p.h"

@interface MZSelectorViewActivationHandler : NSObject <MZSelectorViewActionHandler>
@end

@interface MZSelectorViewActivationHandler(Interface)

- (MZSelectorItem*)activeItemInSelectorView:(MZSelectorView *)selectorView;

- (BOOL)activateViewItemAtIndex:(NSUInteger)index inSelectorView:(MZSelectorView *)selectorView;
- (BOOL)deactivateActiveViewItemInSelectorView:(MZSelectorView *)selectorView;

@end
