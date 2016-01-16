//
//  MassChecksumFile.h
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MassChecksumFile : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)checksumDictionary andChecksumMethod:(NSString*)checksumMethod;
- (instancetype)initWithFileURL:(NSURL*)checksumFileURL;

- (NSDictionary*)dictionaryRepresentation;
- (NSString*)fileRepresentation;
- (NSData*)fileRepresentationUTF8Encoded;
- (NSString*)checksumMethod;

- (void)writeToFile:(NSString*)path atomically:(BOOL)atomically;
- (void)writeToURL:(NSURL*)url atomically:(BOOL)atomically;

+ (NSString*)checksumLineForPath:(NSString*)path withChecksum:(NSString*)checksum andChecksumMethod:(NSString*)checksumMethod;
+ (NSDictionary*)checksumInfoFromLine:(NSString*)line;

@end
