//
//  PCPreferenesWindowController.m
//  Pomodoro Controller
//
//  Created by Umur Gedik on 9/19/13.
//  Copyright (c) 2013 Umur Gedik. All rights reserved.
//

#import "PCPreferenesWindowController.h"
#import <LRResty/LRResty.h>
#import <JSONKit/JSONKit.h>

const NSString *_API_END = @"/api.php";

@interface PCPreferenesWindowController ()
@end

@implementation PCPreferenesWindowController

@synthesize delegate;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)saveAndClose:(id)sender {
    [[LRResty client] get:[NSString stringWithFormat:@"%@%@?u=%@&c=status", [serverUrl stringValue], _API_END, [username stringValue] ] withBlock:^(LRRestyResponse *response) {
        NSDictionary *json = [[response asString] objectFromJSONString];
        if (![json[@"error"] boolValue]) {
            if (delegate) {
                [delegate readUserDefaults];
            }
        }
    }];
    
    [self close];
}

@end
