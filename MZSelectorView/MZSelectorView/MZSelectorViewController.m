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

@interface MZCustomSelectorViewItem : MZSelectorViewItem

@property (strong, nonatomic, readonly) UIButton *button;

@end

@implementation MZCustomSelectorViewItem

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [UIColor yellowColor];
        [self.contentView addSubview:_button];
        [_button autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
        [_button autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:30];
        [_button autoSetDimensionsToSize:CGSizeMake(50, 50)];
    }
    return self;
}

@end

@interface MZSelectorViewController () <MZSelectorViewDelegate, MZSelectorViewDataSource, MZSelectorViewDelegateLayout>
@end

@implementation MZSelectorViewController

- (void)initialize {
    _selectorView = [MZSelectorView new];
    _selectorView.delegate   = self;
    _selectorView.dataSource = self;
    _selectorView.layout     = self;
    [_selectorView registerClass:MZCustomSelectorViewItem.class forViewItemReuseIdentifier:@"ViewItem"];
    [self.view addSubview:_selectorView];
    [_selectorView autoPinEdgesToSuperviewEdges];
}

- (void)action {
    [_selectorView deactivateActiveViewItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
}

- (void)viewWillAppear:(BOOL)animated {
    [_selectorView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate/dataSource
- (NSUInteger)numberOfItemsInSelectorView:(MZSelectorView * _Nonnull)selectorView {
    return 100;
}

- (MZSelectorViewItem * _Nonnull)selectorView:(MZSelectorView * _Nonnull)selectorView viewItemAtIndex:(NSUInteger)index {
    return [selectorView dequeueReusableViewItemWithIdentifier:@"ViewItem"];
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
    NSArray *colors = @[[UIColor redColor],
                        [UIColor greenColor],
                        [UIColor blueColor],
                        [UIColor magentaColor],
                        [UIColor yellowColor],
                        [UIColor grayColor],
                        [UIColor cyanColor],
                        [UIColor orangeColor],
                        [UIColor purpleColor],];
    
    
    item.contentView.backgroundColor = colors[index%colors.count];
    item.contentView.layer.borderColor = [UIColor whiteColor].CGColor;
    item.contentView.layer.borderWidth = 2;

    [((MZCustomSelectorViewItem*)item).button addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
}

- (void)selectorView:(MZSelectorView * _Nonnull)selectorView transformContentLayer:(CALayer* _Nonnull)layer inViewItem:(MZSelectorViewItem * _Nonnull)item atIndex:(NSUInteger)index {
    
    CGPoint point = [selectorView.scrollView convertPoint:item.frame.origin toView:self.view];
    
    [layer setCorrectedAnchorPoint:CGPointMake(0.5, 0.0)];
    
    CGFloat pos = point.y/800;

    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0 / 700;
    CGFloat rot = MIN(-10,-(10+50*pos));
    t = CATransform3DRotate(t, rot*M_PI/180., 1.0, 0.0, 0);
    //t = CATransform3DTranslate(t, 0, -0, -200);
    pos = 0.7 + (0.3 * MAX(0.0, pos));
    t = CATransform3DScale(t, pos, pos, 1);
    layer.transform = t;
}

@end
