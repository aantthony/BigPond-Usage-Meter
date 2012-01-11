//
//  AppLoginItem.h
//  UsageMeter
//
//  Created by Anthony Foster on 11/01/12.
//  Copyright (c) 2012 Anthony Foster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

@interface AppLoginItem : NSObject

+ (BOOL) toggleBundleIDAsLoginItem:(NSString *)bundleID state:(BOOL)state;
+ (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID;
@end
