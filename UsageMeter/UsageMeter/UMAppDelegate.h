//
//  UMAppDelegate.h
//  UsageMeter
//
//  Created by Anthony Foster on 30/09/11.
//  Copyright (c) 2011 Anthony Foster. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UMUsageInfo.h"

@interface UMAppDelegate : NSObject <NSApplicationDelegate>{
    /*
	IBOutlet NSButton *runAtStartupCheckBox;
	IBOutlet NSTextField *usernameField;
	IBOutlet NSTextField *passwordField;
    
	IBOutlet NSWindow *loginWindow;*/
    
    NSStatusItem * _statusItem;
    BOOL _inConnection;
    
    NSTimer * updateTimer;
    
    struct {
        int plan;
        int used;
        double percentage;
        double monthpercent;
        int valid;
        int error;
    } usage;
    
    //@Synthsized properties:
    NSWindow *window;
    NSButton *runAtStartupCheckBox;
    NSButton *runAtStartupCheckBox2;
    NSTextField *usernameField;
    NSTextField *passwordField;
    NSWindow *loginWindow;
    NSMenu *statusMenu;
    NSTextField *signInStatusLabel;
    NSProgressIndicator *updatingIndicator;
    NSMenuItem *updateMenuItem;
    NSPopUpButton *updatePeriodPopUp;
    
    NSTextField *percentOfMonthLabel;
    NSTextField *freeLabel;
    NSLevelIndicator *usedMeter;
    NSLevelIndicator *timeMeter;
    NSTextField* usedLabel;
    NSTextField* timeLabel;
    NSTextField* userLabel;
    
    NSTextField *versionLabel;
    
    NSMenuItem *setShowModeIconOnlyButton;
    NSMenuItem *setShowModePercentageButton;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *runAtStartupCheckBox;
@property (assign) IBOutlet NSButton *runAtStartupCheckBox2;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *passwordField;

@property (assign) IBOutlet NSWindow *loginWindow;

@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet NSTextField *signInStatusLabel;

@property (assign) IBOutlet	NSProgressIndicator *updatingIndicator;

@property (assign) IBOutlet NSMenuItem *updateMenuItem;

@property (assign) IBOutlet NSPopUpButton *updatePeriodPopUp;


@property (assign) IBOutlet NSTextField *percentOfMonthLabel;
@property (assign) IBOutlet NSTextField *freeLabel;
@property (assign) IBOutlet NSLevelIndicator *usedMeter;
@property (assign) IBOutlet NSLevelIndicator *timeMeter;
@property (assign) IBOutlet NSTextField* usedLabel;
@property (assign) IBOutlet NSTextField* timeLabel;
@property (assign) IBOutlet NSTextField* userLabel;

@property (assign) IBOutlet NSTextField *versionLabel;

@property (assign) IBOutlet NSMenuItem *setShowModeIconOnlyButton;
@property (assign) IBOutlet NSMenuItem *setShowModePercentageButton;


- (IBAction) showLogin:(id)sender;
- (IBAction) cancelLogin:(id)sender;
- (IBAction) completeLogin:(id)sender;

- (IBAction) setPreferenceUpdatePeriod:(id)sender;

- (IBAction) update:(id)sender;
- (IBAction) showPreferences:(id)sender;

- (BOOL) updateInBackgroundCompleted: (id) sender;
- (BOOL) updateInBackground: (id) sender;

- (IBAction)changeRunAtStartupCheckbox2:(id)sender;
- (void) showDeadMenu;

- (BOOL) doesRunAtStartup;
- (void)setStartAtLogin:(BOOL)enabled;
@end
