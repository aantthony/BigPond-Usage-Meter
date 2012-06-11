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
NSString * const kUsageMeterGotoURL = @"https://usagemeter.bigpond.com/daily.do";
NSString * const kUsageMeterPostURL = @"https://signon.bigpond.com/login";
NSString * const kUsageMeterRef     = @"https://my.bigpond.com/mybigpond/myaccount/myusage/default.do";
NSString * const kUsageMeterUA      = @"Mozilla/5.0 (Macintosh; U; en-us) UsageMeterDataUpdater/3.0";
NSString * const kUsageMeterCT      = @"application/x-www-form-urlencoded";
int const dumpErrorAnywayDebug = 0;
@implementation UMUsageInfo
/*
 
 UMError_OK=0,
 UMError_CouldNotLoadHTML,
 UMError_CouldNotEvaluateExpression,
 UMError_CouldNotCreateXPathContext,
 UMError_NullNodeSet,
 UMError_DateFieldMissing,
 UMError_FieldsMissing,
 UMError_TotalsFieldsMissing,
 UMError_TableNotFound,
 UMError_TooManyTablesFound,
 UMError_DateParseError,
 UMError_InvalidPassword,
 UMError_InternetOffline,
 UMError_AccountLocked,
 UMError_CouldNotParsePlanSize
 */

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
        case UMError_InternetOffline:
            return @"Internet Offline";
        case UMError_AccountLocked:
            return @"Account Locked";
        case UMError_CouldNotParsePlanSize:
            return @"Could Not Read Plan Size";
        case UMError_OK:
        default:
            return @"";
        
    }
}

BOOL isFatal(int err);
BOOL isFatal(int err){
    switch (err) {
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
        case UMError_CouldNotParsePlanSize:
            return YES;
        case UMError_InvalidPassword:
        case UMError_InternetOffline:
        case UMError_AccountLocked:
        case UMError_TimedOut:
        case UMError_OK:
            return NO;
        default:
            return YES;
            
    }
                
}

- (NSString *)protectPrivateData:(NSString *)input{
    return [[[[[[[[input stringByReplacingOccurrencesOfString:@"0" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"2" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"4" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"5" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"6" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"7" withString:@"1"]
    stringByReplacingOccurrencesOfString:@"8" withString:@"1"]
stringByReplacingOccurrencesOfString:@"9" withString:@"1"];
}
- (void)dumpErrorReport:(NSString *)errorname data:(NSData *)data{
    
    if(errorname == nil){
        errorname = @"No Error";
    }
    
    
    NSFileManager *fileManager= [NSFileManager defaultManager];
    

    NSError *err;
    
    NSURL * path = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
    NSURL *dumpFolder = [path URLByAppendingPathComponent:@"UsageMeter"];
    NSString *dstring = [dumpFolder path];
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy-HH-mm"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    
    [formatter release];
    
    NSURL *u_Data = [dumpFolder URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.html", dateString]];
    NSURL *u_Info = [dumpFolder URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-info.txt", dateString]];
    [fileManager createDirectoryAtPath:(NSString *)dstring withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *d = [self protectPrivateData:[NSString stringWithUTF8String:[data bytes]]];
    NSData * mdata = [d dataUsingEncoding:NSUTF8StringEncoding];
    if(![mdata writeToURL:u_Data options:NSDataWritingAtomic error:&err]){
        NSLog(@"%@", err);
    }
    NSData *ndata = [errorname dataUsingEncoding:NSUTF8StringEncoding];
    if(![ndata writeToURL:u_Info options:NSDataWritingAtomic error:&err]){
        NSLog(@"%@", err);
    }
    NSLog(@"Error log created: %@", u_Data);
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
        [request setValue:kUsageMeterRef forHTTPHeaderField:@"Referer"];
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
            }else if([err code] == -1001){
                *error = UMError_TimedOut;
            }
        }else if(!response){
            *error = 10000;
        }
        if(!*error){
            *error = UMUsageDataFromHTML([data bytes], (int)[data length], &usage);
        }
        if(*error || dumpErrorAnywayDebug){
            if(isFatal(*error) || dumpErrorAnywayDebug){
                NSString *name= [UMUsageInfo stringForError:*error];
                NSString *d = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [self dumpErrorReport:name data:data];
                [d autorelease];
                [NSException raise:name format:@"Error: %@ (%d)\n\n\n\n Data: START DATA%@END DATA", name, *error, d];
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
