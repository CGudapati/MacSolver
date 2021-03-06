//
//  ScratchWindowController.h
//  MacSolver
//
//  Created by Chaitanya Gudapati on 08/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ModelEntryViewController, ResultsViewController;


@interface ScratchWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *modelWindow;
@property (weak) IBOutlet NSView *scratchView;
- (IBAction)solve:(NSButton *)sender;
- (IBAction)showResults:(NSButton *)sender;
- (IBAction)backToModel:(NSButton *)sender;
@property (weak) IBOutlet NSButton *solveButton;
@property (weak) IBOutlet NSButton *showResultsButton;
@property (weak) IBOutlet NSButton *backToModelButton;

@property(nonatomic, assign) NSViewController *myScratchViewController;
@property(nonatomic, strong) ModelEntryViewController *myModelEntryViewController;
@property(nonatomic, strong) ResultsViewController *myResultsViewController;

@property (nonatomic, strong) NSArray *constArrayOfVariableNames;
@property  (nonatomic, strong) NSArray *constArrayOfVariableValues;



@property int returnValue;
@property float optimizedValue;
@property double timeElapsed;
@property long long totalIterations;
@property long totalNodes;

@end
