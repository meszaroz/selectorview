//
//  MZSelectorViewController.h
//  MZSelectorView
//
//  Created by Zoltan Meszaros on 4/4/17.
//  Copyright © 2017 Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorView.h"

@interface MZSelectorViewController : UIViewController <MZSelectorViewDelegate, MZSelectorViewDataSource, MZSelectorViewDelegateLayout>

@property (strong, nonatomic, readonly) MZSelectorView *selectorView;

@end
