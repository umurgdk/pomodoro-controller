//
//  PCAppDelegate.h
//  Pomodoro Controller
//
//  Created by Umur Gedik on 9/17/13.
//  Copyright (c) 2013 Umur Gedik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCPreferenesWindowController.h"

typedef enum {
    IDLE,
    POMODORO,
    BREAK
} PomodoroStatus;

@interface PCAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    
    IBOutlet NSMenuItem *startMenuItem;
    IBOutlet NSMenuItem *stopMenuItem;
    IBOutlet NSMenuItem *totalMenuItem;
    
    NSImage *statusImage;
    NSImage *statusHighlightImage;
    
    NSImage *pomodoroImage;
    NSImage *pomodoroHighlightImage;
    
    NSImage *pomodoroBreakImage;
    
    NSSound *tadaSound;
    
    PomodoroStatus pomodoroStatus;
    
    NSTimer *pomodoroTimer;
    
    int pomodoroCountdown;
    long totalPomodoro;
    
    NSString *serverUrl;
    NSDictionary *serverUrls;
    
    NSString *username;
    
    PCPreferenesWindowController *preferencesWindowController;
    BOOL isSettingsProvided;
    
}

- (void)initPomodoroStatus;
- (void)readUserDefaults;
- (void)showAlert;
- (void)updateTotalMenu;

- (IBAction)startPomodoro:(id)sender;
- (IBAction)stopPomodoro:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (IBAction)advancePomodoroTimer:(NSTimer *)timer;

- (void)cancelPomodoro:(id)sender;

@end
