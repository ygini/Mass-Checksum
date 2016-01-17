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
@property (readonly) NSString *basePath;

+ (NSString*)checksum:(NSData*)data;

- (void)changeBasePath:(NSString*)basePath;
- (void)addRelativePathToWorkingList:(NSString*)relativePath;
- (void)clearWorkingList;
- (void)computeWorkingListWithCompletionHandler:(MassChecksumCompletionHandler)completionHandler;
- (void)setWorklistToSingleFile:(NSURL*)singleFileURL;

- (NSString*)checksumMethod;

@end
