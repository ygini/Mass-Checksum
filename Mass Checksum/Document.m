//
//  Document.m
//  Mass Checksum
//
//  Created by Yoann Gini on 03/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "Document.h"
#import "Constants.h"
#import "SHA1MassChecksum.h"
#import "MassChecksumFile.h"

@interface Document ()

@property IBOutlet NSString *selectedPath;
@property (weak) IBOutlet NSTextField *numberOfItemLabel;
@property (strong) IBOutlet NSTextField *globalChecksumField;
@property (strong) IBOutlet NSButton *checkButton;

@property NSMutableDictionary *originalDigest;

@property NSTimer *updateUITimer;
@property NSUInteger numberOfItems;

@property SHA1MassChecksum *massChecksum;
@end

@implementation Document

#pragma mark - Object Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMassCheckLastSelection];
        self.originalDigest = [NSMutableDictionary new];
        self.massChecksum = [SHA1MassChecksum new];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [self.checkButton setEnabled:NO];
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return YES;
}

#pragma mark - Actions

- (IBAction)selectTargetFileOrFolder:(id)sender {
}



- (IBAction)checkAction:(id)sender {
    [self.massChecksum computeWorkingListWithCompletionHandler:^(MassChecksum *massChecksum) {
        MassChecksumFile *massChecksumFile = [[MassChecksumFile alloc] initWithDictionary:massChecksum.computedDigest andChecksumMethod:massChecksum.checksumMethod];
        
    }];
}

#pragma mark - Worklist actions

- (void)loadWorkingList {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectory = NO;
    [fm fileExistsAtPath:[self.selectedPath stringByExpandingTildeInPath] isDirectory:&isDirectory];
    
    [self startLoadingWorkingList];
    
    if (isDirectory) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSURL *directoryURL = [[NSURL alloc] initFileURLWithPath:[self.selectedPath stringByExpandingTildeInPath]];
            
            NSDirectoryEnumerator *directoryEnum = [fm enumeratorAtURL:directoryURL
                                            includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                               options:0
                                                          errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                              // TODO: See what happen with access right errors
                                                              NSLog(@"%@", error);
                                                              return YES;
                                                          }];
            
            for (NSURL *contentURL in directoryEnum) {
                NSError *error = nil;
                NSNumber *isDirectoryObject = nil;
                [contentURL getResourceValue:&isDirectoryObject
                                      forKey:NSURLIsDirectoryKey
                                       error:&error];
                
                if (error) {
                    // TODO: Error handling
                    NSLog(@"%@", error);
                } else if (![isDirectoryObject boolValue]){
                    [self addURLToWorkingList:contentURL];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishedLoadingWorkingList];
            });
        });
    } else {
        NSURL *contentURL = [[NSURL alloc] initFileURLWithPath:[self.selectedPath stringByExpandingTildeInPath]];
        [self addURLToWorkingList:contentURL];
        [self finishedLoadingWorkingList];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedPath forKey:kMassCheckLastSelection];
}

- (void)startLoadingWorkingList {
    _numberOfItems = 0;
    self.updateUITimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(updateUIWhenLoadingWorkingList)
                                                        userInfo:nil
                                                         repeats:YES];
    
    [self.massChecksum clearWorkingList];
    [self.checkButton setEnabled:NO];
}

- (void)finishedLoadingWorkingList {
    [self.updateUITimer invalidate];
    [self updateUIWhenLoadingWorkingList];
    [self.checkButton setEnabled:YES];
}

- (void)addURLToWorkingList:(NSURL*)contentURL {
    _numberOfItems++;
    [self.massChecksum addURLToWorkingList:contentURL];
}

- (void)updateUIWhenLoadingWorkingList {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.numberOfItemLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfItems];
    });
}

@end
