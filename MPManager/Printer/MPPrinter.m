//
//  MPPrinter.m
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import "MPPrinter.h"
#import "MPManager.h"

@implementation MPPrinter

#pragma mark    -   Contact:

- (void)checkOnline:(void (^)(BOOL))completion {
    
    if (!self.address) {
        if (completion) {
            completion(NO);
        } return;
    }
    
    if (self.address.length == 0) {
        if (completion) {
            completion(NO);
        } return;
    }
    
    //  get type:
    MPPrinterType type          =   [self printerType];
    
    //  AIRPRINT:
    if (type == MPPrinterTypeAirprint) {
        
        UIPrinter *printer      =   [UIPrinter printerWithURL:[NSURL URLWithString:self.address]];
        [printer contactPrinter:^(BOOL available) {
            if (completion) {
                completion(available);
            } return;
        }];
        
    }
    
    //  BLUETOOTH:
    if (type == MPPrinterTypeBluetooth) {
        
        //  for now.. just use epos:
        Epos2Printer *printer           =   [self eposPrinterWithAddress:self.address];
        if (printer) {
            if (completion) { completion(YES); } return;
        }
        if (!printer) {
            if (completion) { completion(NO); } return;
        }
        
    }
    
    //  TCP:
    if (type == MPPrinterTypeTCP) {
        
        //  not supported yet.
        if (completion) {
            completion(NO);
        }
        
    }
    
}

- (Epos2Printer *)eposPrinterWithAddress:(NSString *)ipAddress {
    
    if (!ipAddress) { return nil; }
    
    Epos2Printer *tmpPrinter            =   [[Epos2Printer alloc] initWithPrinterSeries:0 lang:0];
    Epos2PrinterStatusInfo *info        =   [[Epos2PrinterStatusInfo alloc] init];
    info                                =   [tmpPrinter getStatus];
    int result = [tmpPrinter connect:ipAddress timeout:EPOS2_PARAM_DEFAULT];
    
    if (result == EPOS2_SUCCESS) {
        return tmpPrinter;
    }
    
    return nil;
    
}

- (MPPrinterType)printerType {
    
    if (!self.address) {
        return MPPrinterTypeNA;
    }
    if (self.address.length == 0) {
        return MPPrinterTypeNA;
    }
    
    //  AIRPRINT:
    if ([self.address containsString:@"IPP://"] || [self.address containsString:@"ipp://"] || [self.address containsString:@"IPPS://"] || [self.address containsString:@"ipps://"]) {
        return MPPrinterTypeAirprint;
    }
    
    //  BLUETOOTH:
    if ([self.address containsString:@"BT:"] || [self.address containsString:@"bt:"]) {
        return MPPrinterTypeBluetooth;
    }
    
    //  TCP:
    if ([self.address containsString:@"TCP://"] || [self.address containsString:@"tcp://"]) {
        return MPPrinterTypeTCP;
    }
    
    //  NONE:
    return MPPrinterTypeNA;
    
}

#pragma mark    -   Check Valid:

- (BOOL)isValidPrinter {
    if (!self.address) { return NO; }
    if (self.address.length == 0) { return NO; }
    return YES;
}


@end
