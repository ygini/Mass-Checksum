//
//  SHA1MassChecksum.m
//  Mass Checksum
//
//  Created by Yoann Gini on 17/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "SHA1MassChecksum.h"
#import <CommonCrypto/CommonCrypto.h>



@implementation SHA1MassChecksum

+ (NSString*)checksum:(NSData*)data {
    if (data) {
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        
        CC_SHA1([data bytes], (CC_LONG)[data length], digest);
        
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        
        NSString *SHA1Digest = [NSString stringWithUTF8String:hash];
        
        return SHA1Digest;
    }
    
    return nil;
}

- (NSString*)checksumMethod {
    return @"SHA1";
}

@end
