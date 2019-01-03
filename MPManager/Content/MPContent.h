//
//  MPContent.h
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Content to be printed.
*/
@interface MPContent : NSObject

/*!
 @brief Standard string to print.
*/
@property (strong, nonatomic) NSString *string;

/*!
 @brief Mutable string to print.
*/
@property (strong, nonatomic) NSMutableString *mutableString;

/*!
 @brief HTML string to print.
*/
@property (strong, nonatomic) NSString *htmlString;

/*!
 @brief Image to print.
*/
@property (strong, nonatomic) UIImage *image;

/*!
 @brief View to print.
*/
@property (strong, nonatomic) UIView *view;

/*!
 @brief URL to print.
*/
@property (strong, nonatomic) NSURL *url;

@end
