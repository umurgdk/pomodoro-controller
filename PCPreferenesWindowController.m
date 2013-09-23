//
//  PCPreferenesWindowController.m
//  Pomodoro Controller
//
//  Created by Umur Gedik on 9/19/13.
//  Copyright (c) 2013 Umur Gedik. All rights reserved.
//

#import "PCPreferenesWindowController.h"

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
    if (delegate) {
        [delegate readUserDefaults];
    }
    
    [self close];
}

@end
