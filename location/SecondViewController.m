//
//  SecondViewController.m
//  location
//
//  Created by yfxiari on 2018/4/30.
//  Copyright © 2018年 Qingchifan. All rights reserved.
//

#import "SecondViewController.h"
#import "LocationManager.h"

@interface SecondViewController ()<LocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *liveLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentLocationLabel;
@property (weak, nonatomic) IBOutlet UIButton *getLiveLocationBtn;

@end

@implementation SecondViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cityChanged) name:kCityDidChangedNotification object:nil];

    if ([LocationManager shareInstance].currentPlacemark) {
        self.currentLocationLabel.text = [LocationManager shareInstance].currentPlacemark.locality;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)setUseDele:(BOOL)useDele {
    _useDele = useDele;
    if (useDele) {
        [LocationManager shareInstance].delegate = self;
    }else {
        [LocationManager shareInstance].delegate = nil;
    }
     
}

- (IBAction)getLocationButtonClick:(id)sender {
    
    if (self.useDele) {
        if ([LocationManager locationServicesEnabled]) {
            [[LocationManager shareInstance] startUpdatingLocation];
        }else {
            [[LocationManager shareInstance] showOpenAuthAlert];
        }
    }else {
        if ([LocationManager locationServicesEnabled]) {
            [[LocationManager shareInstance] getLivePlacemark:^(CLPlacemark *placemark) {
            self.liveLocationLabel.text = placemark.locality;
            if ([LocationManager shareInstance].currentPlacemark == nil) {
                self.currentLocationLabel.text = placemark.locality;
                [LocationManager shareInstance].currentPlacemark = placemark;
            }
        } errorBlock:^(NSError *error) {
            
        }];
        }else {
            [[LocationManager shareInstance] showOpenAuthAlert];
        }
        
    }
}


#pragma mark - delegate
- (void)locationManagerDidUpdateLocation:(LocationManager *)manager {
    self.liveLocationLabel.text = manager.livePlacemark.locality;
    if ([LocationManager shareInstance].currentPlacemark == nil) {
        _currentLocationLabel.text = self.liveLocationLabel.text;
        [LocationManager shareInstance].currentPlacemark = manager.livePlacemark;
    }
}

- (void)locationManager:(LocationManager *)manager updateLocationError:(NSError *)error {
    
}

#pragma mark - other

- (void)switchCityAlert{
    CLPlacemark * livePlacemark = [LocationManager shareInstance].livePlacemark;
    NSString *message = [NSString stringWithFormat:@"定位显示你在%@, 是否切换当前城市至%@", livePlacemark.locality, livePlacemark.locality];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"切换城市" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:cancel];
    __weak __typeof(&*self)weakSelf = self;
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [LocationManager shareInstance].currentPlacemark = livePlacemark;
        weakSelf.currentLocationLabel.text = livePlacemark.locality;
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:sure];
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)cityChanged {
    [self switchCityAlert];
}

@end
