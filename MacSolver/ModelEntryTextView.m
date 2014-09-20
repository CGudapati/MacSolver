//
//  ModelEntryTextView.m
//  MacSolver
//
//  Created by Chaitanya on 14/09/14.
//  Copyright (c) 2014 Gudapati Naga Venkata Chaitanya. All rights reserved.
//

#import "ModelEntryTextView.h"

@implementation ModelEntryTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
    }
    return self;
}


- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender{
    
    
    NSPasteboard *tempPasteBoard = [sender draggingPasteboard];
    NSDragOperation dragOperation = [sender draggingSourceOperationMask];
    
    if ([[tempPasteBoard types] containsObject:NSFilenamesPboardType]) {
        if (dragOperation && NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
        if ([[tempPasteBoard types] containsObject:NSPasteboardTypeString]) {
            if (dragOperation && NSDragOperationCopy) {
                return NSDragOperationCopy;
            }
        }
        
        
    }
    return NSDragOperationNone;
    
}


-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *tempPasteBoard = [sender draggingPasteboard];
    
    if ( [[tempPasteBoard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *fileNames = [tempPasteBoard propertyListForType:NSFilenamesPboardType];
        
        for (NSString *filename in fileNames) {
            NSStringEncoding encoding;
            NSError * error;
            NSString * fileContents = [NSString stringWithContentsOfFile:filename usedEncoding:&encoding error:&error];
            if (error) {
                // handle error
            }
            else {
                [self setString:fileContents];
            }
        }
        
    }
    
    else if ( [[tempPasteBoard types] containsObject:NSPasteboardTypeString] ) {
        NSString *draggedString = [tempPasteBoard stringForType:NSPasteboardTypeString];
        [self setString:draggedString];
    }
    
    return YES;
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

}

@end
