
![MPManager Logo](Images/mpmanager.png)

#### Master Print Manager - Objective C.

Easily print to multiple types of printers.

</br>
<b>Currently supports</b>:

 - AirPrint
 - Epson
    -   TM-Series

<b>Future Support</b>:

 - STAR
 - EOM
 - Citizen
 - Smart&Cool
 
### Features:

 - Easily add "Print Jobs" and fire them whenever you need
 - Supports printing out to multiple AirPrint printers
 - Delegate methods
 - Best solution for using multiple types of printers
 
</br>
#### AirPrint.. Why?<br>
Apple's AirPrint capabilities wasn't enough. One of the main reasons I created this class is because there's no methods or documentation for printing out to multiple AirPrint printers at the same time. Even if you don't decide to use this class, the below explanation should help you out.

If you're attempting to print jobs with UIPrintInteractionController, your code will probably look something like this:

```objc
NSString *printerAddress                    =   @"ipps://myprinter:.863/printers/label";
NSURL *printerURL                           =   [NSURL URLWithString:printerAddress];
UIPrinter *printer                          =   [[UIPrinter alloc] initWithURL:printerURL];
UIPrintInteractionController *controller    =   [UIPrintInteractionController sharedPrintController];

[controller printToPrinter:printer completionHandler:^(UIPrintInteractionController * _Nonnull printInteractionController, BOOL completed, NSError * _Nullable error) {
    
    //      now that you've reached this method, let's say that
    //      you want to print another job straight after...
    //      here is the problem! the AirPrint framework doesn't
    //      allow this, because it requires the printing alert
    //      to be off the screen before starting the next job..
    //      and.. that AirPrint requires there to be an alert
    //      visible while actually printing a job to show progress.
    
}];
```

<b>NOTE</b>: <i>If you only require AirPrint capabilities, then you'll have to manually go through the code and remove code for the other printer models.</i>

</br>
#### Requirements:

 - Epson ePOS SDK for iOS
 
</br>
#### Imports:

Drag the MPManager folder into your project, then import this file where needed:
```objc
#import "MPManager.h"
```

</br>
#### Usage:

This class system is pretty straight forward.. that was the whole idea behind it.


The pattern is as follows:

 - Create MPContent
    -   Add content (image/text/url/etc)
 - Create MPPrinter
    -   Add printer information (address/name/etc)
 - Create MPManagerJob
    -   Set content (MPContent)
    -   Set printer (MPPrinter)
 - Print MPManagerJob

</br>
##### Print Single Job:

```objc
- (void)printJob {
    
    MPContent *content          =   [[MPContent alloc] init];
    [content setString:@"Print a string"];
    [content setImage:[UIImage imageNamed:@"imagename.png"]];
    
    MPPrinter *printer          =   [[MPPrinter alloc] init];
    [printer setName:@"Printers name"];
    [printer setAddress:@"ipss://myserver.:863/printers/label"];
    
    MPManagerJob *job           =   [[MPManagerJob alloc] init];
    [job setContent:content];
    [job setPrinter:printer];
    
    [[MPManager sharedManager] printJob:job completion:^(BOOL printed, NSString *error) {
        
        //  check print status and error here.
        
    }];
    
}
```

##### Print multiple Jobs:

```objc
- (void)printMultipleJobs {
    
    MPContent *content          =   [[MPContent alloc] init];
    [content setString:@"Print a string"];
    [content setImage:[UIImage imageNamed:@"imagename.png"]];
    
    MPPrinter *firstPrinter     =   [[MPPrinter alloc] init];
    [firstPrinter setAddress:@"ipps://myserver.:863/printers/airprint1"];
    
    MPPrinter *secondPrinter    =   [[MPPrinter alloc] init];
    [secondPrinter setAddress:@"ipps://myserver.:863/printers/airprint2"];
    
    MPPrinter *thirdPrinter     =   [[MPPrinter alloc] init];
    [thirdPrinter setAddress:@"BT:00:11:22:33:44:55"];
    
    MPManagerJob *job1          =   [[MPManagerJob alloc] init];
    [job setContent:content];
    [job setPrinter:firstPrinter];
    
    MPManagerJob *job2          =   [[MPManagerJob alloc] init];
    [job2 setContent:content];
    [job2 setPrinter:secondPrinter];
    
    MPManagerJob *job3          =   [[MPManagerJob alloc] init];
    [job3 setContent:content];
    [job3 setPrinter:thirdPrinter];
    
    MPManager *manager          =   [[MPManager alloc] init];
    [manager addJob:job1];
    [manager addJob:job2];
    [manager addJob:job3];
    
    [manager printAllJobs:^{
        
        //  all jobs printed.
        //  all jobs have been process too..
        //  check manager.jobs -> job.printed/job.error
        
    }];
    
}
```

