/*
 
 UMAppDelegate.h
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
    } usage;
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




//@property (assign) IBOutlet NSMenuItem *setShowModeIconOnlyButton;
//@property (assign) IBOutlet NSMenuItem *setShowModePercentageButton;
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

- (BOOL) updateInBackgroundCompleted: (id) sender;
- (BOOL) updateInBackground: (id) sender;

- (IBAction)changeRunAtStartupCheckbox2:(id)sender;

- (BOOL) doesRunAtStartup;

@end
