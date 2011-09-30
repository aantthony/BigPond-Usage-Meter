/*
 
 UMAppDelegate.m
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

#import "UMAppDelegate.h"

#import "LoginItemsAE.h"
#import "UMKeychain.h"

@implementation UMAppDelegate

@synthesize
window = _window,
runAtStartupCheckBox=_runAtStartupCheckBox,
runAtStartupCheckBox2=_runAtStartupCheckBox2,
usernameField=_usernameField,
passwordField=_passwordField,
loginWindow=_loginWindow,
statusMenu=_statusMenu,
signInStatusLabel=_signInStatusLabel,
updatingIndicator=_updatingIndicator,
updateMenuItem=_updateMenuItem,
updatePeriodPopUp=_updatePeriodPopUp;

@synthesize
percentOfMonthLabel=_percentOfMonthLabel,
freeLabel=_freeLabel,
usedMeter=_usedMeter,
timeMeter=_timeMeter,
usedLabel=_usedLabel,
timeLabel=_timeLabel,
userLabel=_userLabel;

@synthesize
setShowModeIconOnlyButton=_setShowModeIconOnlyButton,
setShowModePercentageButton=_setShowModePercentageButton;


@synthesize versionLabel=_versionLabel;

NSString * const kPreferenceKeyNameUsername	= @"Username";
NSString * const kPreferenceKeyNameInterval	= @"UpdateInterval";
NSString * const kPreferenceKeyNameShow     = @"Show";

NSString * const kImageResourceDefaultIcon	= @"bp";
NSString * const kImageResourceFadedIcon    = @"fade";
NSString * const kImageResourceFailIcon		= @"fail";

NSString * const kBundleVersionKeyName		= @"CFBundleVersion";

int			kShowModePercentage			= 0;
int			kShowModeIconOnly			= 1;


#define SECONDS * 1
#define MINUTES * 60 SECONDS


- (void)dealloc {
    [super dealloc];
}

- (void) loadPreferences{
    
    int intervalSetting = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceKeyNameInterval];
    switch (intervalSetting) {
        case 30 MINUTES:
            [_updatePeriodPopUp selectItemAtIndex:0];
            break;
        case 60 MINUTES:
            [_updatePeriodPopUp selectItemAtIndex:1];
            break;
        case 120 MINUTES:
            [_updatePeriodPopUp selectItemAtIndex:2];
            break;
        default:
            break;
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self updateInBackgroundCompleted: nil];
    [_versionLabel setStringValue:[NSString stringWithFormat:
								  @"Version: %@",
								  [[[NSBundle mainBundle] infoDictionary] objectForKey:kBundleVersionKeyName]]];
    [self loadPreferences];
    [self update:nil];
    
}

-(void)awakeFromNib {
    NSLog(@"MEMORY LEAK, awakeFromNib (statusItem retain)");
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[_statusItem setMenu:_statusMenu];
    
	[_statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
	[_statusItem setHighlightMode:YES];
    
    
    if([self doesRunAtStartup]){
        [_runAtStartupCheckBox setState:NSOnState];
        [_runAtStartupCheckBox2 setState:NSOnState];
    }else{
        [_runAtStartupCheckBox setState:NSOffState];
        [_runAtStartupCheckBox2 setState:NSOffState];
    }
    
}


#pragma mark -
#pragma mark Startup
- (BOOL) doesRunAtStartup {
	NSString *thisURL = [[NSBundle mainBundle] bundlePath];
	OSStatus 			err;
	NSArray *			items;
	CFIndex				itemCount;
	items = NULL;
	
	err = LIAECopyLoginItems((CFArrayRef*)&items);
	if (err == noErr) {
		itemCount = [items count];
		for(int i=0;i<itemCount;i++){
			NSDictionary *dict;
			dict=[items objectAtIndex:i];
			NSURL *url = [dict valueForKey:@"URL"];
			NSString* str = [url path];
			if([thisURL isEqualToString:str]){
				[items release];
				return YES;
			}
		}
	}
	[items release];
	return NO;
}

- (BOOL)getFSRef:(FSRef *)aFSRef forString:(NSString *)string {
	return FSPathMakeRef((const UInt8 *)[string UTF8String], aFSRef,NULL) == noErr;
}
- (BOOL) createStartupEntry {
	
	FSRef item;
	if(![self getFSRef:&item forString:[[NSBundle mainBundle] bundlePath]]){
        NSLog(@"ERROR!!!");
		return NO;
	}
	
	Boolean hideIt=NO;
	int err=0;
	if((err=LIAEAddRefAtEnd(&item,hideIt))){
        NSLog(@"ERROR!!");
		return NO;
	}
	return YES;
}
- (BOOL) deleteStartupEntry {
	int startupIndex = -1;
    NSString *thisURL = [[NSBundle mainBundle] bundlePath];
    OSStatus 			err;
    NSArray *			items;
    CFIndex				itemCount;
    items = NULL;
        
    err = LIAECopyLoginItems((CFArrayRef*)&items);
    if (err == noErr) {
        itemCount = [items count];
        for(int i = 0; i < itemCount; i++){
            NSDictionary *dict;
            dict=[items objectAtIndex:i];
            NSURL *url = [dict valueForKey:@"URL"];
            NSString* str = [url path];
            if([thisURL isEqualToString:str]){
                startupIndex = i;
                break;
            }
        }
    }
    
    [items release];
        
    if(startupIndex == -1) {
        return YES;
    }
    err = LIAERemove(startupIndex);
    
    if([self doesRunAtStartup]) {
        NSLog(@"Still going to run at startup.");
        return NO;
    }
	return YES;
}
#pragma mark -
#pragma mark Timer

- (NSTimeInterval) timerInterval{
	NSInteger setting=[[NSUserDefaults standardUserDefaults]
                       integerForKey:kPreferenceKeyNameInterval];
    return setting?setting:30 MINUTES;
}
-(void) configureTimer{
    if(updateTimer){
        [updateTimer invalidate];
        [updateTimer release];
    }
	updateTimer=[[NSTimer scheduledTimerWithTimeInterval: [self timerInterval]
												  target: self
												selector: @selector(update:)
												userInfo: nil
		  										 repeats: YES] retain];
	
}
- (NSString *) timeString{
	return [[NSDate date] 
			descriptionWithCalendarFormat:@"%H:%M" 
			timeZone:nil
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

#pragma mark -
#pragma mark UI
-(void) setStatusText:(NSString *)text{
	if([[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceKeyNameShow]==kShowModeIconOnly){
		[_statusItem setTitle:@""];
	}else {
		[_statusItem setTitle:text];
	}
	
}

- (IBAction) setShowModeIconOnly:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:kShowModeIconOnly forKey:kPreferenceKeyNameShow];
	[_setShowModeIconOnlyButton setState:NSOnState];
	[_setShowModePercentageButton setState:NSOffState];
	[self setStatusText:@""];
}
- (IBAction) setShowModePercentage:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:kShowModePercentage forKey:kPreferenceKeyNameShow];
	[_setShowModeIconOnlyButton setState:NSOffState];
	[_setShowModePercentageButton setState:NSOnState];
	[self setStatusText:[NSString stringWithFormat:@"%d%%",(int)round(usage.percentage)]];
}


#pragma mark -
#pragma mark Update
- (BOOL) updateInBackgroundCompleted: (id) sender{
    NSLog(@"BUpdate completed");
    
    if(YES){
        [_usedMeter setDoubleValue:usage.percentage];
		[_timeMeter setDoubleValue:usage.monthpercent];
		[_usedLabel setStringValue:[NSString stringWithFormat:
								   @"%d MB (%d%%)",
								   usage.used,
								   (int)(round(usage.percentage))]];
		
		//Memory Leak?
		[self setStatusText:[NSString stringWithFormat:@"%d%%",(int)round(usage.percentage)]];
		
		[_percentOfMonthLabel setStringValue:[NSString stringWithFormat:@"%d%%",(int)(usage.monthpercent)]];
		[_timeLabel setStringValue:[NSString stringWithFormat:
								   @"%dd remain",
								   (signed int)(30.0-(usage.monthpercent*30.0/100.0))]];
		
		[_freeLabel setStringValue:[NSString stringWithFormat:@"Free: %d MB",
								   (int)((double)usage.plan-(double)usage.used)]];
        
        [_updateMenuItem setTitle:[NSString stringWithFormat:@"Update Now - Last: %@",[self timeString]]];
        [_statusItem setImage:[NSImage imageNamed:kImageResourceDefaultIcon]];
        
    }
    [_updatingIndicator stopAnimation:self];
    _inConnection = NO;
    return YES;
}

- (BOOL) updateInBackground: (id) sender{
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
	//get usage info
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
    NSString *password = [[UMKeychain standardKeychain] passwordForUsername:username];
    NSString * error;
    UMUsageInfo *usageInfo = [UMUsageInfo usageInfoWithUser:username password:password error: &error];
    if(!usageInfo){
        NSLog(@"error: %@", error);
    }
    
    usage.monthpercent = [usageInfo monthPercentage];
    usage.used = [usageInfo used];
    usage.plan = [usageInfo plan];
    usage.percentage = [usageInfo percentage];
    
    [autoreleasepool drain];
	
    [self performSelectorOnMainThread:@selector(updateInBackgroundCompleted:)withObject:nil waitUntilDone:NO];
	
	return YES;
}

#pragma mark -
- (void) performLogin{
    
    NSString* username=[_usernameField stringValue];
	NSString* password=[_passwordField stringValue];
    
	if(username.length && password.length){
        [[UMKeychain standardKeychain] setPassword:password forUsername:username];
		[[NSUserDefaults standardUserDefaults]
         setValue:username
         forKey:kPreferenceKeyNameUsername];
		[self update:nil];
	}else {
		[self showLogin:nil];
	}
	[_statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
}

#pragma mark -
#pragma mark IBActions

-(IBAction) showLogin:(id)sender {
    NSString* account=[[NSUserDefaults standardUserDefaults] 
                                      stringForKey:kPreferenceKeyNameUsername];
	if(account==NULL){
		account=@"";
	}
	
	[_usernameField setStringValue:account];
	[_passwordField setStringValue:@""];
	
	[NSApp beginSheet:_loginWindow modalForWindow:_window modalDelegate:self
	   didEndSelector:NULL contextInfo:nil];
	[_loginWindow makeFirstResponder:_usernameField];
}

- (IBAction)cancelLogin:(id)sender {
    [_loginWindow orderOut:nil];
    [NSApp endSheet:_loginWindow];
}
- (IBAction)completeLogin:(id)sender {
    [_loginWindow orderOut:nil];
    [NSApp endSheet:_loginWindow];
    [self performLogin];
    [self deleteStartupEntry];
    
    [_runAtStartupCheckBox2 setState: [_runAtStartupCheckBox state]];
    if([_runAtStartupCheckBox state] == NSOnState){
        [self createStartupEntry];
    }
}
- (IBAction)changeRunAtStartupCheckbox2:(id)sender{
    [_runAtStartupCheckBox setState: [_runAtStartupCheckBox2 state]];
    [self deleteStartupEntry];
    if([_runAtStartupCheckBox state] == NSOnState){
        [self createStartupEntry];
    }
    
}
#pragma mark User Interface (Preferences)
- (IBAction) setPreferenceUpdatePeriod:(id)sender{
    int seconds = 30 MINUTES;
    
    switch ([_updatePeriodPopUp indexOfSelectedItem]) {
        case 1:
            seconds = 60 MINUTES;
            break;
        case 2:
            seconds = 120 MINUTES;
            break;
        case 0:
        default:
            seconds=30 MINUTES;
            break;
    }
    
	[[NSUserDefaults standardUserDefaults]
	 setInteger:seconds
	 forKey:kPreferenceKeyNameInterval];
	
	[self configureTimer];
}

- (IBAction) update:(id)sender {
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
	[_signInStatusLabel setStringValue:[NSString stringWithFormat:@"Account: %@", username]];
    [_userLabel setStringValue:username];
    if(!_inConnection){
		if(![updateTimer isValid]){
			[self configureTimer];
        }
		[_updateMenuItem setTitle:@"Updating..."];
		[_updateMenuItem setEnabled:NO];
		_inConnection=YES;
        [_updatingIndicator startAnimation:self];
		[self performSelectorInBackground:@selector(updateInBackground:) withObject:self];
	}else{
        //already updating...
    }
    
}


- (IBAction) openDownloadPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aantthony.github.com/BigPond-Usage-Meter/"]];
}
- (IBAction) openLicencePage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aantthony.github.com/BigPond-Usage-Meter/licence.html"]];
}

@end
