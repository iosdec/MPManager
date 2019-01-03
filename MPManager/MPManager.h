//
//  MPManager.h
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPManagerJob.h"
#import "ePOS2.h"

@class MPManager, MPManagerJob;

@protocol MPManagerDelegate <NSObject>

@optional
- (void)manager:(MPManager *)manager printedJob:(MPManagerJob *)job;
- (void)managerFinishedPrintingAllJobs:(MPManager *)manager;

@end

/*!
 @brief (M)aster(P)rint(Manager).
 @discussion This class handles everything related to printing.
*/

@interface MPManager : NSObject

/*!
 @brief Shared instance of MPManager.
*/
+ (id)sharedManager;

/*!
 @brief Instantiate MPManager.
*/
- (id)init;

//  this class needs to be kept as clean as possible.
//  no confusion. basic as fuck.
//  start with the below code.

/*!
 @brief Clear all jobs.
*/
- (void)clearJobs;

/*!
 @brief Add job to be printed.
*/
- (void)addJob:(MPManagerJob *)job;

/*!
 @brief Print all the jobs in the stack.
*/
- (void)printAllJobs:(void(^)(void))completion;

/*!
 @brief Print specific job.
*/
- (void)printJob:(MPManagerJob *)job completion:(void(^)(BOOL printed, NSString *error))completion;

/*!
 @brief Get jobs left to be printed.
 */
- (NSArray *)jobs;

/*!
 @brief Optional manager delegate.
*/
@property (nonatomic, weak) id <MPManagerDelegate> delegate;

/*!
 @brief Print all jobs typedef completion.
*/
typedef void (^printAllJobsCompletion) (void);

@property (nonatomic, copy) printAllJobsCompletion printAllCompletion;

@end
