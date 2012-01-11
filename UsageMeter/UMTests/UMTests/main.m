//
//  main.m
//  UMTests
//
//  Created by Anthony Foster on 12/01/12.
//  Copyright (c) 2012 Anthony Foster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMKeychain.h"
NSString * Keychain(void);
NSString * Keychain(void){
    UMKeychain * k = [UMKeychain standardKeychain];
    [k setPassword:@"test" forUsername:@"test_user"];
    NSString *password = [k passwordForUsername:@"test_user"];
    if(![password isEqualToString:@"test"]){
        return @"CREATE/UPDATE READ";
    }
    return nil;
}
void test(char *name, NSString * error);
void test(char *name, NSString * error){
    if(error == nil){
        printf("[OK]\t%s\n", name);
    }else{
        printf("[X]\t%s: %s\n", name, [error cStringUsingEncoding:NSASCIIStringEncoding]);
    }
}
int main (int argc, const char * argv[])
{

    @autoreleasepool {
        test("Keychain", Keychain());
    }
    return 0;
}

