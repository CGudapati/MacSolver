//
//  AppDelegate.m
//  MacSolver
//
//  Created by Gudapati Naga Venkata Chaitanya
//  Copyright (c) 2014 Chaitanya Gudapati. All rights reserved.
//

#import "AppDelegate.h"
#import "ScratchWindowController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)a{
    [self newDocument:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)newDocument:(id)sender
{
    if (self.myScratchWindowController == nil)
    {
        self.myScratchWindowController = [[ScratchWindowController alloc] initWithWindowNibName:@"ScratchWindow"];
    }
    [self.myScratchWindowController showWindow:self];
}

@end
