//
//  ScratchWindowController.m
//  MacSolver
//
//  Created by Gudapati Naga Venkata Chaitanya
//  Copyright (c) 2014 Chaitanya Gudapati. All rights reserved.
//

#import "ScratchWindowController.h"
#import "ModelEntryViewController.h"
#import "ResultsViewController.h"
#include "lp_lib.h"



@implementation ScratchWindowController

enum   {
    kModelEntryViewTag = 0,
    kResultsViewtag
};

NSString *const kModelEntryView = @"ModelEntryView";
NSString *const kResultsView = @"ResultsView";

-(void) awakeFromNib{
    [self changeViewController:kModelEntryViewTag];
    [self.backToModelButton setHidden:YES];
    [self.showResultsButton setEnabled:NO];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void) changeViewController: (NSInteger) whichViewTag{
    NSLog(@"View is going to be changed");
    
    if ([self.myScratchViewController view] != nil) {
        [[self.myScratchViewController view] removeFromSuperview];
    }
    switch (whichViewTag) {
        case kModelEntryViewTag:
            if (self.myModelEntryViewController == nil) {
                self.myModelEntryViewController = [[ModelEntryViewController alloc] initWithNibName:kModelEntryView bundle:nil];
            }
            self.myScratchViewController  = self.myModelEntryViewController;
            break;
            
        case kResultsViewtag:
            if (self.myResultsViewController == nil) {
                self.myResultsViewController = [[ResultsViewController alloc] initWithNibName:kResultsView bundle:nil];
            }
            self.myScratchViewController = self.myResultsViewController;
            
    }
    
    [self.scratchView addSubview: [self.myScratchViewController view]];
    [[self.myScratchViewController view] setFrame:[self.scratchView bounds]];
    
    
}

- (IBAction)solve:(NSButton *)sender {
    
    NSString *prefixString = @"MyFilename";
    NSString *modelFileExtension = @".lp";
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@%@", prefixString, guid,modelFileExtension];
    NSLog(@"uniqueFileName: '%@'", uniqueFileName);
    
    NSString *loadedModelTemp = [[self.myModelEntryViewController.textField textStorage] string];
    
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSURL *fileURL = [directoryURL URLByAppendingPathComponent:uniqueFileName];
    NSLog(@"%@", fileURL);
    
    [loadedModelTemp writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    //Solving the saved model;
    
    lprec *lp;
    self.returnValue = 0;
    
    NSString *filePathNSString = [fileURL absoluteString];
    NSString *filePathModified = [filePathNSString substringFromIndex:7];
    
    NSLog(@"%@", filePathModified);
    
    const char *cFilePath = [filePathModified UTF8String];
    
    lp = read_LP( cFilePath, NORMAL, "test model");
    
    if(lp == NULL) {
        NSLog(@"Unable to create LP");
        self.returnValue = 1;
    }

    
    NSLog(@"What Ho!");
    int rows = get_Nrows(lp);
    int cols = get_Ncolumns(lp);
    //    NSLog(@"Rows = %d, Columns = %d", rows, cols);
    int indexOfArray = 1+rows+cols;
    REAL pv[indexOfArray];
    
    self.returnValue = solve(lp);
    if (self.returnValue == 0) {
        [self.showResultsButton setEnabled:YES];
    }
    get_primal_solution(lp, pv);
    
    for (int i = 0; i < indexOfArray; ++i) {
        NSLog(@"%f", pv[i]);
    }
    
    self.optimizedValue = pv[0];
    NSLog(@"The optimized value is %f", self.optimizedValue);
    
    
}

- (IBAction)showResults:(NSButton *)sender {
    [self changeViewController:[sender tag]];
    [self.solveButton setHidden:YES];
    [self.showResultsButton setHidden:YES];
    [self.backToModelButton setHidden:NO];
    [self.myResultsViewController.optimizedValueLabel setStringValue:[NSString stringWithFormat:@"%0.3f", self.optimizedValue]];
    
}


- (IBAction)backToModel:(NSButton *)sender {
    [self changeViewController:[sender tag]];
    [self.solveButton setHidden:NO];
    [self.showResultsButton setHidden:NO];
    [self.backToModelButton setHidden:YES];
}
@end
