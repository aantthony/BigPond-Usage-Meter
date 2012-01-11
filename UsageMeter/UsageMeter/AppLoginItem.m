//
//  AppLoginItem.m
//  UsageMeter
//
//  Created by Anthony Foster on 11/01/12.
//  Copyright (c) 2012 Anthony Foster. All rights reserved.
//

#import "AppLoginItem.h"

@implementation AppLoginItem

+ (BOOL) toggleBundleIDAsLoginItem:(NSString *)bundleID state:(BOOL)state {
    
    return (BOOL)SMLoginItemSetEnabled( (CFStringRef)bundleID, state );
}

+ (BOOL) enableAppIDasLoginItem: (NSString *)appID { return [AppLoginItem toggleBundleIDAsLoginItem:appID state:YES]; }
+ (BOOL) disableAppIDasLoginItem:(NSString *)appID { return [AppLoginItem toggleBundleIDAsLoginItem:appID state:NO];  }

+ (BOOL) restartLoginItemWithAppID:(NSString *)appID {
    
    BOOL bRet = NO;
    bRet = [AppLoginItem disableAppIDasLoginItem:appID];
    if ( bRet ) bRet = [AppLoginItem enableAppIDasLoginItem:appID];
    return bRet;
}

+ (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID {
    
    NSArray * jobDicts = nil;
    jobDicts = (NSArray *)SMCopyAllJobDictionaries( kSMDomainUserLaunchd );
    // Note: Sandbox issue when using SMJobCopyDictionary()
    
    if ( (jobDicts != nil) && [jobDicts count] > 0 ) {
        
        BOOL bOnDemand = NO;
        
        for ( NSDictionary * job in jobDicts ) {
            
            if ( [bundleID isEqualToString:[job objectForKey:@"Label"]] ) {
                bOnDemand = [[job objectForKey:@"OnDemand"] boolValue];
                break;
            } }
        
        CFRelease((CFDictionaryRef)jobDicts); jobDicts = nil;
        return bOnDemand;
        
    } return NO;
}

@end
