//
//  Data.m
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Data.h"
#import <stdlib.h>
#import <stdio.h>

char charOfKeyTable[keyNumOfHand * 2] = {
	'`', '1', '2', '3', '4', '5',
	't', 'Q', 'W', 'E', 'R', 'T',
	'c', 'A', 'S', 'D', 'F', 'G',
	'l', 'Z', 'X', 'C', 'V', 'B',
	'6', '7', '8', '9', '0', '-',
	'Y', 'U', 'I', 'O', 'P', '[',
	'H', 'J', 'K', 'L', ';', '\'',
	'N', 'M', ',', '.', '/', 'r'};
	
char charOfKey(key_t k)
{
	return charOfKeyTable[k];
}

key_t keyOfChar(char c)
{
	for(int i = 0; i < keyNumOfHand * 2; ++i){
		if(charOfKeyTable[i] == c){
			return i;
		}
	}
	if(c == '\t') return 6; /* TAB */
	return -1;
}

void sort(int32_t *items, int count)
{
}

@implementation Data

- (void)updateWanted
{
	key_pair_t candidates[keyNumOfHand * keyNumOfHand * 2];
	int candidate_count = 0;
	int n = INT_MAX;
	for(hand_t hand = 0; hand < handNum; ++hand){
		for(int i = 0; i < keyNumOfHand; ++i){
			for(int j = 0; j < keyNumOfHand; ++j){
				key_t first = (hand == handLeft) ? i : i + keyNumOfHand;
				key_t second = (hand == handLeft) ? j : j + keyNumOfHand;;
				if(items[hand][i][j].count < n){
					n = items[hand][i][j].count;
					candidates[0].first = first;
					candidates[0].second = second;
					candidate_count = 1;
				} else if(items[hand][i][j].count == n){
					candidates[candidate_count].first = first;
					candidates[candidate_count].second = second;
					++ candidate_count;
				}
			}
		}
	}
	if(candidate_count == 0){
		NSLog(@"maybe bug");
		wanted.first = 0;
		wanted.second = 0;
	}else{
		wanted = candidates[rand() % candidate_count];
	}
}

- (id)init
{
	[super init];
	for(hand_t hand = 0; hand < handNum; ++hand){
		for(int i = 0; i < keyNumOfHand; ++i){
			for(int j = 0; j < keyNumOfHand; ++j){
				items[hand][i][j].count = 0;
			}
		}
	}
	[self updateWanted];
	return self;
}

- (key_pair_t)wanted
{
	return wanted;
}

- (void)regenerateWanted
{
	[self updateWanted];
}

- (void)add:(key_pair_t)seq mesc:(int32_t)msec
{
	hand_t hand = handOf(seq.first);
	if(hand == handOf(seq.second)){
		int firstIndex = (hand == handLeft) ? seq.first : seq.first - keyNumOfHand;
		int secondIndex = (hand == handLeft) ? seq.second : seq.second - keyNumOfHand;
		key_record_t *rec = &items[hand][firstIndex][secondIndex];
		if(rec->count >= recordNum){
			sort(rec->msec, rec->count);
			//最低値と最大値を取り除く
			for(int i = 1; i < rec->count - 1; ++i){
				rec->msec[i - 1] = rec->msec[i];
			}
			rec->count -= 2;
		}
		int recIndex = rec->count;
		rec->msec[recIndex] = msec;
		++ rec->count;
		//次を準備
		[self updateWanted];
	}
}

- (int32_t)msecOf:(key_pair_t)seq
{
	int32_t result = 0;
	hand_t hand = handOf(seq.first);
	if(hand == handOf(seq.second)){
		int firstIndex = (hand == handLeft) ? seq.first : seq.first - keyNumOfHand;
		int secondIndex = (hand == handLeft) ? seq.second : seq.second - keyNumOfHand;
		if(items[hand][firstIndex][secondIndex].count > 0){
			for(int i = 0; i < items[hand][firstIndex][secondIndex].count; ++i){
				result += items[hand][firstIndex][secondIndex].msec[i];
			}
			result /= items[hand][firstIndex][secondIndex].count;
		}
	}
	return result;
}

- (BOOL)saveToFile:(NSURL *)filename
{
	BOOL result = NO;
	char const *filename_s = [[filename path] fileSystemRepresentation];
	NSLog(@"%s", filename_s);
	FILE *file = fopen(filename_s, "wb");
	if(file){
		for(hand_t hand = 0; hand < handNum; ++hand){
			for(int i = 0; i < keyNumOfHand; ++i){
				for(int j = 0; j < keyNumOfHand; ++j){
					int32_t *msec = items[hand][i][j].msec;
					/* clear unused area */
					for(int k = items[hand][i][j].count; k < recordNum; ++k){
						msec[k] = 0;
					}
					/* write */
					if(fwrite(msec, sizeof(int32_t), recordNum, file) < recordNum) goto error;
				}
			}
		}
		result = YES;
	error:
		if(fclose(file) < 0) result = NO;
	}
	return result;
}

- (BOOL)loadFromFile:(NSURL *)filename
{
	BOOL result = NO;
	char const *filename_s = [[filename path] fileSystemRepresentation];
	NSLog(@"%s", filename_s);
	FILE *file = fopen(filename_s, "rb");
	if(file){
		for(hand_t hand = 0; hand < handNum; ++hand){
			for(int i = 0; i < keyNumOfHand; ++i){
				for(int j = 0; j < keyNumOfHand; ++j){
					int32_t *msec = items[hand][i][j].msec;
					/* read */
					if(fread(msec, sizeof(int32_t), recordNum, file) < recordNum) goto error;
					/* 数える */
					items[hand][i][j].count = recordNum;
					while(items[hand][i][j].count > 0 && msec[items[hand][i][j].count - 1] == 0){
						-- items[hand][i][j].count;
					}
				}
			}
		}
		result = YES;
	error:
		if(fclose(file) < 0) result = NO;
	}
	return result;
}

@end
