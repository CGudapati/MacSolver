//
//  ResultsViewController.h
//  MacSolver
//
//  Created by Chaitanya Gudapati on 10/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ScratchWindowController;


@interface ResultsViewController : NSViewController <NSTableViewDataSource>

@property (weak) IBOutlet NSTextField *optimizedValueLabel;

@property (weak) IBOutlet NSTableView *variablesTableView;

@property (weak) IBOutlet NSTableView *constraintsTableView;

@property (weak) IBOutlet NSTextField *totalIterationsLabel;

@property (weak) IBOutlet NSTextField *numberOfNodesLabel;
@property (weak) IBOutlet NSTextField *timeElapsedLabel;

@end
