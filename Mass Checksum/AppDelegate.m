//
//  AppDelegate.m
//  Mass Checksum
//
//  Created by Yoann Gini on 03/12/2015.
//  Copyright © 2015 Yoann Gini (Open Source Project). All rights reserved.
//

#import "AppDelegate.h"

#import "Constants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kMassCheckLastSelection: @"~"}];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
