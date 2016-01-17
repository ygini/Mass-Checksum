//
//  ReadOnlyMassChecksum.h
//  Mass Checksum
//
//  Created by Yoann Gini on 16/01/2016.
//  Copyright © 2016 Yoann Gini (Open Source Project). All rights reserved.
//

#import "MassChecksum.h"

@interface DummyMassChecksum : MassChecksum
@property NSString *checksumMethod;

- (void)importChecksum:(NSString*)checksum forRelativePath:(NSString*)relativePath;

@end
