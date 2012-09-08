//
//  Data.h
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum { handLeft, handRight, handNum } hand_t;

enum { keyNumOfHand = 24 };

typedef int key_t;

enum {
	keyTab = 11,
	keyCapsLock = 17,
	keyLeftShift = 23,
	keyRightShift = keyNumOfHand + 23
};

extern char charOfKey(key_t k);
extern key_t keyOfChar(char c);

static inline
hand_t handOf(key_t k) { return (k < keyNumOfHand) ? handLeft : handRight; }

enum { recordNum = 16 };

typedef struct {
	int32_t msec[recordNum];
	int32_t count;
} key_record_t;

typedef struct {
	key_t first;
	key_t second;
} key_pair_t;

typedef struct {
	key_pair_t items[handNum * keyNumOfHand * keyNumOfHand];
	int count;
} wanted_stack_t;

@interface Data : NSObject {
	key_record_t items[handNum][keyNumOfHand][keyNumOfHand];
	wanted_stack_t wanted_stack;
	key_pair_t current_wanted;
}

- (key_pair_t)wanted;
- (void)add:(key_pair_t)seq mesc:(int32_t)msec;

- (int32_t)msecOf:(key_pair_t)seq;

- (BOOL)saveToFile:(NSURL *)filename;
- (BOOL)loadFromFile:(NSURL *)filename;

@end
