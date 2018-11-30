//
//  RCTBaiduMap.m
//  RCTBaiduMap
//
//  Created by lovebing on 4/17/2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "RCTBaiduMapView.h"

@implementation RCTBaiduMapView {
    BMKMapView* _mapView;
    ZLPointAnnotation* _annotation;
    NSMutableArray* _annotations;
}

-(void)setZoom:(float)zoom {
//    NSLog(@"setZoom");
    self.zoomLevel = zoom;
}

-(void)setCenterLatLng:(NSDictionary *)LatLngObj {
//    NSLog(@"setCenterLatLng");
    double lat = [RCTConvert double:LatLngObj[@"lat"]];
    double lng = [RCTConvert double:LatLngObj[@"lng"]];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lng);
    self.centerCoordinate = point;
}

-(void)setMarker:(NSDictionary *)option {
//    NSLog(@"setMarker");
    if(option != nil) {
        if(_annotation == nil) {
            _annotation = [[ZLPointAnnotation alloc]init];
            [self addMarker:_annotation option:option];
        }
        else {
            [self updateMarker:_annotation option:option];
        }
    }
}
-(void)setPolylines:(NSArray *)points{
//    NSLog(@"setPolylines");
    [self removeOverlays:self.overlays];
    if (points != nil) {
        double maxLng = -360;
        double minLng = 360;
        double maxLat = -360;
        double minLat =  360;
        for (NSInteger i = 0; i < points.count; i++)  {
            NSArray * arr = [points objectAtIndex:i];
            NSInteger count = [arr count];
            BMKMapPoint *pointArr = new BMKMapPoint[count];
            for (NSInteger j = 0; j < count; j++)  {
                NSDictionary *option = [arr objectAtIndex:j];
                double lat = [RCTConvert double:option[@"lat"]];
                double lng = [RCTConvert double:option[@"lng"]];
                if (i==0 && j==0) {
                    maxLng = lng;
                    minLng = lng;
                    maxLat = lat;
                    minLat = lat;
                }else{
                    if (lng > maxLng) maxLng = lng;
                    if (lng < minLng) minLng = lng;
                    if (lat > maxLat) maxLat = lat;
                    if (lat < minLat) minLat = lat;
                }
                
                CLLocationCoordinate2D coor;
                coor.latitude = lat;
                coor.longitude = lng;
                BMKMapPoint point = BMKMapPointForCoordinate(coor);
                pointArr[j] = point;
                
            }
            BMKPolyline* polyline = [BMKPolyline polylineWithPoints:pointArr count:count];
            [self addOverlay:polyline];
        }
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);
        BMKCoordinateSpan span = BMKCoordinateSpanMake((maxLat - minLat)*11/10, (maxLng - minLng)*11/10);
        BMKCoordinateRegion region = BMKCoordinateRegionMake(center, span);
        [self setRegion:region animated:YES];
    }
}
-(void)setMarkers:(NSArray *)markers {
    NSInteger markersCount = [markers count];
    if(_annotations == nil) {
        _annotations = [[NSMutableArray alloc] init];
    }
    if(markers != nil) {
        for (NSInteger i = 0; i < markersCount; i++)  {
            NSDictionary *option = [markers objectAtIndex:i];
            
            ZLPointAnnotation *annotation = nil;
            if(i < [_annotations count]) {
                annotation = [_annotations objectAtIndex:i];
            }
            if(annotation == nil) {
                annotation = [[ZLPointAnnotation alloc]init];
                [self addMarker:annotation option:option];
                [_annotations addObject:annotation];
            }
            else {
                [self updateMarker:annotation option:option];
            }
        }
        
        NSInteger _annotationsCount = [_annotations count];
        
        // NSString *smarkersCount = [NSString stringWithFormat:@"%d", markersCount];
        // NSString *sannotationsCount = [NSString stringWithFormat:@"%d", _annotationsCount];
        // NSLog(smarkersCount);
        // NSLog(sannotationsCount);
        
        if(markersCount < _annotationsCount) {
            NSInteger start = _annotationsCount - 1;
            for(NSInteger i = start; i >= markersCount; i--) {
                ZLPointAnnotation *annotation = [_annotations objectAtIndex:i];
                [self removeAnnotation:annotation];
                [_annotations removeObject:annotation];
            }
        }
        [self showAnnotations:_annotations animated:YES];
    }
}

-(CLLocationCoordinate2D)getCoorFromMarkerOption:(NSDictionary *)option {
    double lat = [RCTConvert double:option[@"latitude"]];
    double lng = [RCTConvert double:option[@"longitude"]];
    CLLocationCoordinate2D coor;
    coor.latitude = lat;
    coor.longitude = lng;
    return coor;
}

-(void)addMarker:(ZLPointAnnotation *)annotation option:(NSDictionary *)option {
    [self updateMarker:annotation option:option];
    [self addAnnotation:annotation];
}

-(void)updateMarker:(ZLPointAnnotation *)annotation option:(NSDictionary *)option {
    CLLocationCoordinate2D coor = [self getCoorFromMarkerOption:option];
    NSString *title = [RCTConvert NSString:option[@"title"]];
    if(title.length == 0) {
        title = nil;
    }
    annotation.coordinate = coor;
    annotation.title = title;
    annotation.extra = [RCTConvert NSDictionary:option[@"extra"]];
}


@end
