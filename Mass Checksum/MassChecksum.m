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

- (void)addURLToWorkingList:(NSURL*)contentURL {
    [self.workingList addObject:contentURL];
}

#pragma mark - Checksum actions

- (void)doChecksum {
    [self.computedDigest removeAllObjects];
    
    dispatch_group_t checksum_group = dispatch_group_create();
    
    for (NSURL *targetURL in self.workingList) {
        dispatch_group_async(checksum_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSError *error = nil;
            NSData *targetData = [[NSData alloc] initWithContentsOfURL:targetURL options:NSDataReadingMappedIfSafe | NSDataReadingUncached error:&error];
            
            if (targetData) {
                NSString *SHA1Digest = [[self class] checksum:targetData];
                [self registerDigest:SHA1Digest forURL:targetURL];
            } else {
                // TODO: Error handling
                NSLog(@"Checksum in progress, impossible to open stream for %@", targetURL);
            }
            
        });
    }
    
    dispatch_group_wait(checksum_group, DISPATCH_TIME_FOREVER);
}

- (void)registerDigest:(NSString*)digest forURL:(NSURL*)fileURL {
    static OSSpinLock lock = OS_SPINLOCK_INIT;
    
    OSSpinLockLock(&lock);
    [self.computedDigest setObject:digest forKey:[fileURL path]];
    OSSpinLockUnlock(&lock);
}

@end
