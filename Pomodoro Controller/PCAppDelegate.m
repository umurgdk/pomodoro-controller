//
//  PCAppDelegate.m
//  Pomodoro Controller
//
//  Created by Umur Gedik on 9/17/13.
//  Copyright (c) 2013 Umur Gedik. All rights reserved.
//

#import "PCAppDelegate.h"
#import <LRResty/LRResty.h>
#import <JSONKit/JSONKit.h>

const NSString *API_END = @"/api.php";
const NSString *TIME_END = @"/time.php";

const int POMODORO_MINUTES = 60 * 25;
const int SHORT_BREAK_MINUTES = 60 * 5;
const int LONG_BREAK_MINUTES = 60 * 15;

@implementation PCAppDelegate

- (void)dealloc
{
    [statusImage release];
    [statusHighlightImage release];
    
    [pomodoroImage release];
    [pomodoroHighlightImage release];
    
    [tadaSound release];
    [pomodoroBreakImage release];
    
    [preferencesWindowController release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [statusMenu setAutoenablesItems:NO];
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"idle" ofType:@"png"]];
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"highlight" ofType:@"png"]];
    
    pomodoroImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"active" ofType:@"png"]];
    pomodoroHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"active_highlight" ofType:@"png"]];
    
    pomodoroBreakImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"break" ofType:@"png"]];
    
    tadaSound = [[NSSound alloc] initWithContentsOfFile:[bundle pathForResource:@"TaDa" ofType:@"mp3"] byReference:NO];
    
    [statusItem setImage:statusImage];
    [statusItem setAlternateImage:statusHighlightImage];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    
    pomodoroStatus = IDLE;
    
    pomodoroTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(advancePomodoroTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:pomodoroTimer forMode:NSRunLoopCommonModes];
    
    pomodoroCountdown = POMODORO_MINUTES;
    
    [stopMenuItem setEnabled:NO];
    
    [self readUserDefaults];
}

- (void) readUserDefaults
{
    username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    serverUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverUrl"];
    
    if (!username) {
        username = @"unentered";
    }
    
    if (!serverUrl) {
        serverUrl = @"http://localhost/";
    }
    
    if (serverUrls) {
        [serverUrls release];
    }
    
    serverUrls = [[NSDictionary alloc] initWithObjectsAndKeys:
                  [NSString stringWithFormat:@"%@%@?u=%@&c=start", serverUrl, API_END, username], @"start",
                  [NSString stringWithFormat:@"%@%@?u=%@&c=break", serverUrl, API_END, username], @"break",
                  [NSString stringWithFormat:@"%@%@?u=%@&c=cancel", serverUrl, API_END, username], @"cancel",
                  [NSString stringWithFormat:@"%@%@?u=%@&c=stop", serverUrl, API_END, username], @"stop",
                  [NSString stringWithFormat:@"%@%@?u=%@&c=status", serverUrl, API_END, username], @"status",
                  [NSString stringWithFormat:@"%@%@", serverUrl, TIME_END], @"time",
                  nil];
    
    if ([username isEqual:@"unentered"]) {
        [self showPreferences:self];
    }
    
    [self initPomodoroStatus];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)initPomodoroStatus {
    NSLog(@"sync status");
    [[LRResty client] get:serverUrls[@"status"] withBlock:^(LRRestyResponse *response) {
        [[LRResty client] get:serverUrls[@"time"] withBlock:^(LRRestyResponse *timeResponse) {
            NSDictionary *json = [[response asString] objectFromJSONString];
            
            if (![json[@"error"] boolValue]) {
                // pomodoro has already started from another environment
                if ([json[@"status"] isEqual:@"POMODORO"]) {
                    NSDate *from = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)[json[@"begin"] doubleValue]];
                    NSDate *now = [NSDate dateWithNaturalLanguageString:[timeResponse asString]];
                    
                    pomodoroCountdown = POMODORO_MINUTES - floor([now timeIntervalSinceDate:from]);
                    pomodoroStatus = POMODORO;
                    
                    [startMenuItem setEnabled:NO];
                    [stopMenuItem setEnabled:YES];
                    
                    long minutes = (long) pomodoroCountdown / 60;
                    long seconds = (long) pomodoroCountdown % 60;
                    
                    [statusItem setTitle:[NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds]];
                    
                    [statusItem setImage:pomodoroImage];
                    [statusItem setAlternateImage:pomodoroHighlightImage];
                } else if ([json[@"status"] isEqual:@"IDLE"]) {
                    pomodoroCountdown = POMODORO_MINUTES;
                    pomodoroStatus = IDLE;
                    
                    [startMenuItem setEnabled:YES];
                    [stopMenuItem setEnabled:NO];
                    
                    [statusItem setTitle:@""];
                    
                    [statusItem setImage:statusImage];
                    [statusItem setAlternateImage:statusHighlightImage];
                } else if ([json[@"status"] isEqual:@"S_BREAK"] ||
                           [json[@"status"] isEqual:@"L_BREAK"]) {
                    NSDate *from = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)[json[@"begin"] doubleValue]];
                    NSDate *now = [NSDate dateWithNaturalLanguageString:[timeResponse asString]];
                    
                    if ([json[@"status"] isEqual:@"S_BREAK"]) {
                        pomodoroCountdown = SHORT_BREAK_MINUTES - floor([now timeIntervalSinceDate:from]);
                    } else if ([json[@"status"] isEqual:@"L_BREAK"]) {
                        pomodoroCountdown = LONG_BREAK_MINUTES - floor([now timeIntervalSinceDate:from]);
                    }
                    
                    pomodoroStatus = BREAK;
                    
                    [startMenuItem setEnabled:NO];
                    [stopMenuItem setEnabled:YES];
                    
                    long minutes = (long) pomodoroCountdown / 60;
                    long seconds = (long) pomodoroCountdown % 60;
                    
                    [statusItem setTitle:[NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds]];
                    
                    [statusItem setImage:pomodoroBreakImage];
                    [statusItem setAlternateImage:pomodoroHighlightImage];
                }
            }
        }];
    }];
}

- (IBAction)advancePomodoroTimer:(NSTimer *)timer {
    if ((pomodoroStatus == POMODORO || pomodoroStatus == BREAK) && --pomodoroCountdown >= 0) {
        long minutes = (long) pomodoroCountdown / 60;
        long seconds = (long) pomodoroCountdown % 60;
        
        [statusItem setTitle: [NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds ]];
    } else if (pomodoroStatus == POMODORO && pomodoroCountdown == -1) {
        pomodoroCountdown = POMODORO_MINUTES;
        
        pomodoroStatus = IDLE;
        [statusItem setTitle:@""];
        
        [startMenuItem setEnabled:YES];
        [stopMenuItem setEnabled:NO];
        
        [statusItem setImage:statusImage];
        [statusItem setAlternateImage:statusHighlightImage];
        
        [tadaSound play];
        
        NSAlert *msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText:@"You're free to pee!"];
        
        [msgBox addButtonWithTitle:@"Take a Break!"]; // Take break
        [msgBox addButtonWithTitle:@"One More Pomodoro!"]; // Start another pomodoro
        [msgBox addButtonWithTitle:@"Cancel It!"]; // Cancel pomodoro
        
        NSInteger val = [msgBox runModal];
        
        NSLog(@"%ld", val);
        
        switch (val) {
            case 1000: // Yihaa
                [[LRResty client] get:serverUrls[@"break"] withBlock:^(LRRestyResponse *response) {
                    [self initPomodoroStatus];
                }];
                break;
                
            case 1001:
                [self startPomodoro:self];
                break;
                
            case 1002:
                [self cancelPomodoro:self];
                break;
                
            default:
                break;
        }
    } else if (pomodoroStatus == BREAK && pomodoroCountdown == -1) {
        pomodoroCountdown = POMODORO_MINUTES;
        
        pomodoroStatus = IDLE;
        [statusItem setTitle:@""];
        
        [startMenuItem setEnabled:YES];
        [stopMenuItem setEnabled:NO];
        
        [statusItem setImage:statusImage];
        [statusItem setAlternateImage:statusHighlightImage];
        
        [tadaSound play];
        
        NSUserNotification *notification = [[NSUserNotification init] alloc];
        notification.title = @"Pomodoro";
        notification.informativeText = @"Your break time is finished!";
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    } else if (pomodoroCountdown % 60 == 0 && (pomodoroCountdown != POMODORO_MINUTES &&
                                               pomodoroCountdown != SHORT_BREAK_MINUTES &&
                                               pomodoroCountdown != LONG_BREAK_MINUTES)) {
        [self initPomodoroStatus];
    }
}

- (IBAction)startPomodoro:(id)sender {
    if (pomodoroStatus != POMODORO || pomodoroStatus != BREAK) {
        [[LRResty client] get:serverUrls[@"start"] withBlock:^(LRRestyResponse *r) {
            NSDictionary *json = [[r asString] objectFromJSONString];
            
            NSLog(@"%d", [json[@"error"] boolValue]);
            NSLog(@"%d", YES);
            
            if (![json[@"error"] boolValue]) {
                pomodoroCountdown = POMODORO_MINUTES;
                
                long minutes = (long) pomodoroCountdown / 60;
                long seconds = (long) pomodoroCountdown % 60;
                
                [statusItem setImage:pomodoroImage];
                [statusItem setAlternateImage:pomodoroHighlightImage];
                
                pomodoroStatus = POMODORO;
                
                [statusItem setTitle:[NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds]];
                
                [startMenuItem setEnabled:NO];
                [stopMenuItem setEnabled:YES];
            }
        }];
    }
}

- (IBAction)stopPomodoro:(id)sender {
    if (pomodoroStatus == POMODORO || pomodoroStatus == BREAK) {
        [[LRResty client] get:serverUrls[@"stop"] withBlock:^(LRRestyResponse *r) {
            NSDictionary *json = [[r asString] objectFromJSONString];
            
            if (![json[@"error"] boolValue]) {
                [statusItem setImage:statusImage];
                [statusItem setAlternateImage:statusHighlightImage];
                
                pomodoroStatus = IDLE;
                [statusItem setTitle:@""];
                
                [startMenuItem setEnabled:YES];
                [stopMenuItem setEnabled:NO];
            }
        }];
    }
}

- (void)cancelPomodoro:(id)sender {
    [[LRResty client] get:serverUrls[@"cancel"] withBlock:^(LRRestyResponse *r) {
        NSDictionary *json = [[r asString] objectFromJSONString];
        
        if (![json[@"error"] boolValue]) {
            [statusItem setImage:statusImage];
            [statusItem setAlternateImage:statusHighlightImage];
            
            pomodoroStatus = IDLE;
            [statusItem setTitle:@""];
            
            [startMenuItem setEnabled:YES];
            [stopMenuItem setEnabled:NO];
        }
    }];
}

- (IBAction)showPreferences:(id)sender {
    if(!preferencesWindowController) {
        preferencesWindowController = [[PCPreferenesWindowController alloc] initWithWindowNibName:@"PCPreferenesWindowController"];
        [preferencesWindowController setDelegate:self];
    }
    
    [[preferencesWindowController window] center];
    [[preferencesWindowController window] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
