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
@end

@implementation ScratchWindowController

enum   {
    kModelEntryViewTag = 0,   //Giving each view a tag for the changeViewcontrollerMethod
    kResultsViewtag
};


NSString *const kModelEntryView = @"ModelEntryView";
NSString *const kResultsView = @"ResultsView";

-(void) awakeFromNib{
    [self changeViewController:kModelEntryViewTag];
    [self.myModelEntryViewController.textField setRichText:NO];
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
            
        case kResultsViewtag:
            if (self.myResultsViewController == nil) {
                self.myResultsViewController = [[ResultsViewController alloc] initWithNibName:kResultsView bundle:nil];
            }
            self.myScratchViewController = self.myResultsViewController;
            
    }
    
    [self.scratchView addSubview: [self.myScratchViewController view]];
    [[self.myScratchViewController view] setFrame:[self.scratchView bounds]];
    
    
    //When the results view is loaded, the TableView gets it's data source and Delegate
    if (whichViewTag == kResultsViewtag) {
        self.myResultsViewController.variablesTableView.delegate = self;
        self.myResultsViewController.variablesTableView.dataSource = self;
        [self.myResultsViewController.variablesTableView reloadData];
    }
    
}


- (IBAction)solve:(NSButton *)sender {
    
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
    
    //Solving the saved model;
    
    lprec *lp;
    self.returnValue = 0;
    
    NSString *filePathNSString = [fileURL absoluteString];
    NSString *filePathModified = [filePathNSString substringFromIndex:7];
    
    NSLog(@"%@", filePathModified);
    
    const char *constCFilePath = [filePathModified UTF8String];
    char * cFilePath = strdup(constCFilePath);
    
    lp = read_LP( cFilePath, NORMAL, "test model");
    
    if(lp == NULL) {
        NSLog(@"Unable to create LP");
        self.returnValue = 1;
    }
    if (self.returnValue == 1) {
        NSBeginAlertSheet(@"Unable to Create LP", @"OK", @"", @"", self.modelWindow , self, @selector(sheetDidEnd: resultCode:contextInfo:), NULL, NULL, @"Unable to create LP frok the given input. Please check again ");
    }
    
    
    if (self.returnValue == 0) {
        int cols = get_Ncolumns(lp); //Get's the number of variables
        self.returnValue = solve(lp);
        
        self.optimizedValue = get_working_objective(lp); //The objective
        
        char* cArrayOfVariableNames[cols-1];
        REAL cArrayOfVariableValues[cols-1];
        
        if (!self.arrayOfVariableNames){
            self.arrayOfVariableNames = [[NSMutableArray alloc] init];
        }
        else {
            [self.arrayOfVariableNames removeAllObjects];
        }
        
            for (int i = 0; i< cols; i++){
                cArrayOfVariableNames[i] = get_origcol_name(lp, i+1);
                printf("varaibles in CArray: %s\n", cArrayOfVariableNames[i]);
                if (cArrayOfVariableNames[i]) {
                    NSString *tempString = [NSString stringWithCString:cArrayOfVariableNames[i] encoding:NSUTF8StringEncoding];
                    [self.arrayOfVariableNames addObject:tempString];
                }
                else{
                    self.returnValue = 2;
                }
            }
        
            get_variables(lp, cArrayOfVariableValues);
        printf("Number of columns: %d\n", cols);
       
        
        
        
        // creating an NSarray of Variable names
        
       
        
        //creating an array of Variable values
        
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
        
        
        if (self.returnValue == 2) {
            NSBeginAlertSheet(@"Issues with model" , @"OK", @"", @"", self.modelWindow , self, @selector(sheetDidEnd: resultCode:contextInfo:), NULL, NULL, @"There might be some issues with your model");
        }
        
        if (self.returnValue == 0) {
            [self.showResultsButton setEnabled:YES];
        }
        
        
        delete_lp(lp);
        free(cFilePath);
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


-(void) sheetDidEnd: (NSWindow *) sheet resultCode:(NSInteger) resultCode contextInfo:(void *) contextInfo{
    if (resultCode == NSAlertDefaultReturn) {
        NSLog(@"OK");
    }
}



@end
