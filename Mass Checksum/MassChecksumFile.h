//
//  MassChecksumFile.h
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import <Foundation/Foundation.h>

@class MassChecksum;

@interface MassChecksumFile : NSObject

- (instancetype)initWithMassChecksum:(MassChecksum*)massChecksum;
- (instancetype)initWithFileURL:(NSURL*)checksumFileURL;
- (instancetype)initWithData:(NSData*)checksumFileData;

- (NSString*)fileRepresentation;
- (NSData*)fileRepresentationUTF8Encoded;
- (NSString*)globalChecksum;

@property (readonly) MassChecksum *massChecksum;

- (void)writeToFile:(NSString*)path atomically:(BOOL)atomically;
- (void)writeToURL:(NSURL*)url atomically:(BOOL)atomically;

+ (NSString*)checksumLineForPath:(NSString*)path withChecksum:(NSString*)checksum andChecksumMethod:(NSString*)checksumMethod;
+ (NSDictionary*)checksumInfoFromLine:(NSString*)line;

@end
