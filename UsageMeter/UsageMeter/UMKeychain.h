//
//  UMKeychain.h
//  UsageMeter
//
//  Created by Anthony Foster on 30/09/11.
//  Copyright (c) 2011 Anthony Foster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UMKeychain : NSObject
+ (UMKeychain *) standardKeychain;

- (void) setPassword:(NSString *) password forUsername:(NSString *) username;
- (NSString *) passwordForUsername:(NSString *) username;
- (void) removePasswordForUsername:(NSString *) username;

@end
