//
//  MPPrinter.h
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    MPPrinterTypeNA         =   0,
    MPPrinterTypeAirprint   =   1,
    MPPrinterTypeBluetooth  =   2,
    MPPrinterTypeTCP        =   3,
}MPPrinterType;

@interface MPPrinter : NSObject

/*!
 @brief IP / Bluetooth address of the printer.
 @discussion The manager will detect which printer it is and print with the appropriate sdk.
*/
@property (strong, nonatomic) NSString *address;

/*!
 @brief Name of the printer.
*/
@property (strong, nonatomic) NSString *name;

/*!
 @brief Check if the printer is online.
*/
- (void)checkOnline:(void(^)(BOOL online))completion;

/*!
 @brief Get printer type.
*/
- (MPPrinterType)printerType;

@end
