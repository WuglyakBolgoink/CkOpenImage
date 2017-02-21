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

// TODO: add in cordova exports
- (void) isAvailable:(CDVInvokedUrlCommand*)command {
    bool avail = NSClassFromString(@"CkOpenImage") != nil;
    NSLog(@"[CkOpenImage] Is plugin available? %i", avail);

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:avail] callbackId:command.callbackId];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- openDocumentControllerWithURL

- (void)openDocumentControllerWithURL:(NSURL*)url andTitle:(NSString*)title
{
    self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];

    [self.docInteractionController setName:title];
    [self.docInteractionController setDelegate:self];

    [self.docInteractionController presentPreviewAnimated:YES];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- documentInteractionControllerViewControllerForPreview

- (UIViewController*) documentInteractionControllerViewControllerForPreview:(__unused UIDocumentInteractionController*) controller
{
    return self.viewController;
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- documentInteractionControllerDidEndPreview

- (void)documentInteractionControllerDidEndPreview:(__unused UIDocumentInteractionController*)controller
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:@"[CkOpenImage] Closed"] callbackId:self.tmpCommandCallbackID];
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- show

-(void) dismissIfNeeded
{
    if (self.docInteractionController)
    {
        [self.docInteractionController dismissPreviewAnimated:YES];
        self.docInteractionController = nil;
    }
}

// ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- show

- (void)open:(CDVInvokedUrlCommand*)command
{
    self.tmpCommandCallbackID = command.callbackId;
    self.pluginResult = nil;

    NSString* url = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];

    [self dismissIfNeeded];

    [self.commandDelegate runInBackground:^{
        if (url != nil && [url length] > 0)
        {
            @try {
                self.documentURLs = [NSMutableArray array];

                NSURL* URL = [self localFileURLForImage:url];

                if (URL)
                {
                    [self.documentURLs addObject:URL];
                    [self openDocumentControllerWithURL:URL andTitle:title];
                } else {
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Bad file path."] callbackId:command.callbackId];
                }
            }
            @catch (NSException* e)
            {
                NSLog(@"Exception: %@", e);
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
        NSLog(@"[CkOpenImage] Exception (Can not get filesize): %@", e);
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
        @catch (NSException* e) {
            NSLog(@"Exception: %@", e);
        }

        return nil;
    } else {
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

