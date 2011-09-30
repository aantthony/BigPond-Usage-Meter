//
//  UMKeychain.m
//  UsageMeter
//
//  Created by Anthony Foster on 30/09/11.
//  Copyright (c) 2011 Anthony Foster. All rights reserved.
//

#import "UMKeychain.h"
#import <Security/Security.h>

int stringByteLength(const NSString *string);
int stringByteLength(const NSString *string) {
	const char * const utf8String = [string UTF8String];
	return (int)(utf8String ? strlen(utf8String) : 0);
}


@implementation UMKeychain

+ (UMKeychain *) standardKeychain{
    static UMKeychain *sharedInstance;
    if (!sharedInstance) sharedInstance = [[self alloc] init];
    return sharedInstance;
}


NSString * kServer  = @"signon.bigpond.com";
UInt16	   kPort    = 443;
NSString * kPath    = @"";

- (void) setPassword:(NSString *) password forUsername:(NSString *) username{
    [self removePasswordForUsername:username];

	if (password.length){
        SecKeychainAddInternetPassword(NULL,
                                       stringByteLength(kServer), [kServer UTF8String],
                                       0, NULL,
                                       stringByteLength(username), [username UTF8String],
                                       stringByteLength(kPath), [kPath UTF8String],
                                       kPort, kSecProtocolTypeHTTPS,
                                       kSecAuthenticationTypeHTMLForm,
                                       stringByteLength(password), [password UTF8String],
                                       NULL
                                       );
    }
}
- (NSString *) passwordForUsername:(NSString *) username{
    
	NSString *string = nil;
	UInt32 passwordLength = 0;
	void *password = NULL;
    
	OSStatus status = SecKeychainFindInternetPassword(NULL,
                                                      stringByteLength(kServer), [kServer UTF8String],
                                                      0, NULL,
                                                      stringByteLength(username), [username UTF8String],
                                                      stringByteLength(kPath), [kPath UTF8String],
                                                      kPort, kSecProtocolTypeHTTPS,
                                                      kSecAuthenticationTypeHTMLForm,
                                                      &passwordLength, &password,
                                                      NULL
                                                      );
	if (status == noErr){
		string = [[NSString alloc] initWithBytes:(const void *)password length:passwordLength encoding:NSUTF8StringEncoding];
        SecKeychainItemFreeContent(NULL, password);
    }
    return [string autorelease];
}
- (void) removePasswordForUsername:(NSString *) username{
    SecKeychainItemRef keychainItem = NULL;
	OSStatus status = SecKeychainFindInternetPassword(NULL,
                                                      stringByteLength(kServer), [kServer UTF8String],
                                                      0, NULL,
                                                      stringByteLength(username), [username UTF8String],
                                                      stringByteLength(kPath), [kPath UTF8String],
                                                      kPort, kSecProtocolTypeHTTPS,
                                                      kSecAuthenticationTypeHTMLForm,
                                                      NULL,
                                                      NULL,
                                                      &keychainItem);
	if (status == noErr){
		SecKeychainItemDelete(keychainItem);
    }
}

@end
