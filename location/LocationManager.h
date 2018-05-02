//
//  LocationManager.h
//  location
//
//  Created by yfxiari on 2018/4/28.
//  Copyright © 2018年 Qingchifan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

static NSNotificationName kLocationDidNotAuthNotification = @"kLocationDidNotAuthNotification";
static NSNotificationName kCityDidChangedNotification = @"kCityDidChangedNotification";//您所在的城市位置发生了改变

@class LocationManager;
@protocol LocationManagerDelegate<NSObject>
- (void)locationManagerDidUpdateLocation:(LocationManager *)manager;
- (void)locationManager:(LocationManager *)manager updateLocationError:(NSError *)error;
@end

@interface LocationManager : NSObject
@property (nonatomic, strong, readonly) CLPlacemark *livePlacemark;//实时的位置
@property (nonatomic, strong) CLPlacemark *currentPlacemark;//当前程序显示的位置
@property (nonatomic, weak) id<LocationManagerDelegate> delegate;
@property (nonatomic, assign) BOOL needLiveUpdate;//需要实时更新, 不会停止，大概十多秒就会更新一次。
@property (nonatomic, assign) CLLocationDistance distanceFilter;//实时更新情况下，移动次距离才会更新位置。默认1km
@property (nonatomic, assign) BOOL allowsBackgroundLocationUpdates;//设置后台更新，需要开启后台定位

+ (instancetype)shareInstance;
+ (BOOL)locationServicesEnabled;//判断是否开启位置权限
- (void)startUpdatingLocation; //needLiveUpdate提前设置
- (void)getLivePlacemark:(void(^)(CLPlacemark *placemark))getPlacemarkBlock errorBlock:(void(^)(NSError *error))errorBlock;//获取实时位置
- (void)showOpenAuthAlert;
@end




/**
 有几个地方没有做考虑：位置没有获取到，无网络，后台定位。
 
 */
