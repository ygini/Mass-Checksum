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
@property (strong) NSString *globalChecksum;
@property (strong) IBOutlet NSButton *computeButton;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

@property (strong) IBOutlet NSTextField *helpText;

@property SHA1MassChecksum *massChecksum;
@property MassChecksumFile *massChecksumFileToVerify;
@property MassChecksumFile *massChecksumFile;

@property (strong) IBOutlet NSPanel *changelogPanel;
@property (strong) IBOutlet NSTextView *changelogTextView;

@end

@implementation Document

#pragma mark - Object Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.massChecksum = [SHA1MassChecksum new];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    
    if (self.massChecksumFileToVerify) {
        self.globalChecksum = self.massChecksumFileToVerify.globalChecksum;
        self.computeButton.title = @"Verify";
        
        if (self.massChecksumFileToVerify.massChecksum.basePath) {
            self.selectedPath = self.massChecksumFileToVerify.massChecksum.basePath;
            BOOL isDirectory = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:[self.selectedPath stringByExpandingTildeInPath] isDirectory:&isDirectory];
            
            if (isDirectory) {
                self.computeButton.enabled = YES;
                [self loadWorkingList];
            } else {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Base folder error"
                                                 defaultButton:@"OK"
                                               alternateButton:@"Cancel"
                                                   otherButton:nil
                                     informativeTextWithFormat:@"No access to original base folder, please select it."];
                
                if ([alert runModal] == NSOKButton) {
                    [self selectTargetFolderToVerify:self];
                    
                }
            }
        } else if ([self.massChecksumFileToVerify.massChecksum.computedDigest count] == 1) {
            self.selectedPath = [[self.massChecksumFileToVerify.massChecksum.computedDigest allKeys] lastObject];
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.selectedPath]) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Target file error"
                                                 defaultButton:@"OK"
                                               alternateButton:@"Cancel"
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Target file %@ not found, please select it.", [self.selectedPath lastPathComponent]];
                
                if ([alert runModal] == NSOKButton) {
                    [self selectTargetFileToVerify:self];
                }
            } else {
                [self loadWorkingList];
            }
            
        } else {
            assert(@"More than one file without base folder isn't supported in this version");
        }

    } else {
        self.computeButton.enabled = NO;
    }
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return self.massChecksumFileToVerify != nil ? self.massChecksumFileToVerify.fileRepresentationUTF8Encoded : self.massChecksumFile.fileRepresentationUTF8Encoded;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    self.massChecksumFileToVerify = [[MassChecksumFile alloc] initWithData:data];
    
    return YES;
}

#pragma mark - Actions

- (IBAction)selectTargetFileOrFolder:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES;
    
    [panel beginSheetModalForWindow:self.windowForSheet
                  completionHandler:^(NSInteger result) {
                      if (result == NSOKButton) {
                          self.selectedPath = [panel.URL path];
                          [self loadWorkingList];
                      }
                  }];
}

- (IBAction)selectTargetFolderToVerify:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    
    [panel beginSheetModalForWindow:self.windowForSheet
                  completionHandler:^(NSInteger result) {
                      if (result == NSOKButton) {
                          self.selectedPath = [panel.URL path];
                          [self loadWorkingList];
                      }
                  }];
}

- (IBAction)selectTargetFileToVerify:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    
    [panel beginSheetModalForWindow:self.windowForSheet
                  completionHandler:^(NSInteger result) {
                      if (result == NSOKButton) {
                          self.selectedPath = [panel.URL path];
                          [self loadWorkingList];
                      }
                  }];
}



- (IBAction)checkAction:(id)sender {
    
    if (self.massChecksumFileToVerify) {
        [self.massChecksum computeWorkingListWithCompletionHandler:^(MassChecksum *massChecksum) {
            self.massChecksumFile = [[MassChecksumFile alloc] initWithMassChecksum:massChecksum];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.massChecksumFileToVerify.globalChecksum isEqualToString:self.massChecksumFile.globalChecksum]) {
                    NSAlert * alert = [[NSAlert alloc] init];
                    
                    alert.alertStyle = NSInformationalAlertStyle;
                    alert.messageText = @"Success";
                    alert.informativeText = @"Target folder is the same as before!";
                    
                    [alert addButtonWithTitle:@"OK"];
                    
                    [alert beginSheetModalForWindow:self.windowForSheet
                                  completionHandler:^(NSModalResponse returnCode) {
                                      
                                  }];
                } else {
                    NSAlert * alert = [[NSAlert alloc] init];
                    
                    alert.alertStyle = NSInformationalAlertStyle;
                    alert.messageText = @"ERROR";
                    
                    [alert addButtonWithTitle:@"OK"];
                    
                    if ([self.massChecksumFileToVerify.massChecksum.basePath length] > 0) {
                        alert.informativeText = @"Target folder has changed!";
                        [alert addButtonWithTitle:@"Changelog"];
                    } else {
                        alert.informativeText = @"Target file has changed!";
                    }
                    
                    
                    [alert beginSheetModalForWindow:self.windowForSheet
                                  completionHandler:^(NSModalResponse returnCode) {
                                      if (returnCode == NSAlertSecondButtonReturn) {
                                          [self showDifferences];
                                      }
                                  }];
                }
                
            });

        }];
        
    } else {
        [self.massChecksum computeWorkingListWithCompletionHandler:^(MassChecksum *massChecksum) {
            self.massChecksumFile = [[MassChecksumFile alloc] initWithMassChecksum:massChecksum];
            
            self.globalChecksum = self.massChecksumFile.globalChecksum;
        }];
    }
}

- (void)showDifferences {
    NSDictionary *originalDigestes = self.massChecksumFileToVerify.massChecksum.computedDigest;
    NSDictionary *currentDigestes = self.massChecksumFile.massChecksum.computedDigest;
    
    
    NSMutableArray *createdFiles = [NSMutableArray new];
    NSMutableArray *deletedFiles = [NSMutableArray new];
    NSMutableArray *updatedFiles = [NSMutableArray new];
    
    for (NSString *file in [originalDigestes allKeys]) {
        NSString *oldDigest = [originalDigestes objectForKey:file];
        NSString *newDigest = [currentDigestes objectForKey:file];
        
        if (!newDigest) {
            [deletedFiles addObject:file];
        } else if (![oldDigest isEqualToString:newDigest]) {
            [updatedFiles addObject:file];
        }
    }
    
    for (NSString *file in [currentDigestes allKeys]) {
        NSString *oldDigest = [originalDigestes objectForKey:file];
        
        if (!oldDigest) {
            [createdFiles addObject:file];
        }
    }
    
    NSMutableString *differencesLog = [NSMutableString new];
    
    [differencesLog appendString:@"### Created Files ###"];
    [differencesLog appendString:@"\n"];
    
    for (NSString *file in createdFiles) {
        [differencesLog appendString:file];
        [differencesLog appendString:@"\n"];
    }
    
    [differencesLog appendString:@"\n"];
    [differencesLog appendString:@"### Deleted Files ###"];
    [differencesLog appendString:@"\n"];
    
    for (NSString *file in deletedFiles) {
        [differencesLog appendString:file];
        [differencesLog appendString:@"\n"];
    }
    
    [differencesLog appendString:@"\n"];
    [differencesLog appendString:@"### Updated Files ###"];
    [differencesLog appendString:@"\n"];
    
    for (NSString *file in updatedFiles) {
        [differencesLog appendString:file];
        [differencesLog appendString:@"\n"];
    }
    
    self.changelogTextView.string = differencesLog;
    
    [self.windowForSheet beginSheet:self.changelogPanel completionHandler:^(NSModalResponse returnCode) {
    }];
    
}

#pragma mark - Changelog actions

- (IBAction)closeChangelog:(id)sender {
    [self.windowForSheet endSheet:self.changelogPanel];
}

- (IBAction)saveChangelog:(id)sender {
    [self.windowForSheet endSheet:self.changelogPanel];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    savePanel.allowedFileTypes = @[@"txt"];
    
    [savePanel beginSheetModalForWindow:self.windowForSheet
                      completionHandler:^(NSInteger result) {
                          if (result == NSFileHandlingPanelOKButton) {
                              NSError *error = nil;
                              [self.changelogTextView.string writeToFile:[savePanel.URL path]
                                                              atomically:YES
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
                              
                              if (error) {
                                  NSAlert *alert = [NSAlert alertWithError:error];
                                  [alert beginSheetModalForWindow:self.windowForSheet
                                                completionHandler:^(NSModalResponse returnCode) {
                                                }];
                              }
                          }
                      }];
}


#pragma mark - Worklist actions

- (void)loadWorkingList {
    [self startLoadingWorkingList];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectory = NO;
    [fm fileExistsAtPath:[self.selectedPath stringByExpandingTildeInPath] isDirectory:&isDirectory];
    
    if (isDirectory) {
        [self.massChecksum changeBasePath:self.selectedPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSURL *directoryURL = [[NSURL alloc] initFileURLWithPath:[self.selectedPath stringByExpandingTildeInPath]];
            
            NSDirectoryEnumerator *directoryEnum = [fm enumeratorAtURL:directoryURL
                                            includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                               options:0
                                                          errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                              NSAlert *alert = [NSAlert alertWithError:error];
                                                              [alert beginSheetModalForWindow:self.windowForSheet
                                                                            completionHandler:^(NSModalResponse returnCode) {
                                                                            }];
                                                              
                                                              return NO;
                                                          }];
            
            NSRange basePathRange;
            basePathRange.location = 0;
            basePathRange.length = [self.selectedPath length];
            
            for (NSURL *contentURL in directoryEnum) {
                NSError *error = nil;
                NSNumber *isDirectoryObject = nil;
                [contentURL getResourceValue:&isDirectoryObject
                                      forKey:NSURLIsDirectoryKey
                                       error:&error];
                
                if (error) {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert beginSheetModalForWindow:self.windowForSheet
                                  completionHandler:^(NSModalResponse returnCode) {
                                  }];
                    
                } else if (![isDirectoryObject boolValue]){
                    [self.massChecksum addRelativePathToWorkingList:[[contentURL path] stringByReplacingCharactersInRange:basePathRange withString:@""]];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishedLoadingWorkingList];
            });
        });
    } else {
        [self.massChecksum changeBasePath:nil];
        [self.massChecksum addRelativePathToWorkingList:self.selectedPath];
        [self finishedLoadingWorkingList];
    }
}

- (void)startLoadingWorkingList {
    [self.massChecksum clearWorkingList];
    self.computeButton.enabled = NO;
    [self.progressIndicator startAnimation:self];
}

- (void)finishedLoadingWorkingList {
    self.computeButton.enabled = YES;
    [self.progressIndicator stopAnimation:self];
}

@end
