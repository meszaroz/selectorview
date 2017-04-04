//
//  MZSelectorViewController.m
//  MZSelectorView
//
//  Created by Zoltan Meszaros on 4/4/17.
//  Copyright © 2017 Mészáros Zoltán. All rights reserved.
//

#import "MZSelectorViewController.h"
#import "MZSelectorView_p.h"

@interface MZSelectorViewController ()
@end

@implementation MZSelectorViewController

- (void)loadView {
    _selectorView = [MZSelectorView new];
    _selectorView.delegate   = self;
    _selectorView.dataSource = self;
    _selectorView.layout     = self;
    _selectorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = _selectorView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)numberOfItemsInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return 0;
}

- (MZSelectorViewItem * _Nonnull)selectorView:(MZSelectorView * _Nonnull)selectorView viewItemAtIndex:(NSUInteger)index {
    return nil;
}

#pragma mark - orientation change
/* - (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator 
   -> not usable, because UIScrollView update is executed before it is called */

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_selectorView deviceOrientationWillChange];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_selectorView deviceOrientationDidChange];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


@end
