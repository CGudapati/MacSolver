//
//  ScratchWindowController.m
//  MacSolver
//
//  Created by Chaitanya Gudapati on 08/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import "ScratchWindowController.h"
#import "ModelEntryViewController.h"
#import "ResultsViewController.h"
#include "lp_lib.h"

@interface ScratchWindowController ()
@property (nonatomic, strong) NSMutableArray *arrayOfVariableNames;
@property (nonatomic, strong) NSMutableArray *arrayOfVariableValues;
@property (nonatomic, strong) NSMutableArray *arrayOfConstraintValues;
@property (nonatomic, strong) NSMutableArray *arrayOfConstraintNames;
@end

@implementation ScratchWindowController

enum   {
    kModelEntryViewTag = 0,   //Giving each view a tag for the changeViewcontrollerMethod
    kResultsViewTag
};


NSString *const kModelEntryView = @"ModelEntryView";
NSString *const kResultsView = @"ResultsView";

-(void) awakeFromNib{
    [self changeViewController:kModelEntryViewTag];
    [self.myModelEntryViewController.textField setRichText:NO];
    [self.myModelEntryViewController.textField setFont:[NSFont userFixedPitchFontOfSize:12.5]]; //default font for entering the model
    [self.backToModelButton setHidden:YES];
    [self.showResultsButton setEnabled:NO];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void) changeViewController: (NSInteger) whichViewTag{
    
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
            
        case kResultsViewTag:
            if (self.myResultsViewController == nil) {
                self.myResultsViewController = [[ResultsViewController alloc] initWithNibName:kResultsView bundle:nil];
            }
            self.myScratchViewController = self.myResultsViewController;
            
    }
    
    [self.scratchView addSubview: [self.myScratchViewController view]];
    [[self.myScratchViewController view] setFrame:[self.scratchView bounds]];
    
    
    //When the results view is loaded, the TableView gets it's DataSource and Delegate
    if (whichViewTag == kResultsViewTag) {
        self.myResultsViewController.variablesTableView.delegate = self;
        self.myResultsViewController.variablesTableView.dataSource = self;
        [self.myResultsViewController.variablesTableView reloadData];
    }
    
}


- (IBAction)solve:(NSButton *)sender {
    
#pragma mark - Saving the file as .lp
    
    //The text in the textField will be stored in a .lp file.
    
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
    
    
#pragma mark - Solving the .lp file
    
    
    //Solving the saved model;
    
    lprec *lp;
    self.returnValue = 0; //setting the return value of solve() to zero. Will be calling different alertsheets
    
    NSString *filePathNSString = [fileURL absoluteString];
    NSString *filePathModified = [filePathNSString substringFromIndex:7];
    
    const char *constCFilePath = [filePathModified UTF8String];
    char * cFilePath = strdup(constCFilePath);
    
    lp = read_LP( cFilePath, NORMAL, "test model");
    
    if(lp == NULL) {
        NSLog(@"Unable to create LP");
        self.returnValue = 1;
    }
    
    if (self.returnValue == 1) {
        NSAlert *createLPFailAlert = [NSAlert alertWithMessageText:@"Unable to create LP" defaultButton:@"Ok" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"Unable to create LP from the given input. Please check again"];
        SEL callback = @selector(endOfAlert:returnCode:contextInfo:);
        [createLPFailAlert beginSheetModalForWindow:self.modelWindow modalDelegate:self didEndSelector:callback contextInfo:nil];
    }
    
    
    int cols = get_Ncolumns(lp); //Gets the number of variables
    int rows = get_Nrows(lp); // Gets the number of constrainrs
    
    //solving the LP and getting it's return value
    
    self.returnValue = solve(lp);
    
    //NSAlerts based on the value of self.returnValue
    
    if (self.returnValue == 2) {
        NSAlert *infeasibleAlert =  [NSAlert alertWithMessageText:@"The model is infeasible" defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"The entered model is infeasible. Enter a feasible model and try again"];
        SEL callback = @selector(endOfAlert:returnCode:contextInfo:);
        [infeasibleAlert beginSheetModalForWindow:self.modelWindow modalDelegate:self didEndSelector:callback contextInfo:nil];
    }
    
    if(self.returnValue == 3){
        NSAlert *unboundedAlert = [NSAlert alertWithMessageText:@"The model is unbounded" defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"The entered model is unbounded. Please enter a bounded model"];
        SEL callback = @selector(endOfAlert:returnCode:contextInfo:);
        [unboundedAlert beginSheetModalForWindow:self.modelWindow modalDelegate:self didEndSelector:callback contextInfo:nil];
    }
    
#pragma mark -Getting the data from Model
    
    
    self.optimizedValue = get_working_objective(lp); //The value of the objective after successful solve
    
    char* cArrayOfVariableNames[cols-1];
    char* cArrayOfConstraintNames[rows-1];
    REAL cArrayOfVariableValues[cols-1];
    REAL cArrayOfConstraintValues[rows-1];
    
    if (!self.arrayOfVariableNames){
        self.arrayOfVariableNames = [[NSMutableArray alloc] init];
    }
    else {
        [self.arrayOfVariableNames removeAllObjects];
    }
    for (int i = 0; i< cols; i++){
        cArrayOfVariableNames[i] = get_origcol_name(lp, i+1);
        
#ifndef NDEBUG
        printf("varaibles in CArray: %s\n", cArrayOfVariableNames[i]);
#endif
        
        if (cArrayOfVariableNames[i]) {
            NSString *tempString = [NSString stringWithCString:cArrayOfVariableNames[i] encoding:NSUTF8StringEncoding];
            [self.arrayOfVariableNames addObject:tempString];
        }
        else{
            self.returnValue = 12;
        }
    }
    
    
    if(self.returnValue == 12){
        NSAlert *wrongVariableAlert = [NSAlert alertWithMessageText:@"Something wrong happened" defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"Couldn't find the solution due to some issues in the model. Please enter correct model"];
        
        SEL callback = @selector(endOfAlert:returnCode:contextInfo:);
        [wrongVariableAlert beginSheetModalForWindow:self.modelWindow modalDelegate:self didEndSelector:callback contextInfo:nil];
    }
    
    //Get the optimal value of variables
    get_variables(lp, cArrayOfVariableValues);
    
    if (!self.arrayOfVariableValues) {
        self.arrayOfVariableValues = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfVariableValues removeAllObjects];
    }
    
    for (int j = 0; j < cols; j++) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfVariableValues[j]];
        [self.arrayOfVariableValues addObject:tempNumber];
    }
    
    NSLog(@"return current value: %d",self.returnValue );
    
    //Getting the Optimal value of constaints
    
    get_constraints(lp, cArrayOfConstraintValues);
    if (!self.arrayOfConstraintValues) {
        self.arrayOfConstraintValues = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfConstraintValues removeAllObjects];
    }
    
    for (int i = 0; i <rows; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfConstraintValues[i]];
        [self.arrayOfConstraintValues addObject:tempNumber];
        NSLog(@"%@", self.arrayOfConstraintValues[i]);
    }
    
    
    //Get the names of the constarints
    
    if (!self.arrayOfConstraintNames) {
        self.arrayOfConstraintNames = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfConstraintNames removeAllObjects];
    }
    for (int i = 0; i < rows; ++i) {
        cArrayOfConstraintNames[i] = get_origrow_name(lp, i+1);
        if (cArrayOfConstraintNames[i]) {
            NSString *tempString = [NSString stringWithCString:cArrayOfConstraintNames[i] encoding:NSUTF8StringEncoding];
            [self.arrayOfConstraintNames addObject:tempString];
        }
        else{
            self.returnValue = 13;
        }
        
    }

#ifndef NDEBUG
    for (int i = 0; i < rows; ++i) {
        NSLog(@"the names of constraints and their values are: %@: %@", self.arrayOfConstraintNames[i], self.arrayOfConstraintValues[i]);
    }
#endif
    
    
    if (self.returnValue == 0) {
        [self.showResultsButton setEnabled:YES];
    }
    
    delete_lp(lp);
    free(cFilePath);
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
    [self.showResultsButton setEnabled:NO];
    [self.backToModelButton setHidden:YES];
}


//implementing the TableView for Variables and their values
-(NSInteger) numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.arrayOfVariableNames count];
}

-(id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return [([tableColumn.identifier isEqualToString:@"variables"] ? self.arrayOfVariableNames : self.arrayOfVariableValues) objectAtIndex:row];
    
}


-(void) endOfAlert: (NSAlert *) alert returnCode:(int) resultCode contextInfo:(void *) contextInfo{
    if (resultCode == NSAlertDefaultReturn){
        NSLog(@"OK");
    }
}

@end
