//
//  PhWebViewController.m
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhWebViewController.h"
#import "PhFacebook_URLs.h"
#import "PhFacebook.h"
#import "INPopoverController.h"

#import "Debug.h"

#define ALWAYS_SHOW_UI

@implementation PhWebViewController

@synthesize webView;
@synthesize cancelButton;
@synthesize parent;
@synthesize permissions;

@synthesize popoverController = _popoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		NSBundle *bundle = [NSBundle bundleForClass: [PhFacebook class]];
		self.title = [bundle localizedStringForKey: @"FBAuthWindowTitle" value: @"" table: nil];
		self.cancelButton.title = [bundle localizedStringForKey: @"FBAuthWindowCancel" value: @"" table: nil];
		
		// NON Lion Use INPopover - Lion - default
		if (NSClassFromString(@"NSPopover")) {
			NSPopover *_popover = [[NSPopover alloc] init];
			// The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
			_popover.contentViewController = self;
			_popover.behavior = NSPopoverBehaviorTransient;
			self.popoverController = _popover;
			[_popover release];
			[self loadView];
		}
		else {
			INPopoverController *popoverController = [[INPopoverController alloc] initWithContentViewController:self];
			popoverController.closesWhenPopoverResignsKey = NO;
			popoverController.color = [NSColor colorWithCalibratedWhite:1.0 alpha:0.8];
			popoverController.borderColor = [NSColor blackColor];
			popoverController.borderWidth = 2.0;
			self.popoverController = popoverController;
			[popoverController release];
		}
	}
	
	return self;
}

#pragma mark Delegate
- (void) showUI {
    // Facebook needs user input, show the window
	if ([self.popoverController isKindOfClass:[INPopoverController class]]) {
		INPopoverController *popoverController = self.popoverController;
		if ([popoverController popoverIsVisible]) 
			return;
		NSRect buttonBounds = [self.parent.sender bounds];
		[popoverController showPopoverAtPoint:NSMakePoint(NSMidX(buttonBounds), NSMidY(buttonBounds)) inView:self.parent.sender preferredArrowDirection:INPopoverArrowDirectionUp anchorsToPositionView:YES];
		
	}
	else if (self.popoverController && [self.popoverController isKindOfClass:NSClassFromString(@"NSPopover")]) {
		[self.popoverController showRelativeToRect:[self.parent.sender bounds] ofView:self.parent.sender preferredEdge:NSMinYEdge];
	}
	// Notify parent that we're about to show UI
	[self.parent webViewWillShowUI];
}

- (NSString*) extractParameter: (NSString*) param fromURL: (NSString*) url
{
    NSString *res = nil;

    NSRange paramNameRange = [url rangeOfString: param options: NSCaseInsensitiveSearch];
    if (paramNameRange.location != NSNotFound)
    {
        // Search for '&' or end-of-string
        NSRange searchRange = NSMakeRange(paramNameRange.location + paramNameRange.length, [url length] - (paramNameRange.location + paramNameRange.length));
        NSRange ampRange = [url rangeOfString: @"&" options: NSCaseInsensitiveSearch range: searchRange];
        if (ampRange.location == NSNotFound)
            ampRange.location = [url length];
        res = [url substringWithRange: NSMakeRange(searchRange.location, ampRange.location - searchRange.location)];
    }

    return res;
}

#pragma mark - WebView Delegation
- (void) webView: (WebView*) sender didCommitLoadForFrame: (WebFrame*) frame;
{
    NSString *url = [sender mainFrameURL];
    DebugLog(@"didCommitLoadForFrame: {%@}", url);
	
    NSString *urlWithoutSchema = [url substringFromIndex: [@"http://" length]];
    if ([url hasPrefix: @"https://"])
        urlWithoutSchema = [url substringFromIndex: [@"https://" length]];
    
    NSString *uiServerURLWithoutSchema = [kFBUIServerURL substringFromIndex: [@"http://" length]];
    NSComparisonResult res = [urlWithoutSchema compare: uiServerURLWithoutSchema options: NSCaseInsensitiveSearch range: NSMakeRange(0, [uiServerURLWithoutSchema length])];
    if (res == NSOrderedSame)
        [self showUI];
	
#ifdef ALWAYS_SHOW_UI
    [self showUI];
#endif
}

- (void) webView: (WebView*) sender didFinishLoadForFrame: (WebFrame*) frame
{
    NSString *url = [sender mainFrameURL];
    DebugLog(@"didFinishLoadForFrame: {%@}", url);

    NSString *urlWithoutSchema = [url substringFromIndex: [@"http://" length]];
    if ([url hasPrefix: @"https://"])
        urlWithoutSchema = [url substringFromIndex: [@"https://" length]];
    
    NSString *loginSuccessURLWithoutSchema = [kFBLoginSuccessURL substringFromIndex: 7];
    NSComparisonResult res = [urlWithoutSchema compare: loginSuccessURLWithoutSchema options: NSCaseInsensitiveSearch range: NSMakeRange(0, [loginSuccessURLWithoutSchema length])];
    if (res == NSOrderedSame) {
        NSString *accessToken = [self extractParameter: kFBAccessToken fromURL: url];
        NSString *tokenExpires = [self extractParameter: kFBExpiresIn fromURL: url];
        NSString *errorReason = [self extractParameter: kFBErrorReason fromURL: url];

		[self cancel:NSApp];
        [parent setAccessToken: accessToken expires: [tokenExpires floatValue] permissions: self.permissions error: errorReason];
    }
    else {
        // If access token is not retrieved, UI is shown to allow user to login/authorize
        [self showUI];
    }

#ifdef ALWAYS_SHOW_UI
    [self showUI];
#endif
}

- (IBAction) cancel: (id) sender {
	if ([self.popoverController isKindOfClass:[INPopoverController class]]) {
		INPopoverController *popoverController = self.popoverController;
		[popoverController closePopover:nil];
	} 
	else if (self.popoverController && [self.popoverController isKindOfClass:NSClassFromString(@"NSPopover")]) {
		[self.popoverController performClose:NSApp];
	}
	
	[parent performSelector: @selector(didDismissUI)];
}

@end
