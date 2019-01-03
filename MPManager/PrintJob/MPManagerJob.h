//
//  MPManagerJob.h
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPPrinter.h"
#import "MPContent.h"

/*!
 @brief Manager job for manager.
*/
@interface MPManagerJob : NSObject

- (id)init;

/*!
 @brief Printer associated for the job.
*/
@property (strong, nonatomic) MPPrinter *printer;

/*!
 @brief Content to print.
*/
@property (strong, nonatomic) MPContent *content;

/*!
 @brief Set to YES when manager has processed job.
*/
@property (nonatomic, assign) BOOL processed;

/*!
 @brief Printed status.
*/
@property (nonatomic, assign) BOOL printed;

/*!
 @brief Error after printed.
*/
@property (strong, nonatomic) NSString *error;

@end
