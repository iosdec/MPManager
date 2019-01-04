//
//  MPContent.m
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import "MPContent.h"

@implementation MPContent

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    } return self;
}

#pragma mark    -   Setup:

- (void)setup {
    
    
    
}

#pragma mark    -   Checker:

- (BOOL)hasValidContent {
    
    if (!self.image && !self.string && !self.htmlString && !self.mutableString && !self.view && !self.url) {
        return NO;
    }
    
    //  check string length:
    if (self.string) {
        if (self.string.length == 0) {
            return NO;
        }
    }
    
    //  check html string length:
    if (self.htmlString) {
        if (self.htmlString.length == 0) {
            return NO;
        }
    }
    
    //  check mutable string length:
    if (self.mutableString) {
        if (self.mutableString.length == 0) {
            return NO;
        }
    }
    
    return YES;
    
}

@end
