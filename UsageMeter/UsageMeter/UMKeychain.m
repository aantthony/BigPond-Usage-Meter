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
    if (!password.length){
        return;
    }
    
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
        //Key is already there. Modifiy instead of add
		OSStatus err = SecKeychainItemModifyContent(keychainItem,
                                                    NULL,
                                                    stringByteLength(password),
                                                    [password UTF8String]);
        if(err == noErr){
            
        }else{
            //NSLog(@"SecKeychainItemModifyContent() failed: %d", err);
        }
        return;
    }else{
        OSStatus err = SecKeychainAddInternetPassword(NULL,
                                                      stringByteLength(kServer), [kServer UTF8String],
                                                      0, NULL,
                                                      stringByteLength(username), [username UTF8String],
                                                      stringByteLength(kPath), [kPath UTF8String],
                                                      kPort, kSecProtocolTypeHTTPS,
                                                      kSecAuthenticationTypeHTMLForm,
                                                      stringByteLength(password), [password UTF8String],
                                                      NULL
                                                      );
        if(err == noErr){
            
        }else{
            //NSLog(@"SecKeychainAddInternetPassword() failed: %d", err);
        }
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
    }else{
        //NSLog(@"SecKeychainFindInternetPassword: %@", SecCopyErrorMessageString(status, NULL));
        return nil;
    }
    return [string autorelease];
}
/*
 
 Removed because it shouldn't be used in this case: (From docs)
    
    Do not delete a keychain item and recreate it in order to modify it; instead, use the SecKeychainItemModifyContent or SecKeychainItemModifyAttributesAndData function to modify an existing keychain item. When you delete a keychain item, you lose any access controls and trust settings added by the user or by other applications.
 
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
 */

@end
