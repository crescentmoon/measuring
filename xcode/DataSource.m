//
//  DataSource.m
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DataSource.h"

static key_t keyOfSightOrder(hand_t hand, int i)
{
	return (hand == handLeft) ? ((i / 6) * 6) + (5 - (i % 6)) : keyNumOfHand + i;
}

@implementation DataSource

- (void)setup:(Data *)the_data hand:(hand_t)the_hand
{
	data = the_data;
	hand = the_hand;
	view = nil;
	columnsInitialized = false;
}

- (void)setNeedsDisplay:(BOOL)flag
{
	[view setNeedsDisplay:YES];
}

/* NSTableViewDataSource */

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if(! columnsInitialized){
		view = tableView;
		columnsInitialized = true;
		for(int i = 0; i < keyNumOfHand; ++i){
			key_t key = keyOfSightOrder(hand, i);
			NSArray *columns = [tableView tableColumns];
			NSTableColumn *column = [columns objectAtIndex:(i + 1)];
			char s[2];
			s[0] = charOfKey(key);
			s[1] = '\0';
			NSString *sobj = [[NSString alloc] initWithCString:s];
			[column setIdentifier:sobj];
			[[column headerCell] setStringValue:sobj];
			[sobj release];
		}
	}
	return keyNumOfHand;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	NSString *ident = [tableColumn identifier];
	key_t first = keyOfSightOrder(hand, row);
	if([ident isEqualToString:@"from"]){
		char s[2];
		s[0] = charOfKey(first);
		s[1] = '\0';
		NSString *sobj = [[NSString alloc] initWithCString:s];
		[sobj autorelease];
		return sobj;
	}else{
		char const *ident_s = [ident UTF8String];
		key_pair_t pair;
		pair.first = first;
		pair.second = keyOfChar(ident_s[0]);
		int32_t msec = [data msecOf:pair];
		return [[NSNumber alloc] initWithInt:msec];
	}
}

@end
