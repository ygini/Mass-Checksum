//
//  ReadOnlyMassChecksum.m
//  Mass Checksum
//
//  Created by Yoann Gini on 16/01/2016.
//  Copyright © 2016 Yoann Gini (Open Source Project). All rights reserved.
//

#import "DummyMassChecksum.h"

@implementation DummyMassChecksum

+ (NSString*)checksum:(NSData*)data {
    assert("You can't use checksum: on the read only subclass!");
    return nil;
}

- (void)importChecksum:(NSString*)checksum forRelativePath:(NSString*)relativePath {
    [self.computedDigest setObject:checksum forKey:relativePath];
}

@end
