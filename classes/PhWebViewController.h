//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@class PhFacebook;

@interface PhWebViewController : NSViewController {
@private
    WebView *webView;
    NSButton *cancelButton;

    PhFacebook *parent;
    NSString *permissions;
	id _popoverController;
}

@property (assign) PhFacebook *parent;
@property (nonatomic, retain) NSString *permissions;

@property (retain) IBOutlet NSButton *cancelButton;
@property (retain) IBOutlet WebView *webView;
@property (retain) id popoverController;

- (IBAction) cancel: (id) sender;

@end
