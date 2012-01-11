//
//  UMAppDelegate.m
//  UsageMeter
//
//  Created by Anthony Foster on 30/09/11.
//  Copyright (c) 2011 Anthony Foster. All rights reserved.
//

#import "UMAppDelegate.h"

#import "UMKeychain.h"
#import "AppLoginItem.h"

@implementation UMAppDelegate

@synthesize window,
runAtStartupCheckBox,
runAtStartupCheckBox2,
usernameField,
passwordField,
loginWindow,
statusMenu,
signInStatusLabel,
updatingIndicator,
updateMenuItem,
updatePeriodPopUp;

@synthesize
percentOfMonthLabel,
freeLabel,
usedMeter,
timeMeter,
usedLabel,
timeLabel,
userLabel;

@synthesize
setShowModeIconOnlyButton,
setShowModePercentageButton;


@synthesize versionLabel;

NSString * const kPreferenceKeyNameUsername	= @"Username";
NSString * const kPreferenceKeyNameInterval	= @"UpdateInterval";
NSString * const kPreferenceKeyNameShow     = @"Show";
//NSString * const kPreferenceKeyNameRunAtStartup = @"RunAtStartup";

NSString * const kImageResourceDefaultIcon	= @"bp";
NSString * const kImageResourceFadedIcon    = @"fade";
NSString * const kImageResourceFailIcon		= @"fail";

NSString * const kBundleVersionKeyName		= @"CFBundleVersion";

NSString * const kHelperAppBundleID         = @"com.aantthony.UsageMeterHelper";

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
            [updatePeriodPopUp selectItemAtIndex:0];
            break;
        case 60 MINUTES:
            [updatePeriodPopUp selectItemAtIndex:1];
            break;
        case 120 MINUTES:
            [updatePeriodPopUp selectItemAtIndex:2];
            break;
        default:
            break;
    }
    
    if([self doesRunAtStartup]){
        [runAtStartupCheckBox setState:NSOnState];
        [runAtStartupCheckBox2 setState:NSOnState];
    }else{
        [runAtStartupCheckBox setState:NSOffState];
        [runAtStartupCheckBox2 setState:NSOffState];
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadPreferences];
    [self showDeadMenu];
    [self update:nil];
}

-(void)awakeFromNib {
    _inConnection = NO;
    
    usage.valid = NO;
    usage.plan = usage.used = usage.error = usage.percentage = usage.monthpercent = 0;
    
    [versionLabel setStringValue:[NSString stringWithFormat:
                                   @"Version: %@",
                                   [[[NSBundle mainBundle] infoDictionary] objectForKey:kBundleVersionKeyName]]];
    
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[_statusItem setMenu:statusMenu];
    
	[_statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
	[_statusItem setHighlightMode:YES];
    
}


#pragma mark -
#pragma mark Startup

- (void)setStartAtLogin:(BOOL)enabled {
	// Creating helper app complete URL
    if(![[[NSBundle mainBundle] bundlePath] isEqualToString:@"/Applications/UsageMeter.app"]){
        if(!enabled){
            return;
        }
        NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please rename this application to \"UsageMeter\" and ensure it is stored in the /Applications folder."];
        [alert runModal];
        
        [[self runAtStartupCheckBox] setState:NSOffState];
        [[self runAtStartupCheckBox2] setState:NSOffState];
        return;
    }
	/*NSURL *url = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:
                  @"Contents/Library/LoginItems/UsageMeterHelper.app"];
     */
    
	// Registering helper app
    //OSStatus err;
    //NSLog(@"Will NOT attempt to register %@.", url);
    /*
	if ((err = LSRegisterURL((CFURLRef)url, true)) != noErr) {
		NSLog(@"Expected error: LSRegisterURL failed: %d! FIX THIS BUG APPLE", err);
        NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"LSRegisterURL failed: %d", err];
        [alert runModal];
	}
    */
    
	// Setting login
	if (![AppLoginItem toggleBundleIDAsLoginItem: kHelperAppBundleID state: enabled]) {
        /*NSAlert * alert = [NSAlert alertWithMessageText:@"Could not configure UsageMeter to run at startup" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"SMLoginItemSetEnabled failed"];
        [alert runModal];*/
		//NSLog(@"Expected error: SMLoginItemSetEnabled failed! FIX THIS BUG APPLE");
	}
    //[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kPreferenceKeyNameRunAtStartup];
}

- (BOOL) doesRunAtStartup {
    BOOL runAtStartup = [AppLoginItem bundleIDExistsAsLoginItem: kHelperAppBundleID];
    //BOOL runAtStartup = [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameRunAtStartup];
    return runAtStartup;
    //TODO
	return NO;
}

#pragma mark -
#pragma mark Timer

- (NSTimeInterval) timerInterval{
	NSInteger setting=[[NSUserDefaults standardUserDefaults]
                       integerForKey:kPreferenceKeyNameInterval];
    return setting ? setting: 30 MINUTES;
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
    //NSLog(@"Timer configured to fire every %f seconds", [self timerInterval]);
	
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
	[setShowModeIconOnlyButton setState:NSOnState];
	[setShowModePercentageButton setState:NSOffState];
	[self setStatusText:@""];
}
- (IBAction) setShowModePercentage:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:kShowModePercentage forKey:kPreferenceKeyNameShow];
	[setShowModeIconOnlyButton setState:NSOffState];
	[setShowModePercentageButton setState:NSOnState];
    if(usage.valid){
        [_statusItem setTitle:[NSString stringWithFormat:@"%d%%",(int)round(usage.percentage)]];
    }else{
        [self setStatusText:@""];
    }
}


#pragma mark -
#pragma mark Update
- (BOOL) updateInBackgroundCompleted: (id) sender{

    [updatingIndicator stopAnimation:self];
    _inConnection = NO;
    NSString * failedReason = nil;
    BOOL invalidateTimer = NO;
    if(usage.error){
        //NSLog(@"Usage error: %@", [UMUsageInfo stringForError: usage.error]);
        invalidateTimer = YES;
        NSAlert * alert = nil;
        switch (usage.error) {
            case UMError_InvalidPassword:
                alert = [NSAlert alertWithMessageText:@"Incorrect Password" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The BigPond password attempted was incorrect. Configure your account in the prefernces window."];
                failedReason = @"Invalid Password";
                break;
            case UMError_AccountLocked:
                /*
                alert = [NSAlert alertWithMessageText:@"Incorrect Password" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The BigPond password attempted was incorrect. Configure your account in the prefernces window."];
                 */
                failedReason = @"Account Locked";
                break;
                
            case UMError_InternetOffline:
                failedReason = @"Internet Offline";
                invalidateTimer = NO;
                break;
            default:
                break;
        }
        if(alert){
            NSInteger button = [alert runModal];
            if(button == NSAlertDefaultReturn){
                [window makeKeyAndOrderFront:nil];
                [self showLogin:nil];
            }
        }
        
        if(invalidateTimer){
            [_statusItem setImage:[NSImage imageNamed:kImageResourceFailIcon]];
        }else{
            [_statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
        }
    }
    if(usage.valid){
        [usedMeter setDoubleValue:usage.percentage];
		[timeMeter setDoubleValue:usage.monthpercent];
		[usedLabel setStringValue:[NSString stringWithFormat:
								   @"%d MB (%d%%)",
								   usage.used,
								   (int)(round(usage.percentage))]];
		
		//Memory Leak?
		[self setStatusText:[NSString stringWithFormat:@"%d%%",(int)round(usage.percentage)]];
		
		[percentOfMonthLabel setStringValue:[NSString stringWithFormat:@"%d%%",(int)(usage.monthpercent)]];
		[timeLabel setStringValue:[NSString stringWithFormat:
								   @"%dd remain",
								   (signed int)(30.0-(usage.monthpercent*30.0/100.0))]];
		
		[freeLabel setStringValue:[NSString stringWithFormat:@"Free: %d MB",
								   (int)((double)usage.plan-(double)usage.used)]];
        
        [updateMenuItem setTitle:[NSString stringWithFormat:@"Update Now - Last: %@",[self timeString]]];
        [_statusItem setImage:[NSImage imageNamed:kImageResourceDefaultIcon]];
        
    }else{
        if(failedReason){
            
            [updateMenuItem setTitle:[NSString stringWithFormat:@"Update - %@", failedReason]];
        }else{
            [updateMenuItem setTitle:[NSString stringWithFormat:@"Update - Last attempt failed"]];
        }
    }
    if(invalidateTimer){
        [updateTimer invalidate];
        //NSLog(@"THE RETAIN COUNT IS %lu", [updateTimer retainCount]);
        assert([updateTimer retainCount] == 1);
        [updateTimer release];
        updateTimer = nil;
    }
    return YES;
}

- (BOOL) updateInBackground: (id) sender{
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
	//get usage info
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
    NSString *password = [[UMKeychain standardKeychain] passwordForUsername:username];
    //NSLog(@"Updating: username: %@", username);
    assert((password!=nil) && (username!=nil));
    int error;
    UMUsageInfo *usageInfo = [UMUsageInfo usageInfoWithUser:username password:password error: &error];
    if(!usageInfo){
        usage.error = error;
        usage.valid = NO;
    }else{
        usage.monthpercent = [usageInfo monthPercentage];
        usage.used = [usageInfo used];
        usage.plan = [usageInfo plan];
        usage.percentage = [usageInfo percentage];
        usage.error = UMError_OK;
        usage.valid = YES;
    }
    
    [autoreleasepool drain];
	
    [self performSelectorOnMainThread:@selector(updateInBackgroundCompleted:)withObject:nil waitUntilDone:NO];
	
	return YES;
}

#pragma mark -
- (void) performLogin{
    
    NSString* username = [usernameField stringValue];
	NSString* password = [passwordField stringValue];
    
    
	if(username.length && password.length){
        [[UMKeychain standardKeychain] setPassword:password forUsername:username];
		[[NSUserDefaults standardUserDefaults]
         setValue:username
         forKey:kPreferenceKeyNameUsername];
        [self showDeadMenu];
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
	
	[usernameField setStringValue:account];
	[passwordField setStringValue:@""];
	
	[NSApp beginSheet:loginWindow modalForWindow:window modalDelegate:self
	   didEndSelector:NULL contextInfo:nil];
	[loginWindow makeFirstResponder:usernameField];
}

- (IBAction)cancelLogin:(id)sender {
    [loginWindow orderOut:nil];
    [NSApp endSheet:loginWindow];
}
- (IBAction)completeLogin:(id)sender {
    [loginWindow orderOut:nil];
    [NSApp endSheet:loginWindow];
    [self performLogin];
    
    [runAtStartupCheckBox2 setState: [runAtStartupCheckBox state]];
    [self setStartAtLogin:[runAtStartupCheckBox state] == NSOnState];
}
- (IBAction)changeRunAtStartupCheckbox2:(id)sender{
    [runAtStartupCheckBox setState: [runAtStartupCheckBox2 state]];
    [self setStartAtLogin:[runAtStartupCheckBox state] == NSOnState];
    
    
}
#pragma mark User Interface (Preferences)
- (IBAction) setPreferenceUpdatePeriod:(id)sender{
    int seconds = 30 MINUTES;
    
    switch ([updatePeriodPopUp indexOfSelectedItem]) {
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
    [window makeKeyAndOrderFront:nil];
}
- (void) showDeadMenu{
    
    [usedMeter setDoubleValue:0.0];
    [timeMeter setDoubleValue:0.0];
    [usedLabel setStringValue:@""];
    
    //Memory Leak?
    [self setStatusText:@""];
    
    [percentOfMonthLabel setStringValue:@""];
    [timeLabel setStringValue:@""];
    
    [freeLabel setStringValue:@""];
    
    [updateMenuItem setTitle:@"Update"];
    [_statusItem setImage:[NSImage imageNamed:kImageResourceDefaultIcon]];

}
- (IBAction) update:(id)sender {
    //NSLog(@"BUpdate Begin");
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
    if(username == nil){
        //Username pref isn't set: Must be first run.
        
        [signInStatusLabel setStringValue:[NSString stringWithFormat:@"Account: %@", @"(none)"]];
        [userLabel setStringValue:NSLocalizedString(@"Not Signed In", @"email for when not signed in")];
        
        [self showDeadMenu];
        [self showPreferences:nil];
        [self showLogin:nil];
        return;
    }
	[signInStatusLabel setStringValue:[NSString stringWithFormat:@"Account: %@", username]];
    [userLabel setStringValue:username];
    if(!_inConnection){
		if(![updateTimer isValid]){
			[self configureTimer];
        }
		[updateMenuItem setTitle:@"Updating..."];
		[updateMenuItem setEnabled:NO];
		_inConnection=YES;
        [updatingIndicator startAnimation:self];
		[self performSelectorInBackground:@selector(updateInBackground:) withObject:self];
	}else{
        //already updating...
        //NSLog(@"ALREADY RUNNING");
    }
    
}


- (IBAction) openDownloadPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aantthony.github.com/BigPond-Usage-Meter/"]];
}
- (IBAction) openLicencePage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aantthony.github.com/BigPond-Usage-Meter/licence.html"]];
}

@end
