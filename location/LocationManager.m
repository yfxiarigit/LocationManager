//
//  LocationManager.m
//  location
//
//  Created by yfxiari on 2018/4/28.
//  Copyright © 2018年 Qingchifan. All rights reserved.
//

#import "LocationManager.h"
#import <UIKit/UIKit.h>

@interface LocationManager()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;// 地理编码器
@property (nonatomic, strong) CLPlacemark *livePlacemark;
@property (nonatomic, copy) void(^getPlacemarkBlock)(CLPlacemark *placemark);
@property (nonatomic, copy) void(^errorBlock)(NSError *error);
@property (nonatomic, assign) BOOL needAlertCityChanged;
@end

@implementation LocationManager
{
    CLPlacemark *_currentPlacemark;
}

+ (instancetype)shareInstance {
    static LocationManager *_shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    return _shareInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 1000;
        
        _geocoder = [[CLGeocoder alloc] init];
        _needLiveUpdate = NO;
        _needAlertCityChanged = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates {
    _allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
    
    _locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
    _locationManager.pausesLocationUpdatesAutomatically = !allowsBackgroundLocationUpdates;//设置是否允许系统自动暂停定位，这里要设置为NO
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    _distanceFilter = distanceFilter;
    _locationManager.distanceFilter = distanceFilter;
}

- (void)setCurrentPlacemark:(CLPlacemark *)currentPlacemark {
    _currentPlacemark = currentPlacemark;
    [NSKeyedArchiver archiveRootObject:currentPlacemark toFile:[LocationManager placemarkArchiverFile]];
}

- (CLPlacemark *)currentPlacemark {
    if (_currentPlacemark) {
        return _currentPlacemark;
    }else {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:[LocationManager placemarkArchiverFile]];
    }
}

- (void)requestLocationServicesAuthorization {
    
    if (_needLiveUpdate) {
        [_locationManager requestAlwaysAuthorization];
    }else {
        [_locationManager requestWhenInUseAuthorization];
    }
}

- (void)getLivePlacemark:(void (^)(CLPlacemark *))getPlacemarkBlock errorBlock:(void (^)(NSError *))errorBlock {
    _getPlacemarkBlock = getPlacemarkBlock;
    _errorBlock = errorBlock;
    
    if (self.livePlacemark && self.needLiveUpdate) {
        if (self.getPlacemarkBlock) {
            self.getPlacemarkBlock(self.livePlacemark);
            self.getPlacemarkBlock = nil;
        }
    }else {
        [self startUpdatingLocation];//重复调用没有关系
    }
}

//是否开启了位置服务
+ (BOOL)locationServicesEnabled {
    return CLLocationManager.locationServicesEnabled;
}

- (void)startUpdatingLocation {
    [self requestLocationServicesAuthorization];
    [_locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    if (!_needLiveUpdate) {
        [_locationManager stopUpdatingLocation];
    }
}


#pragma mark - delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count < 1) return;
    CLLocation *locaiton = locations.lastObject;
    if (locaiton == nil) {
        return;
    }
    [self analyzeLocation:locaiton];
    
    [_geocoder reverseGeocodeLocation:locaiton completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count < 1) return;
        CLPlacemark *placemark = placemarks.lastObject;
        if (placemark == nil) {
            return;
        }
        _livePlacemark = placemark;
        [self analyzePlacemark:placemark];
        [self stopUpdatingLocation];
        if (self.delegate && [self.delegate respondsToSelector:@selector(locationManagerDidUpdateLocation:)]) {
            [self.delegate locationManagerDidUpdateLocation:self];
        }
        if (self.getPlacemarkBlock) {
            self.getPlacemarkBlock(placemark);
            self.getPlacemarkBlock = nil;
        }
        
        [self checkLiveCityIsChanged];
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (error.code == kCLErrorDenied) {
        [self startUpdatingLocation];
        if (self.delegate && [self.delegate respondsToSelector:@selector(locationManager:updateLocationError:)]) {
            [self.delegate locationManager:self updateLocationError:error];
        }
        if (self.errorBlock) {
            self.errorBlock(error);
            self.errorBlock = nil;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (self.needLiveUpdate) {
        if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
            [self startUpdatingLocation];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationDidNotAuthNotification object:nil];
}

- (void)showOpenAuthAlert {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"打开定位开关" message:@"定位服务为开启，请进入系统【设置】>【隐私】>【定位服务】中打开开关，并允许xxapp使用定位服务" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *iKnow = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:iKnow];
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)uploadLocationToServer {
    //self.placemark - > server
}

// 判断实时城市是否发生改变
- (void)checkLiveCityIsChanged {
    if (self.currentPlacemark && ![self.livePlacemark.locality isEqualToString:self.currentPlacemark.locality] && self.needAlertCityChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCityDidChangedNotification object:nil];
        self.needAlertCityChanged = NO;
    }
}

+ (NSString *)placemarkArchiverFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [paths objectAtIndex:0];
    NSString *dstPath = [documentDir stringByAppendingPathComponent:@"placemark.archiver"];
    
    return dstPath;
    
}

#pragma mark - other

- (void)applicationDidEnterBackgroundNotification {
    self.needAlertCityChanged = YES;
}

- (void)analyzeLocation:(CLLocation *)location {
    
//    CLLocationDegrees lat = locaiton.coordinate.latitude;//纬度
//    CLLocationDegrees lon = locaiton.coordinate.longitude;//经度
//    CLLocationDistance altitude = locaiton.altitude; //海拔
//    CLLocationDirection course = locaiton.course;//航向
//    CLLocationSpeed speed = locaiton.speed;//速度
}

- (void)analyzePlacemark:(CLPlacemark *)placemark {
    
//    CLLocation *placemark_location = placemark.location;
//    CLRegion *region = placemark.region;//区域，可以用来区域检测
//    NSString *name = placemark.name;
//    NSString *thoroughfare = placemark.thoroughfare;//街道
//    NSString *subThoroughfare = placemark.subThoroughfare;//子街道
//
//    NSString *city = placemark.locality;
//    if (!city) {
//        city = placemark.administrativeArea;//直辖市
//    }
//    NSString *subLocality = placemark.subLocality;//区
//    NSString *country = placemark.country;//国家
//
}


/**
 最近项目中对于经纬度的反地理编码发现几个坑：
 1.通过系统定位didUpdateLocations方法得到的经纬度，不区分国内国外都是地球坐标（世界标准地理坐标(WGS-84)）
 如果用户通过点击地图，(CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(nullable UIView*)view;方法转换后获得的经纬度，国内的到的是火星坐标（中国国测局地理坐标（GCJ-02）），国外是地球坐标。
 2.reverseGeocodeLocation的坑：在iOS9.XXX中，这个方法需要传入的经纬度必须为地球坐标，而在iOS9之前和iOS10中，这个方法传入的经纬度必须为火星坐标。
 3.地图大头针的MKPointAnnotation设置的经纬度必须为火星坐标，不然会出现偏移
 */

@end
