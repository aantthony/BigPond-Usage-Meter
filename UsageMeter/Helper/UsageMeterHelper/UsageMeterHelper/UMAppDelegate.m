//
//  UMAppDelegate.m
//  UsageMeterHelper
//
//  Created by Anthony Foster on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UMAppDelegate.h"

@implementation UMAppDelegate
- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/UsageMeter.app"];
    [NSApp terminate:nil];
}

@end
