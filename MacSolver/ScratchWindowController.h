//
//  ScratchWindowController.h
//  MacSolver
//
//  Created by Gudapati Naga Venkata Chaitanya
//  Copyright (c) 2014 Chaitanya Gudapati. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ModelEntryViewController, ResultsViewController;


@interface ScratchWindowController : NSWindowController
@property (weak) IBOutlet NSView *scratchView;

@property(nonatomic, assign) NSViewController *myScratchViewController;

@property(nonatomic, strong) ModelEntryViewController *myModelEntryViewController;
@property(nonatomic, strong) ResultsViewController *myResultsViewController;

- (IBAction)solve:(NSButton *)sender;
- (IBAction)showResults:(NSButton *)sender;
@property (weak) IBOutlet NSButton *solveButton;
@property (weak) IBOutlet NSButton *showResultsButton;
@property (weak) IBOutlet NSButton *backToModelButton;
- (IBAction)backToModel:(NSButton *)sender;

@property int returnValue;
@property float optimizedValue;
@property long numberOfIterrations;



@end
