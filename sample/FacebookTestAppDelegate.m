//
//  FacebookTestAppDelegate.m
//  FacebookTest
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "FacebookTestAppDelegate.h"
#import "ApplicationID.h"

@implementation FacebookTestAppDelegate

@synthesize token_label;
@synthesize request_label;
@synthesize request_text;
@synthesize result_text;
@synthesize profile_picture;
@synthesize send_request;
@synthesize window;

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
    fb = [[PhFacebook alloc] initWithApplicationID: APPLICATION_ID delegate: self];
    self.token_label.stringValue = @"Invalid";
    [self.request_label setEnabled: NO];
    [self.request_text setEnabled: NO];
    [self.send_request setEnabled: NO];
    [self.result_text setEditable: NO];
    [self.result_text setFont: [NSFont fontWithName: @"Monaco" size: 10.0]];
}

#pragma mark IBActions

- (IBAction) getAccessToken: (id) sender
{
	if (NSClassFromString(@"NSPopover")) {
		NSLog(@"aa");
//		NSPopover *_popover = [[NSPopover alloc] init];
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
//        _popover.contentViewController = [fb ]
//        _popover.behavior = NSPopoverBehaviorTransient;
//        _popover.delegate = self;
		
//		[_popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
		
	}
    // Always get a new token, don't get a cached one
	[fb setSender:sender];
    [fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"read_stream", @"export_stream", nil] cached: NO];
}

- (IBAction) sendRequest: (id) sender
{
    [self.send_request setEnabled: NO];
    [fb sendRequest: request_text.stringValue];
}

#pragma mark PhFacebookDelegate methods

- (void) tokenResult: (NSDictionary*) result
{
    if ([[result valueForKey: @"valid"] boolValue])
    {
        self.token_label.stringValue = @"Valid";
        [self.request_label setEnabled: YES];
        [self.request_text setEnabled: YES];
        [self.send_request setEnabled: YES];
        [self.result_text setEditable: YES];
        [fb sendRequest: @"me/picture"];
    }
    else
    {
        [self.result_text setString: [NSString stringWithFormat: @"Error: {%@}", [result valueForKey: @"error"]]];
    }
}

- (void) requestResult: (NSDictionary*) result
{
    if ([[result objectForKey: @"request"] isEqualTo: @"me/picture"])
    {
        NSImage *pic = [[NSImage alloc] initWithData: [result objectForKey: @"raw"]];
        self.profile_picture.image = pic;
        [pic release];
        
    } else 
    {
        [self.send_request setEnabled: YES];
        [self.result_text setString: [NSString stringWithFormat: @"Request: {%@}\n%@", [result objectForKey: @"request"], [result objectForKey: @"result"]]];
    }
}

- (void) willShowUINotification: (PhFacebook*) sender
{
    [NSApp requestUserAttention: NSInformationalRequest];
}

@end
