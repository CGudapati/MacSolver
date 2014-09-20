//
//  AppDelegate.m
//  MacSolver
//
//  Created by Chaitanya Gudapati on 07/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import "AppDelegate.h"
#import "ScratchWindowController.h"


@implementation AppDelegate


-(IBAction)newDocument:(id)sender
{
    if (self.myScratchWindowController == nil)
    {
        self.myScratchWindowController = [[ScratchWindowController alloc] initWithWindowNibName:@"ScratchWindow"];
    }
    [self.myScratchWindowController showWindow:self];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self newDocument:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem{
    BOOL enable = [self respondsToSelector:[menuItem action]];
    if ([menuItem action] == @selector(newDocument:)) {
        if ([[self.myScratchWindowController window] isKeyWindow]) {
            enable = NO;
        }
    }
    return enable;
}

@end
