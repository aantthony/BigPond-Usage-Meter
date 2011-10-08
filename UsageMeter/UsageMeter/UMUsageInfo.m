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
NSString * const kUsageMeterUA      = @"Mozilla/5.0 (Macintosh; U; en-us) UsageMeterDataUpdater/3.0";
NSString * const kUsageMeterCT      = @"application/x-www-form-urlencoded";

@implementation UMUsageInfo
- (void) dealloc{
    NSLog(@"I was dealloced!");
}
- (id) alloc{
    
    NSLog(@"I was alloced!");
    return self;
}

+ (NSString *) stringForError:(int) UMError{
    switch (UMError) {
        case UMError_CouldNotCreateXPathContext:
            return @"CouldNotCreateXPathContext";
        case UMError_CouldNotEvaluateExpression:
            return @"UMError_CouldNotEvaluateExpression";
        case UMError_CouldNotLoadHTML:
            return @"UMError_CouldNotLoadHTML";
        case UMError_DateFieldMissing:
            return @"UMError_DateFieldMissing";
        case UMError_DateParseError:
            return @"UMError_DateParseError";
        case UMError_FieldsMissing:
            return @"UMError_FieldsMissing";
        case UMError_NullNodeSet:
            return @"UMError_NullNodeSet";
        case UMError_TableNotFound:
            return @"UMError_TableNotFound";
        case UMError_TooManyTablesFound:
            return @"UMError_TooManyTablesFound";
        case UMError_TotalsFieldsMissing:
            return @"UMError_TotalsFieldsMissing";
        case UMError_InvalidPassword:
            return @"Invalid Username/Password Combination";
        case UMError_OK:
        default:
            return @"";
        
    }
}

BOOL isFatal(int err);
BOOL isFatal(int err){
    switch (UMError) {
        case UMError_CouldNotCreateXPathContext:
        case UMError_CouldNotEvaluateExpression:
        case UMError_CouldNotLoadHTML:
        case UMError_DateFieldMissing:
        case UMError_DateParseError:
        case UMError_FieldsMissing:
        case UMError_NullNodeSet:
        case UMError_TableNotFound:
        case UMError_TooManyTablesFound:
        case UMError_TotalsFieldsMissing:
            return YES;
        case UMError_InvalidPassword:
        case UMError_OK:
        default:
            return NO;
            
    }
                
}
- (UMUsageInfo *) initWithUser:(NSString*)username password:(NSString*)password error:(int *)error{
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
        *error = 0;
        NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &err];
        if(!data){
            NSLog(@"%@",[NSString stringWithFormat:@"No data?: %@",[err localizedDescription]]);
            if([err code] == -1009){
                *error = UMError_InternetOffline;
            }
        }else if(!response){
            *error = 10000;
        }
        if(!*error){
            *error = UMUsageDataFromHTML([data bytes], (int)[data length], &usage);
        }
        if(*error){
            if(isFatal(*error)){
                NSString *name= [UMUsageInfo stringForError:*error];
                NSString *d = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [d autorelease];
                [NSException raise:name format:@"Error: %@ (%d)\n\n\n\n Data: %@", name, *error, d];
            }else{
                return nil;
            }
        }
    }
    return self;
}

+ (UMUsageInfo *) usageInfoWithUser:(NSString*)username password:(NSString*)password error:(int *)error{
    UMUsageInfo *ui = [[UMUsageInfo alloc] initWithUser:username password:password error: error];
    [ui autorelease];
    
    return ui;
}

- (double) plan{
    return usage.plan;
}
- (double) used{
    return usage.daily[usage.count].total;
}
- (double) daysLeft{
    return 3.0;
}
- (double) percentage{
    return 100.0*[self used]/[self plan];
}
- (double) daysInBillingPeriod{
    return 30.0;
}
- (double) daysInMonth{
    return 30.0;
}
- (double) billingPeriodStartDate{
    return usage.daily[0].date;
}

- (double) dayOfMonth{
	NSInteger dayi;
	
	NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSCalendarUnit unitFlags = NSDayCalendarUnit;
	NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:[NSDate date]];
	dayi= [dateComponents day];
	[calendar release];
	return dayi;
}

- (double) dayOfBillingPeriod{
    return (int)([self dayOfMonth]+[self daysInMonth]-[self billingPeriodStartDate])%(int)[self daysInMonth];
}

- (double) monthPercentage{
    return 100.0*[self dayOfBillingPeriod]/[self daysInBillingPeriod];
}
@end
