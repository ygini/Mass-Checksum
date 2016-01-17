//
//  MassChecksum.m
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "MassChecksum.h"

@interface MassChecksum ()

@property NSMutableDictionary *computedDigest;
@property NSMutableArray *workingList;
@property NSString *basePath;

@end

@implementation MassChecksum

#pragma mark - Object Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.workingList = [NSMutableArray new];
        self.computedDigest = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Abstract methods

+ (NSString*)checksum:(NSData*)data {
    assert("You can't use MassChecksum by itself! You must use a specialized subclass!");
    return nil;
}

- (NSString*)checksumMethod {
    return @"ERROR";
}

- (void)changeBasePath:(NSString *)basePath {
    [self clearWorkingList];
    [self.computedDigest removeAllObjects];
    self.basePath = basePath;
}

#pragma mark - Worklist actions


- (void)clearWorkingList {
    [self.workingList removeAllObjects];
}

- (void)computeWorkingListWithCompletionHandler:(MassChecksumCompletionHandler)completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self doChecksum];
        
        completionHandler(self);
    });
}

- (void)addRelativePathToWorkingList:(NSString *)relativePath {
    [self.workingList addObject:relativePath];
}

- (void)setWorklistToSingleFile:(NSURL*)singleFileURL {
    [self changeBasePath:nil];
    [self.workingList addObject:singleFileURL];
}

#pragma mark - Checksum actions

- (void)doChecksum {
    [self.computedDigest removeAllObjects];
    
    
    dispatch_group_t checksum_group = dispatch_group_create();
    
    for (NSString *relativePath in self.workingList) {
        dispatch_group_async(checksum_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSString *targetPath = nil;
            if (self.basePath) {
                targetPath = [self.basePath stringByAppendingPathComponent:relativePath];
            } else {
                targetPath = relativePath;
            }
            
            NSError *error = nil;
            NSData *targetData = [[NSData alloc] initWithContentsOfFile:targetPath options:NSDataReadingMappedIfSafe | NSDataReadingUncached error:&error];
            
            if (targetData) {
                NSString *SHA1Digest = [[self class] checksum:targetData];
                [self registerDigest:SHA1Digest forRelativePath:relativePath];
            } else {
                // TODO: Error handling
                NSLog(@"Checksum in progress, impossible to open stream for %@", targetPath);
            }
            
        });
    }
    
    dispatch_group_wait(checksum_group, DISPATCH_TIME_FOREVER);
    
    
}

- (void)registerDigest:(NSString*)digest forRelativePath:(NSString*)relativePath {
    static OSSpinLock lock = OS_SPINLOCK_INIT;
    
    OSSpinLockLock(&lock);
    [self.computedDigest setObject:digest forKey:relativePath];
    OSSpinLockUnlock(&lock);
}

@end
