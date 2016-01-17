//
//  MassChecksumFile.m
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "MassChecksumFile.h"
#import "MassChecksum.h"
#import "DummyMassChecksum.h"
#import "SHA1MassChecksum.h"

#define kMassChecksumFileOriginalSourcePrefix @"#originalSource:"

@interface MassChecksumFile ()

@property NSMutableArray *arrayOfString;

@property MassChecksum *massChecksum;

@end

@implementation MassChecksumFile

#pragma mark - Object Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithMassChecksum:(MassChecksum*)massChecksum {
    self = [self init];
    if (self) {
        self.massChecksum = massChecksum;
        self.arrayOfString = [NSMutableArray new];
        
        for (NSString *path in [self.massChecksum.computedDigest allKeys]) {
            [self.arrayOfString addObject:[[self class] checksumLineForPath:path
                                                               withChecksum:[self.massChecksum.computedDigest objectForKey:path]
                                                          andChecksumMethod:self.massChecksum.checksumMethod]];
        }
        
        [self.arrayOfString sortUsingSelector:@selector(compare:)];
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL*)checksumFileURL {
    self = [self init];
    if (self) {
        NSError *error = nil;
        [self commonInitWhenLoadingFromPreviousChecksumWithFileContent:[NSString stringWithContentsOfURL:checksumFileURL
                                                                                                encoding:NSUTF8StringEncoding
                                                                                                   error:&error]];
    }
    return self;
}

- (instancetype)initWithData:(NSData*)checksumFileData {
    self = [self init];
    if (self) {
        [self commonInitWhenLoadingFromPreviousChecksumWithFileContent:[NSString stringWithUTF8String:[checksumFileData bytes]]];
    }
    return self;
}

- (void)commonInitWhenLoadingFromPreviousChecksumWithFileContent:(NSString*)fileContent {
    
    self.arrayOfString = [[fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    
    [self.arrayOfString filterUsingPredicate:[NSPredicate predicateWithFormat:@"self != NULL && self != %@", @""]];

    DummyMassChecksum *massChecksum = [DummyMassChecksum new];
    
    NSString *firstLine = [self.arrayOfString firstObject];
    NSRange prefixRange = [firstLine rangeOfString:kMassChecksumFileOriginalSourcePrefix];
    
    NSString *originalSourceFolder = nil;
    
    if (prefixRange.location == 0) {
        [self.arrayOfString removeObjectAtIndex:0];
        originalSourceFolder = [firstLine stringByReplacingCharactersInRange:prefixRange withString:@""];
    }
    
    [massChecksum changeBasePath:originalSourceFolder];
    
    NSString *checksumMethod = nil;
    NSInteger checksumMethodChange = 0;
    for (NSString *line in self.arrayOfString) {
        NSDictionary *info = [[self class] checksumInfoFromLine:line];
        
        if (info) {
            [massChecksum importChecksum:info[@"checksum"] forRelativePath:info[@"path"]];
            
            if (![checksumMethod isEqualToString:info[@"checksumMethod"]]) {
                checksumMethod = info[@"checksumMethod"];
                checksumMethodChange++;
                NSAssert(checksumMethodChange <= 1, @"Checksum file use multiple checksum method, this is not supported by this release.");
            }
        }
    }
    
    massChecksum.checksumMethod = checksumMethod;
    
    self.massChecksum = massChecksum;
}

#pragma mark - Toolbox

+ (NSString*)checksumLineForPath:(NSString*)path withChecksum:(NSString*)checksum andChecksumMethod:(NSString*)checksumMethod {
    return [NSString stringWithFormat:@"(%@)[%@]%@", checksumMethod, checksum, path];
}

+ (NSDictionary*)checksumInfoFromLine:(NSString*)line {
    
    if ([line length] > 0) {
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        NSString *checksumMethod = nil;
        NSString *checksum = nil;
        NSString *path = nil;
        
        if (![scanner scanString:@"(" intoString:nil]) {
            assert("Checksum line don't start by \"(\"!");
        }
        
        if (![scanner scanUpToString:@")" intoString:&checksumMethod]) {
            assert("Impossible to read checksum method!");
        }
        
        scanner.scanLocation = scanner.scanLocation + 1;
        
        if (![scanner scanString:@"[" intoString:nil]) {
            assert("Checksum line don't contain valid checksum starting by \"[\"!");
        }
        
        if (![scanner scanUpToString:@"]" intoString:&checksum]) {
            assert("Impossible to read checksum!");
        }
        
        scanner.scanLocation = scanner.scanLocation + 1;
        
        path = [line substringFromIndex:scanner.scanLocation];
        
        return @{@"path": path, @"checksumMethod": checksumMethod, @"checksum" : checksum};
    }
    
    return nil;
}

#pragma mark - Accessors

- (NSString*)fileRepresentation {
    NSMutableString *finalString = [NSMutableString new];
    
    if ([self.massChecksum.basePath length] > 0) {
        [finalString appendString:kMassChecksumFileOriginalSourcePrefix];
        [finalString appendString:self.massChecksum.basePath];
        [finalString appendString:@"\n"];
                
        for (NSString *line in self.arrayOfString) {
            [finalString appendString:line];
            [finalString appendString:@"\n"];
        }
    } else if ([self.arrayOfString count] == 1) {
        [finalString appendString:[self.arrayOfString lastObject]];
        [finalString appendString:@"\n"];
    } else {
        assert(@"More than one file without base folder isn't supported in this version");
    }
    
    return finalString;
}

- (NSData*)fileRepresentationUTF8Encoded {
    return [[self fileRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)globalChecksum {
    
    if ([self.massChecksum.computedDigest count] == 0) {
        return @"ERROR, no digests to create a general one";
    } else if ([self.massChecksum.computedDigest count] == 1) {
        return [self.massChecksum.computedDigest.allValues lastObject];
    } else {
        return [SHA1MassChecksum checksum:[self fileRepresentationUTF8Encoded]];
    }
}


#pragma mark - Write methods

- (void)writeToFile:(NSString*)path atomically:(BOOL)atomically {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    [self writeToURL:url atomically:atomically];
}

- (void)writeToURL:(NSURL*)url atomically:(BOOL)atomically {
    
    NSError *error = nil;
    [[self fileRepresentation] writeToURL:url
                               atomically:atomically
                                 encoding:NSUTF8StringEncoding
                                    error:&error];
}

@end
