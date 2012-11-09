//
//  DataObject.h
//  measuring
//
//  Created by crescentmoon on 12/11/04.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "data.h"


/* the Objective-C wrapper of data.h */

@interface Data : NSObject {
	data_t instance;
}

- (bool)is_fixing_mode;
- (key_pair_t)wanted;
- (void)add:(key_pair_t)seq mesc:(int32_t)msec;

- (int32_t)msecOf:(key_pair_t)seq;

- (BOOL)saveToFile:(NSURL *)filename;
- (BOOL)loadFromFile:(NSURL *)filename;

@end
