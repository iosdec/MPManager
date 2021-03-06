//
//  MPManagerJob.m
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import "MPManagerJob.h"

@implementation MPManagerJob

- (id)init {
    self = [super init];
    if (self) {
       [self setupDefaults];
    } return self;
}

#pragma mark    -   Setup Defaults:

- (void)setupDefaults {
    self.processed          =   NO;
    self.printed            =   NO;
}

#pragma mark    -   Checker:

- (BOOL)isValidJob {
    if (!self.content) { return NO; }
    if (!self.content.hasValidContent) { return NO; }
    return YES;
}

@end
