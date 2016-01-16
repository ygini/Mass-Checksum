//
//  MassChecksum.h
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import <Foundation/Foundation.h>


@class MassChecksum;

typedef void(^MassChecksumCompletionHandler)(MassChecksum *massChecksum);

@interface MassChecksum : NSObject

@property (readonly) NSMutableDictionary *computedDigest;
@property (readonly) NSMutableArray *workingList;

+ (NSString*)checksum:(NSData*)data;

- (void)addURLToWorkingList:(NSURL*)contentURL;
- (void)clearWorkingList;
- (void)computeWorkingListWithCompletionHandler:(MassChecksumCompletionHandler)completionHandler;

- (NSString*)checksumMethod;

@end
