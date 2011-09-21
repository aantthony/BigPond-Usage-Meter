/*
 
 UMUsageInfo.m
 UsageMeter
 
 Created by Anthony Foster on 21/09/11.
 
 Copyright (c) 2011 Anthony Foster.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "UMUsageInfo.h"
NSString * const kUsageMeterGotoURL = @"https://my.bigpond.com/mybigpond/myaccount/myusage/daily/default.do";
NSString * const kUsageMeterPostURL = @"https://signon.bigpond.com/login";
//NSString * const kUsageMeterPostURL = @"http://localhost/test.html";
NSString * const kUsageMeterUA      = @"Mozilla/5.0 (Macintosh; U; en-us) UsageMeterDataUpdater/3.0";
NSString * const kUsageMeterCT      = @"application/x-www-form-urlencoded";

@implementation UMUsageInfo
- (void) dealloc{
    NSLog(@"I was dealloced!");
}

- (UMUsageInfo *) initWithUser:(NSString*)username password:(NSString*)password{
    
    if((self = [super init])){
        
        NSString * post = [NSString stringWithFormat:@"username=%@&password=%@&goto=%@&encoded=false&gx_charset=UTF-8",
                           [username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [kUsageMeterGotoURL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
        
        NSData * postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
        
        [request setURL:[NSURL URLWithString:kUsageMeterPostURL]];
        
        [request setHTTPMethod:@"POST"];
        [request setHTTPShouldHandleCookies:YES];
        
        [request setValue:kUsageMeterUA forHTTPHeaderField:@"User-Agent"];
        [request setValue:kUsageMeterCT forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        
        NSHTTPURLResponse *response=nil;
        NSError *err = nil;
        
        NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &err];
        
        if(!data){
            NSLog(@"%@",[NSString stringWithFormat:@"No data?: %@",[err localizedDescription]]);
        }
        if(!response){
            NSLog(@"No response??");
        }
        
        UMUsageData usage;
        int UMError = UMUsageDataFromHTML([data bytes], (int)[data length], &usage);
        if(UMError){
            
        }
    }
    return self;
}

+ (UMUsageInfo *) usageInfoWithUser:(NSString*)username password:(NSString*)password{
    UMUsageInfo *ui = [[UMUsageInfo alloc] initWithUser:username password:password];
    [ui autorelease];
    
    return ui;
}



@end
