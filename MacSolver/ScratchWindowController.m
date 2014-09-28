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
@property (nonatomic, strong) NSMutableArray *arrayOfObjectiveUpper;
@property (nonatomic, strong) NSMutableArray  *arrayOfObjectiveLower;
@property (nonatomic, strong) NSMutableArray *arrayOfDuals;
@property (nonatomic, strong) NSMutableArray *arrayOfDualsLower;
@property (nonatomic, strong) NSMutableArray *arrayOfDualsUpper;
@property (nonatomic, strong) NSMutableArray *arrayOfDualsOfVariables;
@property (nonatomic, strong) NSMutableArray *arrayOfDualsOfConstraints;
@property (nonatomic, strong) NSMutableArray *arrayOfObjectiveCoefficients;
@property (nonatomic, strong) NSMutableArray *arrayOfRHSValues;
@property (nonatomic, strong) NSMutableArray *arratOfSlackValues;


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
    REAL cArrayOfObjectiveLower[cols-1];
    REAL cArrayOfObjectiveUpper[cols-1];
    REAL cArrayOfDuals[1+cols+rows];
    REAL cArrayOfDualsLower[1+cols+rows];
    REAL cArrayOfDualsUpper[1+cols+rows];
    REAL cArrayOfObjectiveCoefficients[1+cols];
    REAL cArrayOfRHSValues[rows];
    
    
    
    //Get the names of the variables
    
    if (!self.arrayOfVariableNames){
        self.arrayOfVariableNames = [[NSMutableArray alloc] init];
    }
    
    else {
        [self.arrayOfVariableNames removeAllObjects];
    }
    for (int i = 0; i< cols; i++){
        cArrayOfVariableNames[i] = get_origcol_name(lp, i+1);
        
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
    
    if (self.returnValue == 0) {
        [self.showResultsButton setEnabled:YES];
    }
    
    
    //Getting the Optimal value of constraints
    
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
    }
    
    // Getting the value of the coefficients of the objective function
    
    get_row(lp, 0, cArrayOfObjectiveCoefficients);
    if (!self.arrayOfObjectiveCoefficients) {
        self.arrayOfObjectiveCoefficients = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfObjectiveCoefficients removeAllObjects];
    }
    for (int i = 0; i < cols+1; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfObjectiveCoefficients[i]];
        [self.arrayOfObjectiveCoefficients addObject:tempNumber];
    }
    
    //Getting the sensitivity of the constarints
    
    get_sensitivity_obj(lp, cArrayOfObjectiveLower, cArrayOfObjectiveUpper);
    
    if (!self.arrayOfObjectiveLower) {
        self.arrayOfObjectiveLower = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfObjectiveLower removeAllObjects];
    }
    
    for (int i = 0; i <= cols; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfObjectiveLower[i]];
        [self.arrayOfObjectiveLower addObject:tempNumber];
    }
    
    
    if (!self.arrayOfObjectiveUpper) {
        self.arrayOfObjectiveUpper = [[NSMutableArray alloc] init];
    }
    
    else{
        [self.arrayOfObjectiveUpper removeAllObjects];
    }
    
    for (int i = 0; i <= cols; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfObjectiveUpper[i]];
        [self.arrayOfObjectiveUpper addObject:tempNumber];
    }
    
    //Getting the value of the RHS values of constraints
    
    if (!self.arrayOfRHSValues) {
        self.arrayOfRHSValues = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfRHSValues removeAllObjects];
    }
    for (int i = 0; i <= rows; ++i) {
        cArrayOfRHSValues[i] = get_rh(lp, i);
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfRHSValues[i]];
        
        [self.arrayOfRHSValues addObject:tempNumber];
    }
    
    //Getting the values of reduced costs
    
    get_sensitivity_rhs(lp, cArrayOfDuals, cArrayOfDualsLower, cArrayOfDualsUpper);
    
    if (!self.arrayOfDuals) {
        self.arrayOfDuals = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfDuals removeAllObjects];
    }
    for (int i = 0; i < cols+rows; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfDuals[i]];
        [self.arrayOfDuals addObject:tempNumber];
    }
    
    if (!self.arrayOfDualsLower) {
        self.arrayOfDualsLower = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfDualsLower   removeAllObjects];
    }
    for (int i = 0; i < rows+ cols; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfDualsLower[i]];
        [self.arrayOfDualsLower addObject:tempNumber];
    }
    if (!self.arrayOfDualsUpper) {
        self.arrayOfDualsUpper = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfDualsUpper  removeAllObjects];
    }
    for (int i = 0; i < rows+ cols ; ++i) {
        NSNumber *tempNumber = [NSNumber numberWithDouble:cArrayOfDualsUpper[i]];
        [self.arrayOfDualsUpper addObject:tempNumber];
    }
    
    if (!self.arrayOfDualsOfConstraints) {
        self.arrayOfDualsOfConstraints = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfDualsOfConstraints removeAllObjects];
    }
    
    for (int i = 0; i < rows; ++i) {
        [self.arrayOfDualsOfConstraints addObject:self.arrayOfDuals[i]];
    }
    
    if (!self.arrayOfDualsOfVariables) {
        self.arrayOfDualsOfVariables = [[NSMutableArray alloc] init];
    }
    else{
        [self.arrayOfDualsOfVariables removeAllObjects];
    }
    for (int i = rows; i < rows+cols; ++i) {
        [self.arrayOfDualsOfVariables addObject:self.arrayOfDuals[i]];
    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
    
    //Logging the values of the variables and constraints
    
    REAL cValueOfInfinite;
    REAL negCValueOfInfinite;
    
    cValueOfInfinite = get_infinite(lp);
    negCValueOfInfinite = -(get_infinite(lp));
    NSNumber *valueOfInfinite = [NSNumber numberWithDouble:cValueOfInfinite];
    NSNumber *negValueOfInfinite = [NSNumber numberWithDouble:negCValueOfInfinite];
    
    NSLog(@"The value of infinite for the given system is %@", valueOfInfinite);
    NSLog(@"The value of infinite for the given system is %@", negValueOfInfinite);

    
    NSNumberFormatter *formatForDecimals = [[NSNumberFormatter alloc] init];
    [formatForDecimals setMaximumFractionDigits:4];
    [formatForDecimals setMinimumFractionDigits:2];
    [formatForDecimals setMinimumIntegerDigits:1];
    
    NSNumberFormatter *formatForScientific= [[NSNumberFormatter alloc] init];
    [formatForScientific setNumberStyle:NSNumberFormatterScientificStyle];
    [formatForScientific setMaximumFractionDigits:1];
    [formatForScientific setRoundingMode:NSNumberFormatterRoundHalfDown];
    [formatForScientific setExponentSymbol:@"e"];
    
    NSLog(@"\n");
    
    NSLog(@"The number of Variables/Columns are %d", cols);
    NSLog(@"The number of Constraints/Rows are %d", rows);
    
    NSLog(@"\n");
    
    //Logging the value of variables
    for (int i = 0; i < cols; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfVariableValues[i];
        
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];

        }
        NSLog(@"Tha value of Variable %@ is %@", self.arrayOfVariableNames[i], tempString);
    }
    
    NSLog(@"\n");
    
    //Logging the value of constraints
    
    for (int i = 0; i < rows; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfConstraintValues[i];
        
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];

        }
        NSLog(@"The value of %@ is %@", self.arrayOfConstraintNames[i], tempString);
    }
    
    NSLog(@"\n");
    
    //        Logging the lower objective function limit;
    
    for (int i = 0; i < cols; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfObjectiveLower[i];
        
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        NSLog(@"The lower value of the coeeficient of %@ is %@", self.arrayOfVariableNames[i], tempString);
    }
    
    //       Logging the upper objective function limit;
    NSLog(@"\n");
    
    for (int i = 0; i < cols; ++i) {
        NSString *tempString;
        NSNumber *tempNumber;
        tempNumber = self.arrayOfObjectiveUpper[i];
        
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        NSLog(@"The Upper value of the coefficient of %@ is %@", self.arrayOfVariableNames[i], tempString);
    }
    
    
    NSLog(@"\n");
    
    //Logging the reduced cost of constratints
    
    for (int i = 0; i < rows; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfDuals[i];
         if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        
        NSLog(@"The reduced cost of %@ is %@", self.arrayOfConstraintNames[i],tempString);
    }
    
    NSLog(@"\n");
    
    //Logging the lower value of reduced cost of constratints
    
    
    for (int i = 0; i < rows; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        
        tempNumber = self.arrayOfDualsLower[i];
        if ([tempNumber doubleValue] == [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <=[negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        
        NSLog(@"The lower limit of reduced cost of %@ is %@", self.arrayOfConstraintNames[i], tempString);
    }
    
    NSLog(@"\n");
    
    //Logging the upper value of reduced cost of constratints
    
    for (int i = 0; i < rows; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfDualsUpper[i];
        if ([tempNumber doubleValue] >= ([valueOfInfinite doubleValue])) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= ([negValueOfInfinite doubleValue])){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        
        NSLog(@"The upper limit of reduced cost of %@ is %@", self.arrayOfConstraintNames[i], tempString);
    }
    
    NSLog(@"\n");
    
    //Logging the value of the reduced costs of variables
    
    for (int i = 0; i <cols; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfDuals[i+rows];
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        NSLog(@"The reduced cost of %@ is %@", self.arrayOfVariableNames[i],tempString);
    }
    
    NSLog(@"\n");
    
    //Logging the lower reduced cost of variables
    
    
    for (int i = 0; i <cols; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfDualsLower[rows+i];
        double tempDouble = [tempNumber doubleValue];
        if (tempDouble >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if (tempDouble <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if(tempDouble >= 10000000000.0 || tempDouble<= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
            NSLog(@"it's neither");
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        
        NSLog(@"The lower limit of reduced cost of %@ is %@", self.arrayOfVariableNames[i], tempString);
    }
    
    //Logging the Upper reduced cost of variables
    NSLog(@"\n");
    
    for (int i = 0; i <cols; ++i) {
        NSString *tempString = [[NSString alloc] init];
        NSNumber *tempNumber = [[NSNumber alloc] init];
        tempNumber = self.arrayOfDualsUpper[rows+i];
        if ([tempNumber doubleValue] >= [valueOfInfinite doubleValue]) {
            tempString = @"∞";
        }
        else if ([tempNumber doubleValue] <= [negValueOfInfinite doubleValue]){
            tempString = @"-∞";
        }
        else if([tempNumber doubleValue] >= 10000000000.0 || [tempNumber doubleValue] <= -100000000.0){
            tempString = [formatForScientific stringFromNumber:tempNumber];
        }
        else{
            tempString = [formatForDecimals stringFromNumber:tempNumber];
        }
        NSLog(@"The upper limit of reduced cost of %@ is %@", self.arrayOfVariableNames[i], tempString);
    }
    
    
    
    
    NSLog(@"\n");
    for (int i = 1; i <= cols; ++i) {
        NSString *tempString = [formatForDecimals stringFromNumber:self.arrayOfObjectiveCoefficients[i]];
        NSLog(@"The value of the objective coefficients is %@",tempString);
    }
    
    NSLog(@"\n");
    
    for (int i = 1; i <= rows; ++i) {
        NSString *tempString = [formatForDecimals stringFromNumber:self.arrayOfRHSValues[i]];
        NSLog(@"The RHS value of %@ is %@", self.arrayOfConstraintNames[i-1], tempString );
    }
    delete_lp(lp);
    free(cFilePath);
    
    //Enables the show results button
    
    if (self.returnValue == 0) {
        [self.showResultsButton setEnabled:YES];
    }
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
