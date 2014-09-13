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




@end
