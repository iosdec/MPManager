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
    int currentIndex;       //  current item to print.
    BOOL printingStack;     //  whether we're printing stack.
    
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
    
    //  in this method.. we need to make sure that each job is completed
    //  before starting another one.
    //  so once we've called "printJob".. we then need to pull the
    //  next job and print that..
    
    if (self->jobs.count == 0) {
        if (completion) { completion(); } return;
    }
    
    //  update values:
    self->printingStack     =   YES;
    self->currentIndex      =   0;
    [self setPrintAllCompletion:completion];
    
    //  get the first item in the stack:
    MPManagerJob *job       =   [self->jobs objectAtIndex:0];
    
    //  now print the item.. the printJob method
    //  will automaticall check the index
    //  of the next object.. because we have printintStack set to YES.
    [self printJob:job completion:nil];
    
}

#pragma mark    -   Print:

- (void)updateInteractionControllerWithJob:(MPManagerJob *)job controller:(UIPrintInteractionController *)controller {
    
    if (!job.printer) {
        return;
    }
    
    if (!job.printer.address) {
        return;
    }
    
    if (job.printer.address.length == 0) {
        return;
    }
    
    if (!job.content) {
        return;
    }
    
    UIPrintInfo *info       =   [UIPrintInfo printInfo];
    info.outputType         =   UIPrintInfoOutputGrayscale;
    info.duplex             =   UIPrintInfoDuplexNone;
    info.orientation        =   UIPrintInfoOrientationPortrait;
    info.jobName            =   @"Airprint Job";
    
    UIPrintInteractionController *printController   =   [UIPrintInteractionController sharedPrintController];
    printController.printInfo                       =   info;
    printController.delegate                        =   self;
    printController.printingItem                    =   nil;
    printController.printingItems                   =   nil;
    printController.printPageRenderer               =   nil;
    
    //  check if the job content is a valid print item:
    if (job.content.image) {
        printController.printingItem = job.content.image;
    }
    if (job.content.url) {
        printController.printingItem = [NSData dataWithContentsOfURL:job.content.url];
    }
    
    //  now check if we're printing a string:
    if (job.content.string || job.content.mutableString || job.content.htmlString) {
        
        printController.printingItem                =   nil;
        
        //  create a renderer:
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
    
}

- (void)printJob:(MPManagerJob *)job completion:(void(^)(BOOL printed, NSString *error))completion {
    
    //  check for requirements:
    
    if (!job.printer) {
        if (completion) {
            completion(NO, @"Invalid printer");
        } return;
    }
    
    if (!job.printer.address) {
        if (completion) {
            completion(NO, @"Invalid printer address");
        } return;
    }
    
    if (job.printer.address.length == 0) {
        if (completion) {
            completion(NO, @"Invalid printer address");
        } return;
    }
    
    if (!job.content) {
        if (completion) {
            completion(NO, @"Invalid printer content");
        } return;
    }
    
    //  AIRPRINT.
    if (job.printer.printerType == MPPrinterTypeAirprint) {
        
        UIPrinter *printer      =   [UIPrinter printerWithURL:[NSURL URLWithString:job.printer.address]];
        UIPrintInfo *info       =   [UIPrintInfo printInfo];
        info.outputType         =   UIPrintInfoOutputGrayscale;
        info.duplex             =   UIPrintInfoDuplexNone;
        info.orientation        =   UIPrintInfoOrientationPortrait;
        info.jobName            =   @"Airprint Job";
        
        UIPrintInteractionController *printController   =   [UIPrintInteractionController sharedPrintController];
        printController.printInfo                       =   info;
        printController.delegate                        =   self;
        printController.printingItem                    =   nil;
        printController.printingItems                   =   nil;
        printController.printPageRenderer               =   nil;
        
        //  check if the job content is a valid print item:
        if (job.content.image) {
            printController.printingItem = job.content.image;
        }
        if (job.content.url) {
            printController.printingItem = [NSData dataWithContentsOfURL:job.content.url];
        }
        
        //  now check if we're printing a string:
        if (job.content.string || job.content.mutableString || job.content.htmlString) {
            
            printController.printingItem                =   nil;
            
            //  create a renderer:
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
        
        //  print it:
        [printController printToPrinter:printer completionHandler:^(UIPrintInteractionController * _Nonnull printInteractionController, BOOL completed, NSError * _Nullable error) {
            
            //  FIX.
            //  Here is where we need to check for the next job.
            //  without calling printToPrinter again.
            //  So first.. we need to check if the user
            //  is printing from printStack.
            
            if (self->printingStack) {
                
                //  so let's check our index stuff:
                if (self->jobs.count == 0) {
                    if (self.printAllCompletion) {
                        self.printAllCompletion();
                    } return;
                }
                
                //  now check the index range:
                if ((self->currentIndex + 1) > (self->jobs.count - 1)) {
                    if (self.printAllCompletion) {
                        self.printAllCompletion();
                    } return;
                }
                
                //  let's get the next job:
                self->currentIndex  =   self->currentIndex + 1;
                MPManagerJob *job   =   [self->jobs objectAtIndex:self->currentIndex];
                
                //  first.. let's check if the alert
                //  is still visible:
                if ([self isPrintingAlertActive]) {
                    [self performSelector:@selector(reattemptPrint:) withObject:job afterDelay:2.0];
                    return;
                }
                
                //  now.. print the next job:
                [self printJob:job completion:nil];
                return;
                
            }
            
            if (error) {
                NSLog(@"printInteractionController failed with error: %@", error);
            }
            
            if (completion) {
                completion(completed, error.localizedDescription);
            }
            
        }];
        
    }
    
    //  BLUETOOTH:
    if (job.printer.printerType == MPPrinterTypeBluetooth) {
        
        //  in the future we'll add more support for different printers.
        //  for now.. we're focusing on EPOS.
        //  for this, we need to have mutable content set.
        
        if (!job.content.mutableString) {
            if (completion) {
                completion(NO, @"EPOS Mutable content needs to be set");
            } return;
        }
        
        //  now, create an epos2printer.
        Epos2Printer *epos2printer  =   [self eposPrinterWithAddress:job.printer.address];
        if (!epos2printer) {
            if (completion) {
                completion(NO, @"EPOS Printer is offline");
            } return;
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
        
        //  add feed line:
        [epos2printer addFeedLine:1];
        
        //  add content:
        [epos2printer addText:job.content.mutableString];
        
        //  add feed line before cut:
        [epos2printer addFeedLine:1];
        
        //  cut the feed:
        [epos2printer addCut:EPOS2_CUT_FEED];
        
        //  get status of printer:
        Epos2PrinterStatusInfo *info        =   [epos2printer getStatus];
        NSString *infoError                 =   [self makeErrorMessage:info];
        
        if (![self isPrintable:info]) {
            if (completion) {
                completion(NO, @"Printer not available");
            } return;
        }
        
        if (infoError.length != 0) {
            if (completion) {
                completion(NO, infoError);
            } return;
        }
        
        int print_result                    =   [epos2printer sendData:EPOS2_PARAM_DEFAULT];
        
        if (print_result == 0) {
            if (completion) { completion(YES, nil); }
        } else {
            if (completion) { completion(NO, @"Failed to print"); }
        }
        
        [epos2printer clearCommandBuffer];
        [epos2printer endTransaction];
        
    }
    
}

- (void)reattemptPrint:(MPManagerJob *)job {
    
    //  this method will attempt to call the print method again:
    //  it's another hacky/quick method seeing as we can't call
    //  performSelector with multiple objects.
    [self printJob:job completion:nil];
    
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
    
    NSMutableString *errMsg = [[NSMutableString alloc] initWithString:@""];
    
    if (status.getOnline == EPOS2_FALSE) {
        [errMsg appendString:NSLocalizedString(@"err_offline", @"")];
    }
    if (status.getConnection == EPOS2_FALSE) {
        [errMsg appendString:NSLocalizedString(@"err_no_response", @"")];
    }
    if (status.getCoverOpen == EPOS2_TRUE) {
        [errMsg appendString:NSLocalizedString(@"err_cover_open", @"")];
    }
    if (status.getPaper == EPOS2_PAPER_EMPTY) {
        [errMsg appendString:NSLocalizedString(@"err_receipt_end", @"")];
    }
    if (status.getPaperFeed == EPOS2_TRUE || status.getPanelSwitch == EPOS2_SWITCH_ON) {
        [errMsg appendString:NSLocalizedString(@"err_paper_feed", @"")];
    }
    if (status.getErrorStatus == EPOS2_MECHANICAL_ERR || status.getErrorStatus == EPOS2_AUTOCUTTER_ERR) {
        [errMsg appendString:NSLocalizedString(@"err_autocutter", @"")];
        [errMsg appendString:NSLocalizedString(@"err_need_recover", @"")];
    }
    if (status.getErrorStatus == EPOS2_UNRECOVER_ERR) {
        [errMsg appendString:NSLocalizedString(@"err_unrecover", @"")];
    }
    
    if (status.getErrorStatus == EPOS2_AUTORECOVER_ERR) {
        if (status.getAutoRecoverError == EPOS2_HEAD_OVERHEAT) {
            [errMsg appendString:NSLocalizedString(@"err_overheat", @"")];
            [errMsg appendString:NSLocalizedString(@"err_head", @"")];
        }
        if (status.getAutoRecoverError == EPOS2_MOTOR_OVERHEAT) {
            [errMsg appendString:NSLocalizedString(@"err_overheat", @"")];
            [errMsg appendString:NSLocalizedString(@"err_motor", @"")];
        }
        if (status.getAutoRecoverError == EPOS2_BATTERY_OVERHEAT) {
            [errMsg appendString:NSLocalizedString(@"err_overheat", @"")];
            [errMsg appendString:NSLocalizedString(@"err_battery", @"")];
        }
        if (status.getAutoRecoverError == EPOS2_WRONG_PAPER) {
            [errMsg appendString:NSLocalizedString(@"err_wrong_paper", @"")];
        }
    }
    
    if (status.getBatteryLevel == EPOS2_BATTERY_LEVEL_0) {
        [errMsg appendString:NSLocalizedString(@"err_battery_real_end", @"")];
    }
    
    return errMsg;
    
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
    return self->jobs;
}

@end
