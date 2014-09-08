//
//  ScratchWindowController.h
//  MacSolver
//
//  Created by Venkat on 08/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ModelEntryViewController, ResultsViewController;


@interface ScratchWindowController : NSWindowController
@property(nonatomic, assign) NSViewController *myScratchViewController;

@property(nonatomic, strong) ModelEntryViewController *myModelEntryViewController;
@property(nonatomic, strong) ResultsViewController *myResultsViewController;

@property (weak) IBOutlet NSView *scratchView;
- (IBAction)solve:(NSButton *)sender;
- (IBAction)showResults:(NSButton *)sender;
- (IBAction)backToModel:(NSButton *)sender;
@property (weak) IBOutlet NSButton *solveButton;
@property (weak) IBOutlet NSButton *showResultsButton;
@property (weak) IBOutlet NSButton *backToModelButton;


@property int returnValue;
@property float optimizedValue;
@property long numberOfIterrations;

@end
