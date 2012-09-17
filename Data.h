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
	key5 = 0,
	key4 = 1,
	key3 = 2,
	key2 = 3,
	key1 = 4,
	keyBackQuote = 5,
	keyT = 6,
	keyR = 7,
	keyE = 8,
	keyW = 9,
	keyQ = 10,
	keyTab = 11,
	keyG = 12,
	keyF = 13,
	keyD = 14,
	keyS = 15,
	keyA = 16,
	keyCapsLock = 17,
	keyB = 18,
	keyV = 19,
	keyC = 20,
	keyX = 21,
	keyZ = 22,
	keyLeftShift = 23,
	keyY = keyNumOfHand + 6,
	keyU = keyNumOfHand + 7,
	keyI = keyNumOfHand + 8,
	keyO = keyNumOfHand + 9,
	keyP = keyNumOfHand + 10,
	keyOpenBracket = keyNumOfHand + 11,
	keyJ = keyNumOfHand + 13,
	keyK = keyNumOfHand + 14,
	keyL = keyNumOfHand + 15,
	keySemicolon = keyNumOfHand + 16,
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
