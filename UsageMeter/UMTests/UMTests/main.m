//
//  main.m
//  UMTests
//
//  Created by Anthony Foster on 12/01/12.
//  Copyright (c) 2012 Anthony Foster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMKeychain.h"
BOOL Keychain(void);
BOOL Keychain(void){
    UMKeychain * k = [UMKeychain standardKeychain];
    [k setPassword:@"test" forUsername:@"test_user"];
    sleep(20);
    NSString *password = [k passwordForUsername:@"test_user"];
    if([password isEqualToString:@"test"]){
        return YES;
    }else{
        return NO;
    }
}
void test(char *name, BOOL passed);
void test(char *name, BOOL passed){
    if(passed){
        printf("[OK]\t%s\n", name);
    }else{
        printf("[X]\t%s\n", name);
    }
}
int main (int argc, const char * argv[])
{

    @autoreleasepool {
        test("Keychain", Keychain());
    }
    return 0;
}

