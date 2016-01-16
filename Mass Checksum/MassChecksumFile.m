//
//  MassChecksumFile.m
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "MassChecksumFile.h"

@interface MassChecksumFile ()

@property NSString *checksumMethod;

@property NSMutableArray *arrayOfString;
@property NSMutableDictionary *checksumTable;

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

- (instancetype)initWithDictionary:(NSDictionary*)checksumDictionary andChecksumMethod:(NSString*)checksumMethod {
    self = [self init];
    if (self) {
        self.checksumTable = [checksumDictionary mutableCopy];
        self.checksumMethod = checksumMethod;
        self.arrayOfString = [NSMutableArray new];
        
        for (NSString *path in [checksumDictionary allKeys]) {
            [self.arrayOfString addObject:[[self class] checksumLineForPath:path
                                                               withChecksum:[checksumDictionary objectForKey:path]
                                                          andChecksumMethod:checksumMethod]];
        }
        
        [self.arrayOfString sortUsingSelector:@selector(compare:)];
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL*)checksumFileURL {
    self = [self init];
    if (self) {
        self.checksumTable = [NSMutableDictionary new];
        NSError *error = nil;
        NSString *fileContent = [NSString stringWithContentsOfURL:checksumFileURL
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
        
        self.arrayOfString = [[fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        
        NSString *checksumMethod = nil;
        NSInteger checksumMethodChange = 0;
        for (NSString *line in self.arrayOfString) {
            NSDictionary *info = [[self class] checksumInfoFromLine:line];
            [self.checksumTable setObject:[[NSURL alloc] initFileURLWithPath:info[@"path"]] forKey:info[@"checksum"]];
            
            if (![checksumMethod isEqualToString:info[@"checksumMethod"]]) {
                checksumMethod = info[@"checksumMethod"];
                NSAssert(++checksumMethodChange > 1, @"Checksum file use multiple checksum method, this is not supported by this release.");
            }
        }
        
        self.checksumMethod = checksumMethod;
    }
    return self;
}

#pragma mark - Toolbox

+ (NSString*)checksumLineForPath:(NSString*)path withChecksum:(NSString*)checksum andChecksumMethod:(NSString*)checksumMethod {
    return [NSString stringWithFormat:@"(%@)[%@]%@", checksumMethod, checksum, path];
}

+ (NSDictionary*)checksumInfoFromLine:(NSString*)line {
    
    NSAssert([line containsString:@"\n"], @"The checksum line contain a line break, this is not possible");
    
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
    
    if (![scanner scanString:@"[" intoString:nil]) {
        assert("Checksum line don't contain valid checksum starting by \"[\"!");
    }
    
    if (![scanner scanUpToString:@"]" intoString:&checksum]) {
        assert("Impossible to read checksum!");
    }
    
    path = [line substringFromIndex:scanner.scanLocation];
    
    return @{@"path": path, @"checksumMethod": checksumMethod, @"checksum" : checksum};
}

#pragma mark - Accessors

- (NSDictionary*)dictionaryRepresentation {
    return [self.checksumTable copy];
}

- (NSString*)fileRepresentation {
    NSMutableString *finalString = [NSMutableString new];
    
    for (NSString *line in self.arrayOfString) {
        [finalString appendString:line];
        [finalString appendString:@"\n"];
    }
    
    return finalString;
}

- (NSData*)fileRepresentationUTF8Encoded {
    return [[self fileRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
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
