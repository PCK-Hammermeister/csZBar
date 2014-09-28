#import "CsZBar.h"


#pragma mark - State

@interface CsZBar ()
@property bool scanInProgress;
@property NSString *scanCallbackId;
@property ZBarReaderViewController *scanReader;
@end


#pragma mark - Synthesize

@implementation CsZBar

@synthesize scanInProgress;
@synthesize scanCallbackId;
@synthesize scanReader;


#pragma mark - Cordova Plugin

- (void)pluginInitialize
{
    self.scanInProgress = NO;
}


#pragma mark - Plugin API

- (void)scan: (CDVInvokedUrlCommand*)command;
{
    if(self.scanInProgress) {
        [self.commandDelegate
         sendPluginResult: [CDVPluginResult
                            resultWithStatus: CDVCommandStatus_ERROR
                            messageAsString:@"A scan is already in progress."]
         callbackId: [command callbackId]];
    } else {
        self.scanInProgress = YES;
        self.scanCallbackId = [command callbackId];
//        self.scanReader = [ZBarReaderViewController new];
        self.scanReader = [ZBarReaderViewControllerWithoutInfoButton new];

        self.scanReader.readerDelegate = self;
        self.scanReader.supportedOrientationsMask = ZBarOrientationMaskAll;

        // Hack to hide the bottom bar's Info button... http://stackoverflow.com/a/16353530
        //UIView *infoButton = [[[[[self.scanReader.view.subviews objectAtIndex:1] subviews] objectAtIndex:0] subviews] objectAtIndex:3];
        //[infoButton setHidden:YES];

        [self.viewController presentModalViewController: self.scanReader animated: YES];
    }
}


#pragma mark - Helpers

- (void)sendScanResult: (CDVPluginResult*)result
{
    [self.commandDelegate sendPluginResult: result callbackId: self.scanCallbackId];
}


#pragma mark - ZBarReaderDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results) break; // get the first result

    [self.scanReader dismissModalViewControllerAnimated: YES];
    self.scanInProgress = NO;
    [self sendScanResult: [CDVPluginResult
                           resultWithStatus: CDVCommandStatus_OK
                           messageAsString: symbol.data]];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self.scanReader dismissModalViewControllerAnimated: YES];
    self.scanInProgress = NO;
    [self sendScanResult: [CDVPluginResult
                           resultWithStatus: CDVCommandStatus_ERROR
                           messageAsString: @"cancelled"]];
}

- (void) readerControllerDidFailToRead:(ZBarReaderController*)reader withRetry:(BOOL)retry
{
    [self.scanReader dismissModalViewControllerAnimated: YES];
    self.scanInProgress = NO;
    [self sendScanResult: [CDVPluginResult
                           resultWithStatus: CDVCommandStatus_ERROR
                           messageAsString: @"Failed"]];
}


@end


#pragma mark - ZBarReaderViewControllerWithoutInfoButton
@interface ZBarReaderViewControllerWithoutInfoButton : ZBarReaderViewController

@end

@implementation ZBarReaderViewControllerWithoutInfoButton


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Accessing the toolbar
    UIToolbar *toolbar = [[controls subviews] firstObject];
    
    // Only keeping the first two items of the toolbar, thus deleting the info button
    if ([toolbar isKindOfClass:UIToolbar.class]) {
        toolbar.items = @[ toolbar.items[0], toolbar.items[1] ];
    }
}

@end