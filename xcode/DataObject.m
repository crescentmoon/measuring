//
//  DataObject.m
//  measuring
//
//  Created by crescentmoon on 12/11/04.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DataObject.h"


@implementation Data

- (id)init
{
	[super init];
	init_data(&instance);
	return self;
}

- (key_pair_t)wanted
{
	return wanted(&instance);
}

- (void)add:(key_pair_t)seq mesc:(int32_t)msec
{
	add(&instance, seq, msec);
}

- (int32_t)msecOf:(key_pair_t)seq
{
	return msecOf(&instance, seq);
}

- (BOOL)saveToFile:(NSURL *)filename
{
	BOOL result;
	char const *filename_s = [[filename path] fileSystemRepresentation];
	NSLog(@"%s", filename_s);
	result = saveToFile(&instance, filename_s);
	return result;
}

- (BOOL)loadFromFile:(NSURL *)filename
{
	BOOL result;
	char const *filename_s = [[filename path] fileSystemRepresentation];
	NSLog(@"%s", filename_s);
	result = loadFromFile(&instance, filename_s);
	return result;
}

@end
