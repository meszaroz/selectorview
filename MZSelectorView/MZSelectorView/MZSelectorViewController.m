//
//  MZSelectorViewController.m
//  MZSelectorView
//
//  Created by Mészáros Zoltán on 2017. 03. 11..
//  Copyright © 2017. Mészáros Zoltán. All rights reserved.
//

#import "PureLayout.h"
#import "MZSelectorViewController.h"
#import "MZSelectorViewItem.h"
#import "CALayer+Anchor.h"

@interface MZSelectorViewController () <MZSelectorViewDelegate, MZSelectorViewDataSource, MZSelectorViewDelegateLayout> {
}

@end

@implementation MZSelectorViewController

- (void)initialize {
    _selectorView = [MZSelectorView new];
    _selectorView.delegate   = self;
    _selectorView.dataSource = self;
    _selectorView.layout     = self;
    
    //_selectorView.backgroundColor = [UIColor yellowColor];
    
    //_selectorView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:_selectorView];
    [_selectorView autoPinEdgesToSuperviewEdges];
    
    /*UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [button autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [button autoSetDimensionsToSize:CGSizeMake(50., 50.)];
    [button addTarget:self action:@selector(action1) forControlEvents:UIControlEventTouchUpInside];
    */
    /*UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [button autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [button autoSetDimensionsToSize:CGSizeMake(50., 50.)];
    [button addTarget:self action:@selector(action2) forControlEvents:UIControlEventTouchUpInside];*/
    
}

- (void)action1 {
    [_selectorView activateViewItemAtIndex:3];
}

- (void)action2 {
    [_selectorView deactivateActiveViewItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
}

- (void)viewWillAppear:(BOOL)animated {
    [_selectorView reloadData];
    /*
    _view = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 50, 50)];
    _view.backgroundColor = [UIColor redColor];
    
    [_contentView addSubview:_view];
    _view.frame = CGRectMake(200, 200, 200, 200);
    _view.layer.position = CGPointMake(self.view.center.x, 500);
    
    CALayer *layer = [CALayer new];
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [_view.layer addSublayer:layer];
    layer.frame = CGRectMake(0, 0, 200, 100);
    
    //[view autoSetDimensionsToSize:CGSizeMake(50, 50)];
    //[self transformViewAtIndex:0 atNominalPosition:CGPointZero];
    //[_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x, _scrollView.contentOffset.y+1) animated:NO];
    */
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {    
    //_selectorView.contentOffset = CGPointMake(_selectorView.contentOffset.x, _selectorView.contentOffset.y+1);
    [super viewDidAppear:animated];
    //[self transformViewAtIndex:0 atNominalPosition:CGPointZero];
}

- (void)viewDidLayoutSubviews {
    //[self transformViewAtIndex:0 atNominalPosition:CGPointZero];
}
/*
- (void)transformView:(UIView*)view {
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0 / 700;
    t = CATransform3DRotate(t, -(40)*M_PI/180., 1.0, 0.0, 0.0);
    //t = CATransform3DTranslate(t, 0, -0, -200);
    
    view.layer.anchorPoint = CGPointMake(0.5, 0.0);
    
    //view.layer.transform = t;

    [UIView animateWithDuration:3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         view.alpha = 1.0;
                         //view.layer.bounds = CGRectMake(view.layer.bounds.origin.x, view.layer.bounds.origin.y, view.layer.bounds.size.width*0.9, view.layer.bounds.size.height*0.6);
                         //view.layer.position = CGPointMake(view.layer.bounds.size.width/2, 500);
                         //view.layer.transform = t;
                     }
                     completion:^(BOOL finished) {
                         //[displayLink invalidate];
                     }];
    
}
*/
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIScrollViewDelegate
/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"%f-%f-%f-%f-%f-%f", _view.center.y,_view.bounds.origin.y,[_view convertPoint:_view.bounds.origin toView:self.view].y,_view.layer.frame.size.height, [_view convertPoint:_view.layer.position toView:self.view].y, _scrollView.contentOffset.y);
    [self transformViewAtIndex:0 atNominalPosition:CGPointZero];
}
 */

/* DELEGATE/DATASOURCE */
- (NSUInteger)numberOfItemsInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return 100;
}

- (MZSelectorViewItem * _Nonnull)selectorView:(MZSelectorView * _Nonnull)selectorView viewItemAtIndex:(NSUInteger)index {
    NSArray *colors = @[[UIColor redColor],
                        [UIColor greenColor],
                        [UIColor blueColor],
                        [UIColor magentaColor],
                        [UIColor yellowColor],
                        [UIColor grayColor],
                        [UIColor cyanColor],
                        [UIColor orangeColor],
                        [UIColor purpleColor],];
    
    
    MZSelectorViewItem *out = [MZSelectorViewItem new];
    /*if (index == 4)
        out.backgroundColor = [UIColor magentaColor];*/
    out.contentView.backgroundColor = colors[index%colors.count];
    out.contentView.layer.borderColor = [UIColor whiteColor].CGColor;
    out.contentView.layer.borderWidth = 2;
   
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    [out.contentView addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [button autoSetDimensionsToSize:CGSizeMake(50, 50)];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor yellowColor];
    [out.contentView addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:30];
    [button autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [button addTarget:self action:@selector(action2) forControlEvents:UIControlEventTouchUpInside];
    
    
    return out;
}

- (CGFloat)minimalItemDistanceInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 120. : 100.0;
}

- (CGFloat)topInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return 40;
}

- (CGFloat)bottomInsetInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return 120;
}

- (void)selectorView:(MZSelectorView *)selectorView willDisplayViewItem:(MZSelectorViewItem *)item atIndex:(NSUInteger)index {
    /*UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor redColor];
    [item.contentView addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [button autoSetDimensionsToSize:CGSizeMake(50, 50)];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor yellowColor];
    [item.contentView addSubview:button];
    [button autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    [button autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:30];
    [button autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [button addTarget:self action:@selector(action2) forControlEvents:UIControlEventTouchUpInside];*/
}

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView transformContentLayer:(CALayer* _Nonnull)layer inViewItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index {
    
    // LOGIC - BEGIN - delegate - all views in collection get this
    CGPoint point = [selectorView.scrollView convertPoint:item.frame.origin toView:self.view];
    
    [layer setCorrectedAnchorPoint:CGPointMake(0.5, 0.0)];
    
    CGFloat pos = point.y/800;
    //NSLog(@"%f", [item.contentView convertPoint:item.contentView.bounds.origin toView:self.view].y);
    //NSLog(@"pos: %f, %@, y2:%f, %@ \n",pos,NSStringFromCGRect(_scrollView.bounds),[_view convertPoint:_view.bounds.origin toView:self.view].y, NSStringFromCGRect(self.view.bounds));
    
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0 / 700;
    CGFloat rot = MIN(-10,-(10+50*pos));
    t = CATransform3DRotate(t, rot*M_PI/180., 1.0, 0.0, 0);
    //t = CATransform3DTranslate(t, 0, -0, -200);
    pos = 0.7 + (0.3 * MAX(0.0, pos));
    t = CATransform3DScale(t, pos, pos, 1);
    layer.transform = t;
    
    /*dispatch_async(dispatch_get_main_queue(), ^{
        item.contentView.layer.position = CGPointMake(item.contentView.layer.position.x,0.0);
    });
    */
    //NSLog(@"%f",point.y);
    //NSLog(@"%f",pos);
    
    
    // LOGIC - END
}

/*
- (void)transformViewAtIndex:(NSUInteger)index atNominalPosition:(CGPoint)position {
    
    // LOGIC - BEGIN - delegate - all views in collection get this
    
    _view.layer.anchorPoint = CGPointMake(0.5, 0.0);
    
    CGFloat pos = [_view convertPoint:_view.bounds.origin toView:self.view].y/600;
    NSLog(@"pos: %f, %@, y2:%f, %@ \n",pos,NSStringFromCGRect(_scrollView.bounds),[_view convertPoint:_view.bounds.origin toView:self.view].y, NSStringFromCGRect(self.view.bounds));
    
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0 / 700;
    t = CATransform3DRotate(t, -(10+50*pos)*M_PI/180., 1.0, 0.0, 0);
    //t = CATransform3DTranslate(t, 0, -0, -200);
    pos = 0.7 + (0.3 * MAX(0.0, pos));
    t = CATransform3DScale(t, pos, pos, 1);
    _view.layer.transform = t;
    
    
    //NSLog(@"%f",pos);
    
    
    // LOGIC - END
}

 */
/* ACCESS */

@end
