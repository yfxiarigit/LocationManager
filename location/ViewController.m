//
//  ViewController.m
//  location
//
//  Created by yfxiari on 2018/4/28.
//  Copyright © 2018年 Qingchifan. All rights reserved.
//

#import "ViewController.h"
#import "LocationManager.h"
#import "SecondViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *isLiveSegmentControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *isDeleSegmentControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)sureConfigButtonClick:(id)sender {
    if (self.isLiveSegmentControl.selectedSegmentIndex == 0) {
        [LocationManager shareInstance].distanceFilter = kCLDistanceFilterNone;
        [LocationManager shareInstance].needLiveUpdate = YES;
    }else {
        [LocationManager shareInstance].needLiveUpdate = NO;
    }
    SecondViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SecondViewController"];
    vc.useDele = self.isDeleSegmentControl.selectedSegmentIndex == 0 ? YES : NO;
    [self.navigationController pushViewController:vc animated:YES];
    
}



@end
