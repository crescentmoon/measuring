//
//  TheField.h
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataObject.h"
#import "DataSource.h"

@interface TheField : NSView {
	Data *data;
	NSString *inputed;
	NSDate *firstTime;
	bool prevCapsLock;
	bool tableInitialized;
	NSURL *filename;
	
	NSTextField *guide;
	DataSource *leftDataSource;
	DataSource *rightDataSource;
}

@property (assign, readwrite) IBOutlet Data *data;
@property (copy, readwrite) NSString *inputed;

@property (assign, readwrite) IBOutlet NSTextField *guide;
@property (assign, readwrite) IBOutlet DataSource *leftDataSource;
@property (assign, readwrite) IBOutlet DataSource *rightDataSource;

- (IBAction)openDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;

@end
