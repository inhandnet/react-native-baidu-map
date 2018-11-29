//
//  ZLPointAnnotation.h
//  iwos
//
//  Created by zhanglinfeiMacAir on 2018/8/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <BaiduMapAPI_Map/BMKMapComponent.h>
@class Item;
@interface ZLPointAnnotation : BMKPointAnnotation
@property (strong, nonatomic) NSDictionary * extra;
@property (weak, nonatomic) id <BMKAnnotation>delegate;
@end
