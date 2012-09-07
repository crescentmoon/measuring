//
//  DataSource.h
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"


@interface DataSource : NSObject<NSTableViewDataSource> {
	Data *data;
	hand_t hand;
	NSTableView *view;
	bool columnsInitialized;
}

- (void)setup:(Data *)the_data hand:(hand_t)the_hand;
- (void)setNeedsDisplay:(BOOL)flag;

@end
