//
//  Document.m
//  Mass Checksum
//
//  Created by Yoann Gini on 03/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "Document.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Constants.h"

@interface Document ()

@property IBOutlet NSString *selectedPath;
@property (weak) IBOutlet NSTextField *numberOfItemLabel;

@property NSMutableDictionary *computedDigest;
@property NSMutableDictionary *originalDigest;

@property NSMutableArray *workingList;
@property NSInteger numberOfItems;

@property NSTimer *updateUITimer;

@end

@implementation Document

#pragma mark - Object Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedPath = [[NSUserDefaults standardUserDefaults] stringForKey:kMassCheckLastSelection];
        self.workingList = [NSMutableArray new];
        self.computedDigest = [NSMutableDictionary new];
        self.originalDigest = [NSMutableDictionary new];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
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

- (IBAction)checksumAction:(id)sender {
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
            
            [self finishedLoadingWorkingList];
        });
    } else {
        NSURL *contentURL = [[NSURL alloc] initFileURLWithPath:[self.selectedPath stringByExpandingTildeInPath]];
        [self addURLToWorkingList:contentURL];
        [self finishedLoadingWorkingList];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedPath forKey:kMassCheckLastSelection];
}

#pragma mark - Worklist actions

- (void)startLoadingWorkingList {
    _numberOfItems = 0;
    [self.workingList removeAllObjects];
    
    self.updateUITimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(updateUIWhenLoadingWorkingList)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)finishedLoadingWorkingList {
    [self.updateUITimer invalidate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self doChecksum];
    });
   
}

- (void)addURLToWorkingList:(NSURL*)contentURL {
    [self.workingList addObject:contentURL];
    _numberOfItems++;
}

- (void)updateUIWhenLoadingWorkingList {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.numberOfItemLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfItems];
    });
}

#pragma mark - Checksum actions

- (void)doChecksum {
    [self.workingList sortUsingComparator:^NSComparisonResult(NSURL *obj1, NSURL *obj2) {
        return [[obj1 path] compare:[obj2 path]];
    }];
    
    [self.computedDigest removeAllObjects];
    
    dispatch_group_t checksum_group = dispatch_group_create();
    
    for (NSURL *targetURL in self.workingList) {
        dispatch_group_async(checksum_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSError *error = nil;
            NSData *targetData = [[NSData alloc] initWithContentsOfURL:targetURL options:NSDataReadingMappedIfSafe | NSDataReadingUncached error:&error];
            
            if (targetData) {
                unsigned char digest[CC_SHA1_DIGEST_LENGTH];
                
                CC_SHA1([targetData bytes], (CC_LONG)[targetData length], digest);

                char hash[2 * sizeof(digest) + 1];
                for (size_t i = 0; i < sizeof(digest); ++i) {
                    snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
                }
                
                NSString *SHA1Digest = [NSString stringWithUTF8String:hash];
                
                [self registerDigest:SHA1Digest forURL:targetURL];
            } else {
                // TODO: Error handling
                NSLog(@"Checksum in progress, impossible to open stream for %@", targetURL);
            }
            
        });
    }
    
    dispatch_group_wait(checksum_group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"%@",self.computedDigest);
}

- (void)registerDigest:(NSString*)digest forURL:(NSURL*)fileURL {
    [self.computedDigest setObject:digest forKey:[fileURL path]];
}

@end
