//
//  RCTBaiduMapViewManager.m
//  RCTBaiduMap
//
//  Created by lovebing on Aug 6, 2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "RCTBaiduMapViewManager.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

@implementation RCTBaiduMapViewManager;

RCT_EXPORT_MODULE(RCTBaiduMapView)

RCT_EXPORT_VIEW_PROPERTY(mapType, int)
RCT_EXPORT_VIEW_PROPERTY(zoom, float)
RCT_EXPORT_VIEW_PROPERTY(trafficEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(baiduHeatMapEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(marker, NSDictionary*)
RCT_EXPORT_VIEW_PROPERTY(markers, NSArray*)
RCT_EXPORT_VIEW_PROPERTY(polylines, NSArray*)
RCT_EXPORT_VIEW_PROPERTY(centerDict, NSDictionary*)

RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY(center, CLLocationCoordinate2D, RCTBaiduMapView) {
    [view setCenterCoordinate:json ? [RCTConvert CLLocationCoordinate2D:json] : defaultView.centerCoordinate];
}


+(void)initSDK:(NSString*)key {
    
    BMKMapManager* _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:key  generalDelegate:nil];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
}

- (UIView *)view {
    RCTBaiduMapView* mapView = [[RCTBaiduMapView alloc] init];
    mapView.delegate = self;
    return mapView;
}

-(void)mapview:(BMKMapView *)mapView
 onDoubleClick:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onDoubleClick");
    NSDictionary* event = @{
                            @"type": @"onMapDoubleClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

-(void)mapView:(BMKMapView *)mapView
onClickedMapBlank:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onClickedMapBlank");
    NSDictionary* event = @{
                            @"type": @"onMapClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

-(void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    NSDictionary* event = @{
                            @"type": @"onMapLoaded",
                            @"params": @{}
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

-(void)mapView:(BMKMapView *)mapView
didSelectAnnotationView:(BMKAnnotationView *)view {
    NSLog(@"%@",[((ZLPointAnnotation *)[view annotation]) extra]);
    NSDictionary* event = @{
                            @"type": @"onMarkerClick",
                            @"params": @{
                                    @"title": [[view annotation] title],
                                    @"position": @{
                                            @"latitude": @([[view annotation] coordinate].latitude),
                                            @"longitude": @([[view annotation] coordinate].longitude)
                                            }
                                    }
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

- (void) mapView:(BMKMapView *)mapView
 onClickedMapPoi:(BMKMapPoi *)mapPoi {
    NSLog(@"onClickedMapPoi");
    NSDictionary* event = @{
                            @"type": @"onMapPoiClick",
                            @"params": @{
                                    @"name": mapPoi.text,
                                    @"uid": mapPoi.uid,
                                    @"latitude": @(mapPoi.pt.latitude),
                                    @"longitude": @(mapPoi.pt.longitude)
                                    }
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        newAnnotationView.pinColor =
        BMKPinAnnotationColorGreen;
        newAnnotationView.animatesDrop = NO;
        NSDictionary * extra = ((ZLPointAnnotation *)annotation).extra;
        float heading = 0.0;
        if (extra) {
            if (extra[@"imageName"] && ![extra[@"imageName"] isEqualToString:@""]) {
                newAnnotationView.image = [UIImage imageNamed:((ZLPointAnnotation *)annotation).extra[@"imageName"]];
                newAnnotationView.centerOffset = CGPointMake(0, -(newAnnotationView.frame.size.height/2));
                return newAnnotationView;
            }
            heading = -1*[extra[@"heading"] floatValue];
        }
        
        newAnnotationView.image = [self image:[UIImage imageNamed:@"ico_car.png"] heading:heading ];
        newAnnotationView.centerOffset = CGPointMake(0, 0);
        return newAnnotationView;
    }
    return nil;
}
//添加轨迹
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]){
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.lineWidth = 4.0;
        polylineView.strokeColor = [[self stringToColor:@"#24ba8e"] colorWithAlphaComponent:1];
        return polylineView;
    }
    return nil;
}
-(void)mapStatusDidChanged: (BMKMapView *)mapView     {
    NSLog(@"mapStatusDidChanged");
    CLLocationCoordinate2D targetGeoPt = [mapView getMapStatus].targetGeoPt;
    NSDictionary* event = @{
                            @"type": @"onMapStatusChange",
                            @"params": @{
                                    @"target": @{
                                            @"latitude": @(targetGeoPt.latitude),
                                            @"longitude": @(targetGeoPt.longitude)
                                            },
                                    @"zoom": @"",
                                    @"overlook": @""
                                    }
                            };
    [self sendEvent:(RCTBaiduMapView *)mapView params:event];
}

-(void)sendEvent:(RCTBaiduMapView *) mapView params:(NSDictionary *) params {
    if (!mapView.onChange) {
        return;
    }
    mapView.onChange(params);
}
- (UIColor *) stringToColor:(NSString *)str
{
    if (!str || [str isEqualToString:@""]) {
        return nil;
    }
    unsigned red,green,blue;
    NSRange range;
    range.length = 2;
    range.location = 1;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&red];
    range.location = 3;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&green];
    range.location = 5;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&blue];
    UIColor *color= [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1];
    return color;
}

-(UIImage*)image:(UIImage *)defaultImage heading:(CGFloat)degree{
    //将image转化成context
    //获取图片像素的宽和高
    size_t width =  CGImageGetWidth(defaultImage.CGImage);
    size_t height = CGImageGetHeight(defaultImage.CGImage);
    
    //颜色通道为8 因为0-255 经过了8个颜色通道的变化
    //每一行图片的字节数 因为我们采用的是ARGB/RGBA 所以字节数为 width * 4
    size_t bytesPerRow =width * 4;
    //图片的透明度通道
    CGImageAlphaInfo info =kCGImageAlphaPremultipliedFirst;
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault|info);
    
    if (!context) {
        return nil;
    }
    //将图片渲染到图形上下文中
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), defaultImage.CGImage);
    
    //旋转context
    uint8_t* data =(uint8_t*) CGBitmapContextGetData(context);
    //旋转欠的数据
    vImage_Buffer src = { data,height,width,bytesPerRow};
    //旋转后的数据
    vImage_Buffer dest= { data,height,width,bytesPerRow};
    
    //背景颜色
    Pixel_8888  backColor = {0,0,0,0};
    //填充颜色
    vImage_Flags flags = kvImageBackgroundColorFill;
    
    vImageRotate_ARGB8888(&src, &dest, nil, degree * M_PI/180.f, backColor, flags);
    
    //将conetxt转换成image
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage  * rotateImage =[UIImage imageWithCGImage:imageRef scale:defaultImage.scale orientation:defaultImage.imageOrientation];
    
    return  rotateImage;
}

@end

