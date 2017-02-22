/********* CkOpenImage.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CkOpenImage : CDVPlugin <UIDocumentInteractionControllerDelegate> {
  // Member variables go here.
}

@property (nonatomic, strong) UIDocumentInteractionController* docInteractionController;
@property (nonatomic, strong) NSMutableArray* documentURLs;

@property (nonatomic,strong) CDVPluginResult* pluginResult;
@property (nonatomic,strong) NSString* tmpCommandCallbackID;


- (void)open:(CDVInvokedUrlCommand*)command;
- (void)isAvailable:(CDVInvokedUrlCommand*)command;

@end

@implementation CkOpenImage
{
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- isAvailable

- (void)isAvailable:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES] callbackId:command.callbackId];
    }];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- setupDocumentControllerWithURL

- (void)setupDocumentControllerWithURL:(NSURL*)url andTitle:(NSString*)title
{
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        [self.docInteractionController setDelegate:self];
    } else {
        [self.docInteractionController setURL:url];
    }

    [self.docInteractionController setName:title];

    [self.docInteractionController presentPreviewAnimated:YES];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- setupDocumentControllerWithURL:usingDelegate

- (UIDocumentInteractionController *) setupDocumentControllerWithURL: (NSURL*) fileURL usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate
{
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;

    return interactionController;
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- documentInteractionControllerViewControllerForPreview

- (UIViewController*) documentInteractionControllerViewControllerForPreview:(__unused UIDocumentInteractionController*) controller
{
    return self.viewController;
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- documentInteractionControllerDidEndPreview

- (void)documentInteractionControllerDidEndPreview:(__unused UIDocumentInteractionController*)controller
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"[CkOpenImage] Closed"] callbackId:self.tmpCommandCallbackID];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- open

- (void)open:(CDVInvokedUrlCommand*)command
{
    // ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- add Spinner

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:self.viewController.view.frame];

    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator.layer setBackgroundColor:[[UIColor colorWithWhite:0.0 alpha:0.30] CGColor]];

    CGPoint center = self.viewController.view.center;

    activityIndicator.center = center;

    [self.viewController.view addSubview:activityIndicator];

    [activityIndicator startAnimating];

    // ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---

    self.tmpCommandCallbackID = command.callbackId;
    self.pluginResult = nil;

    NSString* url = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];

    [self.commandDelegate runInBackground:^{
        if (url != nil && [url length] > 0)
        {
            @try
            {
                self.documentURLs = [NSMutableArray array];

                NSURL* URL = [self localFileURLForImage:url];

                if (URL)
                {
                    [self.documentURLs addObject:URL];

                    double delayInSeconds = 0.1;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [activityIndicator stopAnimating];

                        [self setupDocumentControllerWithURL:URL andTitle:title];
                    });
                }
                else
                {
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Bad file path."] callbackId:command.callbackId];
                }
            }
            @catch (NSException* e)
            {
                NSLog(@"[CkOpenImage] Exception(open): %@", e);
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason] callbackId:command.callbackId];
            }
        }
        else
        {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"URL was not defined."] callbackId:command.callbackId];
        }
    }];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- localFileURLForImage

- (NSURL*)localFileURLForImage:(NSString*)image
{
    NSString* imagePath = [image stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    // save this image to a temp folder
    NSURL* tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSString* filename = [[NSUUID UUID] UUIDString];
    NSURL* fileURL = [NSURL URLWithString:imagePath];

    @try
    {
        NSNumber* fileSizeValue = nil;
        [fileURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:nil];
    }
    @catch (NSException* e)
    {
        NSLog(@"[CkOpenImage] Exception (fileSizeValue): %@", e);
        return nil;
    }

    if ([fileURL isFileReferenceURL])
    {
        return fileURL;
    }

    NSData* data = [NSData dataWithContentsOfURL:fileURL];

    if( data && [data length] > 0 )
    {
        @try
        {
            fileURL = [[tmpDirURL URLByAppendingPathComponent:filename] URLByAppendingPathExtension:[self contentTypeForImageData:data]];

            [[NSFileManager defaultManager] createFileAtPath:[fileURL path] contents:data attributes:nil];

            return fileURL;
        }
        @catch (NSException* e)
        {
            NSLog(@"Exception (localFileURLForImage): %@", e);
        }

        return nil;
    }
    else
    {
        NSLog(@"[CkOpenImage] Error: Data not exist!");
        return nil;
    }
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- contentTypeForImageData

- (NSString*)contentTypeForImageData:(NSData*)data
{
    uint8_t c;

    [data getBytes:&c length:1];

    switch (c) {
        case 0xFF:
             return @"jpeg";
        case 0x89:
             return @"png";
        case 0x47:
             return @"gif";
        case 0x49:
        case 0x4D:
             return @"tiff";
        default:
             return nil;
    }

    return nil;
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --

@end
