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

static char charOfKeyTable[keyNumOfHand * 2] = {
	'5', '4', '3', '2', '1', '`',
	'T', 'R', 'E', 'W', 'Q', 't',
	'G', 'F', 'D', 'S', 'A', 'c',
	'B', 'V', 'C', 'X', 'Z', 'l',
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
	return -1;
}

static void insert(int32_t *items, int count, int32_t new_item)
{
	int j = count;
	while(j > 0 && new_item < items[j - 1]){
		items[j] = items[j - 1];
		-- j;
	}
	items[j] = new_item;
}

static void sort(int32_t *items, int count)
{
	for(int i = 1; i < count; ++ i){
		insert(items, i, items[i]);
	}
}

static int32_t median(key_record_t const *rec)
{
	int32_t result;
	if(rec->count == 0){
		result = 0;
	}else{
		result = rec->msec[(rec->count - 1) / 2];
	}
	return result;
}

static bool is_filled(key_record_t (*items)[handNum][keyNumOfHand][keyNumOfHand])
{
	for(hand_t hand = 0; hand < handNum; ++hand){
		for(int i = 0; i < keyNumOfHand; ++i){
			for(int j = 0; j < keyNumOfHand; ++j){
				if((*items)[hand][i][j].count == 0){
					return false;
				}
			}
		}
	}
	return true;
}

static void push_to_wanted_stack(wanted_stack_t *wanted_stack, key_pair_t new_item)
{
	for(int i = 0; i < wanted_stack->count; ++ i){
		if(wanted_stack->items[i].first == new_item.first && wanted_stack->items[i].second == new_item.second){
			return; /* 既に追加済み */
		}
	}
	wanted_stack->items[wanted_stack->count] = new_item;
	++ wanted_stack->count;
}

@implementation Data

- (void)updateWanted
{
	/* データが欲しい組み合わせを列挙 */
	if(wanted_stack.count == 0){
		/* 全部埋まっているかチェック */
		bool filled = is_filled(&items);
		/* 全てのデータが埋まっている場合のみ、不自然データのチェック */
		if(filled){
			/* 1000msを超えていたらいくらなんでもおかしいと思う */
			for(hand_t hand = 0; hand < handNum; ++hand){
				for(int i = 0; i < keyNumOfHand; ++i){
					for(int j = 0; j < keyNumOfHand; ++j){
						if(median(&items[hand][i][j]) >= 1000){
							key_pair_t new_item;
							new_item.first = (hand == handLeft) ? i : i + keyNumOfHand;
							new_item.second = (hand == handLeft) ? j : j + keyNumOfHand;;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			/* VよりもBのほうが速かったからおかしいよね？ */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				if(pre % 6 >= 2){ /* 人差し指以外 */
					if(median(&items[handLeft][pre][keyV]) > median(&items[handLeft][pre][keyB])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyB;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = keyV;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = 0; snd < keyNumOfHand; ++snd){
				if(snd % 6 >= 2){ /* 人差し指以外 */
					if(median(&items[handLeft][keyV][snd]) > median(&items[handLeft][keyB][snd])){
						key_pair_t new_item;
						new_item.first = keyB;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = keyV;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* UよりもYのほうが速かったらおかしいよね？ */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				if(pre % 6 >= 2){ /* 人差し指以外 */
					if(median(&items[handRight][pre - keyNumOfHand][keyU - keyNumOfHand]) > median(&items[handRight][pre - keyNumOfHand][keyY - keyNumOfHand])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyY;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = keyU;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
				if(snd % 6 >= 2){ /* 人差し指以外 */
					if(median(&items[handRight][keyU - keyNumOfHand][snd - keyNumOfHand]) > median(&items[handRight][keyY - keyNumOfHand][snd - keyNumOfHand])){
						key_pair_t new_item;
						new_item.first = keyY;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = keyU;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
		}
		/* 少ないデータを求める */
		if(wanted_stack.count == 0){
			int n = INT_MAX;
			for(hand_t hand = 0; hand < handNum; ++hand){
				for(int i = 0; i < keyNumOfHand; ++i){
					for(int j = 0; j < keyNumOfHand; ++j){
						key_t first = (hand == handLeft) ? i : i + keyNumOfHand;
						key_t second = (hand == handLeft) ? j : j + keyNumOfHand;;
						if(items[hand][i][j].count < n){
							n = items[hand][i][j].count;
							wanted_stack.items[0].first = first;
							wanted_stack.items[0].second = second;
							wanted_stack.count = 1;
						} else if(items[hand][i][j].count == n){
							wanted_stack.items[wanted_stack.count].first = first;
							wanted_stack.items[wanted_stack.count].second = second;
							++ wanted_stack.count;
						}
					}
				}
			}
		}
	}
	/* 出題 */
	if(wanted_stack.count == 0){
		NSLog(@"maybe bug");
		current_wanted.first = 0;
		current_wanted.second = 0;
	}else{
		/* ランダムに出題 */
		int wanted_index = rand() % wanted_stack.count;
		current_wanted = wanted_stack.items[wanted_index];
		/* 出題した分を取り除く */
		-- wanted_stack.count;
		for(int i = wanted_index; i < wanted_stack.count; ++i){
			wanted_stack.items[i] = wanted_stack.items[i + 1];
		}
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
	wanted_stack.count = 0;
	[self updateWanted];
	return self;
}

- (key_pair_t)wanted
{
	return current_wanted;
}

- (void)add:(key_pair_t)seq mesc:(int32_t)msec
{
	hand_t hand = handOf(seq.first);
	if(hand == handOf(seq.second)){
		int firstIndex = (hand == handLeft) ? seq.first : seq.first - keyNumOfHand;
		int secondIndex = (hand == handLeft) ? seq.second : seq.second - keyNumOfHand;
		key_record_t *rec = &items[hand][firstIndex][secondIndex];
		if(rec->count >= recordNum){
			//最低値と最大値を取り除く
			for(int i = 1; i < rec->count - 1; ++i){
				rec->msec[i - 1] = rec->msec[i];
			}
			rec->count -= 2;
		}
		//追加
		insert(rec->msec, rec->count, msec);
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
		key_record_t *rec = &items[hand][firstIndex][secondIndex];
		result = median(rec); /* 中央値 */
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
					key_record_t *rec = &items[hand][i][j];
					/* clear unused area */
					for(int k = rec->count; k < recordNum; ++k){
						rec->msec[k] = 0;
					}
					/* write */
					if(fwrite(rec->msec, sizeof(int32_t), recordNum, file) < recordNum) goto error;
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
					key_record_t *rec = &items[hand][i][j];
					/* read */
					if(fread(rec->msec, sizeof(int32_t), recordNum, file) < recordNum) goto error;
					/* 数える */
					rec->count = recordNum;
					while(rec->count > 0 && rec->msec[rec->count - 1] == 0){
						-- rec->count;
					}
					/* ソートしておく */
					sort(rec->msec, rec->count);
				}
			}
		}
		result = YES;
	error:
		if(fclose(file) < 0) result = NO;
	}
	//問題差し替え
	if(result){
		wanted_stack.count = 0;
		[self updateWanted];
	}
	return result;
}

@end
