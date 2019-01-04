//
//  MPManager.m
//  iOSDec
//
//  Created by Declan Land
//  Copyright Declan Land. All rights reserved.
//

#import "MPManager.h"
#import "ePOS2.h"

@interface MPManager() <UIPrintInteractionControllerDelegate, Epos2ScanDelegate, Epos2DiscoveryDelegate, Epos2ConnectionDelegate, Epos2PtrReceiveDelegate> {
    
    NSMutableArray *jobs;   //  jobs left to print.
    
}
@end

@implementation MPManager

+ (id)sharedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
        [_sharedObject initManager];
    }); return _sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initManager];
    } return self;
}

#pragma mark    -   Initialise:

- (void)initManager {
    if (!self->jobs) {
        self->jobs = [[NSMutableArray alloc] init];
    }
}

- (void)clearJobs {
    self->jobs = [[NSMutableArray alloc] init];
}

#pragma mark    -   Add:

- (void)addJob:(MPManagerJob *)job {
    
    if (!job) { return; }
    if (!job.printer) { return; }
    if (!job.content) { return; }
    
    if (!self->jobs) {
        self->jobs = [[NSMutableArray alloc] init];
    }
    
    [self->jobs addObject:job];
    
}

#pragma mark    -   Print All Jobs:

- (void)printAllJobs:(void (^)(void))completion {
    
    //  first, check for the delegate method:
    if (completion) {
        [self setPrintAllCompletion:completion];
    }
    
    //  check if we have valid jobs:
    if (!self->jobs) {
        if (completion) { completion(); return; }
    }
    if (self->jobs.count == 0) {
        if (completion) { completion(); return; }
    }
    
    //  instead of running through a loop (because that would
    //  defeat the point of waiting for the alert to be dimsissed)..
    //  we need to start the next job ONLY after the active job
    //  is finished. To do this.. we need a repeater function that
    //  checks for a next job in the queue until all jobs are done.
    //  And because we've got a completion as a property, we can
    //  check for that in the check method and call if needed.
    //  So first.. let's attempt to print the first job:
    
    MPManagerJob *primary   =   [self primaryJob];
    
    [self printJob:primary completion:^(BOOL printed, NSString *error) {
        
        //  update job information:
        [primary setProcessed:YES];
        [primary setPrinted:printed];
        [primary setError:error];
        
        //  now check for the next job:
        [self checkForNextJobWithPrevious:primary];
        
    }];
    
}

- (void)checkForNextJobWithPrevious:(MPManagerJob *)job {
    
    //  this method gets called after a job has finished
    //  processing. so what we want to do here, is check
    //  if there's a job after this in the stack; if there
    //  isn't.. then we'll call the completion method if
    //  it exists.. because we've completed all jobs:
    
    if (!self.jobs) {
        if (self.printAllCompletion) { self.printAllCompletion(); } return;
    }
    if (self.jobs.count == 0) {
        if (self.printAllCompletion) { self.printAllCompletion(); } return;
    }
    
    NSUInteger previous_index   =   [self.jobs indexOfObject:job];
    
    if (previous_index + 1 > (self->jobs.count - 1)) {
        
        //  this must mean that we've reached the end
        //  of the stack.
        if (self.printAllCompletion) {
            self.printAllCompletion();
        } return;
        
    }
    
    //  now find the next job:
    MPManagerJob *next_job      =   [self.jobs objectAtIndex:previous_index + 1];
    
    //  and print it:
    [self printJob:next_job completion:^(BOOL printed, NSString *error) {
        
        //  update job info:
        [next_job setProcessed:YES];
        [next_job setPrinted:printed];
        [next_job setError:error];
        
        //  now check for the next one:
        [self checkForNextJobWithPrevious:next_job];
        
    }];
    
}

#pragma mark    -   Print Job:

- (void)printJob:(MPManagerJob *)job completion:(void (^)(BOOL, NSString *))completion {
    
    //  first, let's check if we have a job:
    if (!job) {
        if (completion) { completion(NO, @"Missing job"); return; }
    }
    
    //  now.. check if printer is missing:
    if (!job.printer) {
        if (completion) { completion(NO, @"Missing printer"); return; }
    }
    
    //  check if printer is valid:
    if (!job.printer.isValidPrinter) {
        if (completion) { completion(NO, @"Printer is invalid"); return; }
    }
    
    //  check missing content:
    if (!job.content) {
        if (completion) { completion(NO, @"Content is missing"); return; }
    }
    
    //  check content valid:
    if (!job.content.hasValidContent) {
        if (completion) { completion(NO, @"Content is invalid"); return; }
    }
    
    //  -------------------------------------------------------------------
    
    //  AIRPRINT.
    if (job.printer.printerType == MPPrinterTypeAirprint) {
        
        UIPrinter *printer                              =   [UIPrinter printerWithURL:[NSURL URLWithString:job.printer.address]];
        UIPrintInfo *info                               =   [UIPrintInfo printInfo];
        info.outputType                                 =   UIPrintInfoOutputGrayscale;
        info.duplex                                     =   UIPrintInfoDuplexNone;
        info.orientation                                =   UIPrintInfoOrientationPortrait;
        info.jobName                                    =   @"Airprint - Superb | iOS";
        
        UIPrintInteractionController *printController   =   [UIPrintInteractionController sharedPrintController];
        printController.printInfo                       =   info;
        printController.delegate                        =   self;
        printController.printingItem                    =   nil;
        printController.printingItems                   =   nil;
        printController.printPageRenderer               =   nil;
        
        if (job.content.image) {
            printController.printingItem = job.content.image;
        }
        if (job.content.url) {
            printController.printingItem = [NSData dataWithContentsOfURL:job.content.url];
        }
        
        if (job.content.string || job.content.mutableString || job.content.htmlString) {
            
            printController.printingItem                =   nil;
            
            if (job.content.string) {
                UISimpleTextPrintFormatter *formatter   =   [self textFormatterWithString:job.content.string];
                printController.printFormatter          =   formatter;
            }
            if (job.content.mutableString) {
                UISimpleTextPrintFormatter *formatter   =   [self textFormatterWithString:job.content.mutableString];
                printController.printFormatter          =   formatter;
            }
            if (job.content.htmlString) {
                UIMarkupTextPrintFormatter *formatter   =   [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:job.content.htmlString];
                printController.printFormatter          =   formatter;
            }
            
        }
        
        //  now let's print:
        [printController printToPrinter:printer completionHandler:^(UIPrintInteractionController * _Nonnull printInteractionController, BOOL completed, NSError * _Nullable error) {
            
            //  previously.. we had a function in here that would
            //  check for the next job in the cycle.. that's been removed
            //  due to being able to print in singular.
            //  all cycle methods should be called from a super function.
            //  instead.. what we will do, is call the completion method when
            //  the alert is off the screen.
            
            [self handleAirPrintCompletion:completion];
            return;
            
        }];
        
    }
    
    //  BLUETOOTH.
    if (job.printer.printerType == MPPrinterTypeBluetooth) {
        
        if (!job.content.mutableString) {
            if (completion) { completion(NO, @"EPOS Mutable content needs to be set"); } return;
        }
        
        //  now, create an epos2printer.
        Epos2Printer *epos2printer  =   [self eposPrinterWithAddress:job.printer.address];
        
        if (!epos2printer) {
            if (completion) { completion(NO, @"EPOS Printer is offline"); } return;
        }
        
        //  prepare printer:
        [epos2printer clearCommandBuffer];
        [epos2printer beginTransaction];
        [epos2printer setReceiveEventDelegate:self];
        
        //  align center:
        [epos2printer addTextAlign:EPOS2_ALIGN_CENTER];
        
        //  check for image in content:
        if (job.content.image) {
            [epos2printer addImage:job.content.image x:0 y:0
                             width:job.content.image.size.width
                            height:job.content.image.size.height
                             color:EPOS2_COLOR_1
                              mode:EPOS2_MODE_MONO
                          halftone:EPOS2_HALFTONE_DITHER
                        brightness:EPOS2_PARAM_DEFAULT
                          compress:EPOS2_COMPRESS_AUTO];
        }
        
        //  add printing content / options:
        [epos2printer addFeedLine:1];
        [epos2printer addText:job.content.mutableString];
        [epos2printer addFeedLine:1];
        [epos2printer addCut:EPOS2_CUT_FEED];
        
        //  check online status:
        Epos2PrinterStatusInfo *info        =   [epos2printer getStatus];
        NSString *infoError                 =   [self makeErrorMessage:info];
        
        if (![self isPrintable:info]) {
            if (infoError && infoError.length != 0) {
                if (completion) { completion(NO, infoError); } return;
            } else {
                if (completion) { completion(NO, @"Printer not available"); } return;
            }
        }
        
        if (infoError.length != 0) {
            if (completion) { completion(NO, infoError); } return;
        }
        
        int print_result                    =   [epos2printer sendData:EPOS2_PARAM_DEFAULT];
        
        //  before calling any completion methods,
        //  let's finish the job for the printer:
        [epos2printer clearCommandBuffer];
        [epos2printer endTransaction];
        
        //  check for a bad result:
        if (print_result != 0) {
            if (completion) { completion(NO, @"Failed to print"); return; }
        }
        
        //  if we got to here.. the job was successful.
        //  so lets call the completion method:
        if (completion) {
            completion(YES, nil);
        }
        
    }
    
}

#pragma mark    -   Alert Checker:

- (void)handleAirPrintCompletion:(void(^)(BOOL printed, NSString *error))completion {
    
    //  the purpose of this method, is to keep checking if an alert
    //  is visible on screen, if so.. then repeat the method.. if not
    //  then the job is ACTUALLY completed.
    
    if ([self isPrintingAlertActive]) {
        [self performSelector:@selector(handleAirPrintCompletion:) withObject:completion afterDelay:1]; return;
    }
    
    //  if we got to here.. that means the alert has dissapeared,
    //  and we can call the completion method:
    
    if (completion) {
        completion(YES, nil);
    }
    
}

#pragma mark    -   Checkers and getters:

- (BOOL)hasPrimaryJob {
    if (!self->jobs) { return NO; }
    if (self->jobs.count == 0) { return NO; }
    return YES;
}

- (MPManagerJob *)primaryJob {
    if (![self hasPrimaryJob]) {
        return nil;
    } else {
        return [self->jobs firstObject];
    }
}

#pragma mark    -   Hacky Delegate:

- (BOOL)isPrintingAlertActive {
    UIViewController *controller    =   [self highestController];
    if ([controller isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert    =   (UIAlertController *)controller;
        if ([alert.title containsString:@"Printing"]) {
            return YES;
        }
        if ([alert.title containsString:@"Connecting"]) {
            return YES;
        }
        if ([alert.title containsString:@"Printed"]) {
            return YES;
        }
    } return NO;
}

- (UIViewController *)highestController {
    UIViewController *rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootController.presentedViewController) {
        rootController = rootController.presentedViewController;
    } return rootController;
}

#pragma mark    -   Airprint Delegate:

- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
    
    NSLog(@"Print interaction controller did finish job | printing item: %@", printInteractionController.printingItem);
    
}

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
    
    NSLog(@"Print interaction controller will start job | printing item: %@", printInteractionController.printingItem);
    
}

- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController {
    
    NSLog(@"Print interaction controller did present printer options");
    
}

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController {
    
    NSLog(@"Print interaction controller will present printer options");
    
}


#pragma mark    -   UIPrinter Formatter:

- (UISimpleTextPrintFormatter *)textFormatterWithString:(NSString *)string {
    UISimpleTextPrintFormatter *formatter = [[UISimpleTextPrintFormatter alloc] initWithText:string];
    formatter.perPageContentInsets = UIEdgeInsetsZero;
    formatter.startPage = 0;
    return formatter;
}

#pragma mark    -   EPOS2 Printer Instance:

- (Epos2Printer *)eposPrinterWithAddress:(NSString *)ipAddress {
    
    if (!ipAddress) { return nil; }
    
    Epos2Printer *tmpPrinter            =   [[Epos2Printer alloc] initWithPrinterSeries:0 lang:0];
    Epos2PrinterStatusInfo *info        =   [[Epos2PrinterStatusInfo alloc] init];
    info                                =   [tmpPrinter getStatus];
    int result                          =   [tmpPrinter connect:ipAddress timeout:EPOS2_PARAM_DEFAULT];
    
    if (result == EPOS2_SUCCESS) {
        return tmpPrinter;
    }
    
    if (result == EPOS2_ERR_CONNECT) {
        return tmpPrinter;
    }
    
    return nil;
    
}

#pragma mark    -   EPOS Delegate:

- (void)onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId {
    [printerObj addPulse:EPOS2_DRAWER_5PIN time:EPOS2_PULSE_100];
    [printerObj clearCommandBuffer];
    [printerObj setReceiveEventDelegate:nil];
    [printerObj endTransaction];
}

- (void)onScanData:(Epos2BarcodeScanner *)scannerObj scanData:(NSString *)scanData {
    
}

- (void)onDiscovery:(Epos2DeviceInfo *)deviceInfo {
    
}

- (void)onConnection:(id)deviceObj eventType:(int)eventType {
    
}

#pragma mark    -   Make Error for EPOS:

- (NSString *)makeErrorMessage:(Epos2PrinterStatusInfo *)status {
    
    if (status.getOnline == EPOS2_FALSE) {
        return @"Printer is offline";
    }
    if (status.getConnection == EPOS2_FALSE) {
        return @"No response";
    }
    if (status.getCoverOpen == EPOS2_TRUE) {
        return @"Cover is open";
    }
    if (status.getPaper == EPOS2_PAPER_EMPTY) {
        return @"No paper";
    }
    if (status.getPaperFeed == EPOS2_TRUE || status.getPanelSwitch == EPOS2_SWITCH_ON) {
        return @"Error.. Paper feed";
    }
    if (status.getErrorStatus == EPOS2_MECHANICAL_ERR || status.getErrorStatus == EPOS2_AUTOCUTTER_ERR) {
        return @"Cutter / Mechanical error";
    }
    if (status.getErrorStatus == EPOS2_UNRECOVER_ERR) {
        return @"Unrecover";
    }
    
    if (status.getErrorStatus == EPOS2_AUTORECOVER_ERR) {
        if (status.getAutoRecoverError == EPOS2_HEAD_OVERHEAT) {
            return @"Head / Overheat";
        }
        if (status.getAutoRecoverError == EPOS2_MOTOR_OVERHEAT) {
            return @"Motor / Overheat";
        }
        if (status.getAutoRecoverError == EPOS2_BATTERY_OVERHEAT) {
            return @"Battery / Overheat";
        }
        if (status.getAutoRecoverError == EPOS2_WRONG_PAPER) {
            return @"Wrong paper";
        }
    }
    
    if (status.getBatteryLevel == EPOS2_BATTERY_LEVEL_0) {
        return @"Battery empty";
    }
    
    return @"";
    
}

- (BOOL)isPrintable:(Epos2PrinterStatusInfo *)status {
    if (status == nil) {
        return NO;
    }
    if (status.connection == EPOS2_FALSE) {
        return NO;
    }
    else if (status.online == EPOS2_FALSE) {
        return NO;
    }
    else {
    } return YES;
}

#pragma mark    -   Getters:

- (NSArray *)jobs {
    if (!self->jobs) { return [NSArray array]; }
    if (self->jobs.count == 0) { return [NSArray array]; }
    return self->jobs;
}

@end
