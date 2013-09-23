//
//  PCPreferenesWindowController.h
//  Pomodoro Controller
//
//  Created by Umur Gedik on 9/19/13.
//  Copyright (c) 2013 Umur Gedik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PCPreferenesWindowController : NSWindowController {
//    id delegate;
    IBOutlet NSTextField *username;
    IBOutlet NSTextField *serverUrl;
}

@property id delegate;

- (IBAction)saveAndClose:(id)sender;

@end
