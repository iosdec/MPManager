
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
 
#### AirPrint:<br>
Apple's AirPrint capabilities wasn't enough. One of the main reasons I created this class is because there's no methods or documentation for printing out to multiple AirPrint printers at the same time.

What the delegate method for UIPrintInteractionController is "SUPPOSED" to do, is inform you when a job is printed, so that then you can fire out another job. MPManager takes care of that.

<b>NOTE</b>: <i>If you only require AirPrint capabilities, then you'll have to manually go through the code and remove code for the other printer models.</i>

#### Requirements:

 - Epson ePOS SDK for iOS
