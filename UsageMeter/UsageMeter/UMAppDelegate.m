//
//  UMAppDelegate.m
//  UsageMeter
//
//  Created by Anthony Foster on 30/09/11.
//  Copyright (c) 2011 Anthony Foster. All rights reserved.
//

#import "UMAppDelegate.h"

#import "UMKeychain.h"
#import <ServiceManagement/ServiceManagement.h>


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
NSString * const kPreferenceKeyNameRunAtStartup = @"RunAtStartup";

NSString * const kImageResourceDefaultIcon	= @"bp";
NSString * const kImageResourceFadedIcon    = @"fade";
NSString * const kImageResourceFailIcon		= @"fail";

NSString * const kBundleVersionKeyName		= @"CFBundleVersion";

int			kShowModePercentage             = 0;
int			kShowModeIconOnly               = 1;


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
    [self showDeadMenu];
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
- (void)setStartAtLogin:(BOOL)enabled {
	// Creating helper app complete URL
    if(![[[NSBundle mainBundle] bundlePath] isEqualToString:@"/Applications/UsageMeter.app"]){
        NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please rename this application to \"UsageMeter\" and ensure it is stored in the Applications folder."];
        [alert runModal];
       /* if(button == NSAlertDefaultReturn){
            [_window makeKeyAndOrderFront:nil];
        }
        */

        return;
    }
	NSURL *url = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:
                  @"Contents/Library/LoginItems/UsageMeterHelper.app"];
    
	// Registering helper app
    OSStatus err;
	if ((err = LSRegisterURL((CFURLRef)url, true)) != noErr) {
		NSLog(@"LSRegisterURL failed: %d!", err);
        NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"LSRegisterURL failed: %d", err];
        [alert runModal];
        
	}
    
	// Setting login
	if (!SMLoginItemSetEnabled((CFStringRef)@"com.aantthony.UsageMeterHelper",
                               enabled)) {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"SMLoginItemSetEnabled failed"];
        [alert runModal];
		NSLog(@"SMLoginItemSetEnabled failed!");
	}
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kPreferenceKeyNameRunAtStartup];
}

- (BOOL) doesRunAtStartup {
    BOOL runAtStartup = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameRunAtStartup];
    return runAtStartup;
    //TODO
	return NO;
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
	updateTimer=[[NSTimer scheduledTimerWithTimeInterval: [self timerInterval]/10
												  target: self
												selector: @selector(update:)
												userInfo: nil
		  										 repeats: YES] retain];
    NSLog(@"Timer configured to fire every %f seconds", [self timerInterval]/10);
	
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
    
    if(usage.error){
        NSAlert * alert=nil;
        switch (usage.error) {
            case UMError_InvalidPassword:
                alert = [NSAlert alertWithMessageText:@"Invalid Username/Password combination" defaultButton:@"Re-enter password" alternateButton:nil otherButton:nil informativeTextWithFormat:@"e"];
                break;
            case UMError_InternetOffline:
                
                break;
            default:
                break;
        }
        if(alert){
            NSInteger button = [alert runModal];
            if(button == NSAlertDefaultReturn){
                [_window makeKeyAndOrderFront:nil];
            }
        }
    }
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
    //NSLog(@"password: %@", password);
    int error;
    UMUsageInfo *usageInfo = [UMUsageInfo usageInfoWithUser:username password:password error: &error];
    if(!usageInfo){
        usage.error = error;
    }else{
        usage.monthpercent = [usageInfo monthPercentage];
        usage.used = [usageInfo used];
        usage.plan = [usageInfo plan];
        usage.percentage = [usageInfo percentage];
        usage.error = UMError_OK;
        
    }
    
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
    
    [_runAtStartupCheckBox2 setState: [_runAtStartupCheckBox state]];
    [self setStartAtLogin:[_runAtStartupCheckBox state] == NSOnState];
}
- (IBAction)changeRunAtStartupCheckbox2:(id)sender{
    [_runAtStartupCheckBox setState: [_runAtStartupCheckBox2 state]];
    [self setStartAtLogin:[_runAtStartupCheckBox state] == NSOnState];
    
    
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
- (IBAction) showPreferences:(id)sender{
    //TODO: Should this launch another app?
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:nil];
}
- (void) showDeadMenu{
    
    [_usedMeter setDoubleValue:0.0];
    [_timeMeter setDoubleValue:0.0];
    [_usedLabel setStringValue:@""];
    
    //Memory Leak?
    [self setStatusText:@""];
    
    [_percentOfMonthLabel setStringValue:@""];
    [_timeLabel setStringValue:@""];
    
    [_freeLabel setStringValue:@""];
    
    [_updateMenuItem setTitle:@"Update"];
    [_statusItem setImage:[NSImage imageNamed:kImageResourceDefaultIcon]];

}
- (IBAction) update:(id)sender {
    NSLog(@"BUpdate Begin");
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
    if(username == nil){
        //Username pref isn't set: Must be first run.
        
        [_signInStatusLabel setStringValue:[NSString stringWithFormat:@"Account: %@", @"(none)"]];
        [_userLabel setStringValue:NSLocalizedString(@"Not Signed In", @"email for when not signed in")];
        
        [self showDeadMenu];
        [self showPreferences:nil];
        [self showLogin:nil];
        return;
    }
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
