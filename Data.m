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

static key_record_t *ofLeft(key_record_t (*items)[handNum][keyNumOfHand][keyNumOfHand], key_t first, key_t second)
{
	return &((*items)[handLeft][first][second]);
}

static key_record_t *ofRight(key_record_t (*items)[handNum][keyNumOfHand][keyNumOfHand], key_t first, key_t second)
{
	return &((*items)[handRight][first - keyNumOfHand][second - keyNumOfHand]);
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
	NSLog(@"%c,%c", charOfKey(new_item.first), charOfKey(new_item.second));
	wanted_stack->items[wanted_stack->count] = new_item;
	++ wanted_stack->count;
}

static bool is_near_equal(int32_t a, int32_t b)
{
	int32_t lo = MIN(a, b);
	int32_t hi = MAX(a, b);
	return (hi <= lo * 4 / 3);
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
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手上から下2) */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				for(key_t snd_1 = (pre / 6) * 6 + 6; snd_1 < keyNumOfHand - 6; ++snd_1){
					key_t snd_2 = snd_1 + 6;
					NSAssert(snd_2 < keyNumOfHand, @"bad snd_2");
					if(median(&items[handLeft][pre][snd_1]) >= median(&items[handLeft][pre][snd_2])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手上から下2) */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				for(key_t snd_1 = (pre / 6) * 6 + 6; snd_1 < 2 * keyNumOfHand - 6; ++snd_1){
					key_t snd_2 = snd_1 + 6;
					NSAssert(snd_2 < 2 * keyNumOfHand, @"bad snd_2");
					if(median(&items[handRight][pre - keyNumOfHand][snd_1 - keyNumOfHand]) >= median(&items[handRight][pre - keyNumOfHand][snd_2 - keyNumOfHand])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手下から上2) */
			for(key_t pre = 12; pre < keyNumOfHand; ++pre){
				for(key_t snd_1 = 6; snd_1 < (pre / 6) * 6; ++snd_1){
					key_t snd_2 = snd_1 - 6;
					NSAssert(snd_2 >= 0, @"bad snd_2");
					if(median(&items[handLeft][pre][snd_1]) >= median(&items[handLeft][pre][snd_2])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手下から上2) */
			for(key_t pre = 12 + keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				for(key_t snd_1 = 6 + keyNumOfHand; snd_1 <= (pre / 6) * 6; ++snd_1){
					key_t snd_2 = snd_1 - 6;
					NSAssert(snd_2 >= keyNumOfHand, @"bad snd_2");
					if(median(&items[handRight][pre - keyNumOfHand][snd_1 - keyNumOfHand]) >= median(&items[handRight][pre - keyNumOfHand][snd_2 - keyNumOfHand])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手上2から下) */
			for(key_t pre_1 = 0; pre_1 < keyNumOfHand - 12; ++pre_1){
				key_t pre_2 = pre_1 + 6;
				for(key_t snd = (pre_2 / 6) * 6 + 6; snd < keyNumOfHand; ++snd){
					NSAssert(snd < keyNumOfHand, @"bad snd");
					if(median(ofLeft(&items, pre_1, snd)) <= median(ofLeft(&items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手上2から下) */
			for(key_t pre_1 = keyNumOfHand; pre_1 < 2 * keyNumOfHand - 12; ++pre_1){
				key_t pre_2 = pre_1 + 6;
				for(key_t snd = (pre_2 / 6) * 6 + 6; snd < 2 * keyNumOfHand; ++snd){
					NSAssert(snd < 2 * keyNumOfHand, @"bad snd");
					if(median(ofRight(&items, pre_1, snd)) <= median(ofRight(&items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手下2から上) */
			for(key_t pre_1 = 12; pre_1 < keyNumOfHand; ++pre_1){
				key_t pre_2 = pre_1 - 6;
				for(key_t snd = 0; snd < (pre_2 / 6) * 6; ++snd){
					if(median(ofLeft(&items, pre_1, snd)) <= median(ofLeft(&items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手下2から上) */
			for(key_t pre_1 = keyNumOfHand + 12; pre_1 < 2 * keyNumOfHand; ++pre_1){
				key_t pre_2 = pre_1 - 6;
				for(key_t snd = keyNumOfHand; snd < (pre_2 / 6) * 6; ++snd){
					if(median(ofRight(&items, pre_1, snd)) <= median(ofRight(&items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* 同じ指の連打が余りにも違いすぎたらおかしいよね？ */
			for(key_t key = 0; key < 18; ++key){
				key_t snd = key + 6;
				int32_t a = median(&items[handLeft][key][key]);
				int32_t b = median(&items[handLeft][snd][snd]);
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				key_t snd = key + 6;
				int32_t a = median(&items[handRight][key - keyNumOfHand][key - keyNumOfHand]);
				int32_t b = median(&items[handRight][snd - keyNumOfHand][snd - keyNumOfHand]);
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 同じ指の連打が余りにも違いすぎたらおかしいよね？人差し指横方向 */
			for(key_t key = 0; key <= 18; key += 6){
				key_t snd = key + 1;
				int32_t a = median(ofLeft(&items, key, key));
				int32_t b = median(ofLeft(&items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key <= keyNumOfHand + 18; key += 6){
				key_t snd = key + 1;
				int32_t a = median(ofRight(&items, key, key));
				int32_t b = median(ofRight(&items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 同じ指によるアルペジオが余りにも違いすぎたらおかしいよね？ */
			for(key_t key = key3; key <= keyD; key += 6){
				key_t bottom = key + 6;
				if(! is_near_equal(median(ofLeft(&items, key, key - 1)), median(ofLeft(&items, bottom, bottom - 1)))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = bottom;
					new_item.second = bottom - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = key8; key <= keyK; key += 6){
				key_t bottom = key + 6;
				if(! is_near_equal(median(ofRight(&items, key, key - 1)), median(ofRight(&items, bottom, bottom - 1)))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = bottom;
					new_item.second = bottom - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 左右同形の箇所は余りにも違いすぎたらおかしいよね？(DSAFG→V, HJKL;→N) */
			for(key_t leftFst = keyG; leftFst <= keyA; ++leftFst){
				key_t rightFst = leftFst + keyNumOfHand;
				if(! is_near_equal(median(ofLeft(&items, leftFst, keyV)), median(ofRight(&items, rightFst, keyN)))){
					key_pair_t new_item;
					new_item.first = leftFst;
					new_item.second = keyV;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = rightFst;
					new_item.second = keyN;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
				if(! is_near_equal(median(ofLeft(&items, keyV, leftFst)), median(ofRight(&items, keyN, rightFst)))){
					key_pair_t new_item;
					new_item.first = keyV;
					new_item.second = leftFst;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.first = keyN;
					new_item.second = rightFst;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 連打のほうが同指異段より速いよね？(下) */
			for(key_t key = 0; key < 18; ++key){
				key_t snd = key + 6;
				if(median(&items[handLeft][key][key]) >= median(&items[handLeft][key][snd])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				key_t snd = key + 6;
				if(median(&items[handRight][key - keyNumOfHand][key - keyNumOfHand]) >= median(&items[handRight][key - keyNumOfHand][snd - keyNumOfHand])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 連打のほうが同指異段より速いよね？(上) */
			for(key_t key = 6; key < keyNumOfHand; ++key){
				key_t snd = key - 6;
				if(median(&items[handLeft][key][key]) >= median(&items[handLeft][key][snd])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand + 6; key < 2 * keyNumOfHand; ++key){
				key_t snd = key - 6;
				if(median(&items[handRight][key - keyNumOfHand][key - keyNumOfHand]) >= median(&items[handRight][key - keyNumOfHand][snd - keyNumOfHand])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 同指異段が隣の指より速かったらおかしいよね？(下) */
			for(key_t key = 0; key < 18; ++key){
				for(key_t snd_1 = key + 6; snd_1 < keyNumOfHand; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofLeft(&items, key, snd_1)) <= median(ofLeft(&items, key, snd_2))
							&& !((key == keyQ || key == key1) && snd_1 == keyZ)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofLeft(&items, key, snd_1)) <= median(ofLeft(&items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				for(key_t snd_1 = key + 6; snd_1 < 2 * keyNumOfHand; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofRight(&items, key, snd_1)) <= median(ofRight(&items, key, snd_2))
							&& !((key == key0 || key == keyP) && snd_1 == keySlash)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofRight(&items, key, snd_1)) <= median(ofRight(&items, key, snd_2))
							&& !(key == keyJ && snd_1 == keyM)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			/* 同指異段が隣の指より速かったらおかしいよね？(上) */
			for(key_t key = 6; key < keyNumOfHand; ++key){
				for(key_t snd_1 = key % 6; snd_1 < key; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofLeft(&items, key, snd_1)) <= median(ofLeft(&items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofLeft(&items, key, snd_1)) <= median(ofLeft(&items, key, snd_2))
							&& !((key == keyX || key == keyS) && (snd_1 == keyW || snd_1 == key2))
							&& !(key == keyC && (snd_1 == keyE || snd_1 == key3))) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			for(key_t key = keyNumOfHand; key < 2 * keyNumOfHand; ++key){
				for(key_t snd_1 = keyNumOfHand + key % 6; snd_1 < key; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofRight(&items, key, snd_1)) <= median(ofRight(&items, key, snd_2))
							&& !((key == keyI || key == keyK || key == keyComma) && snd_1 == key8))
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofRight(&items, key, snd_1)) <= median(ofRight(&items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			/* 薬指連打より薬指→中指のほうが速いよね？ */
			for(key_t key = key2; key <= keyX; key += 6){
				if(median(&items[handLeft][key][key - 1]) >= median(&items[handLeft][key][key])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = key9; key <= keyPeriod; key += 6){
				if(median(&items[handRight][key - keyNumOfHand][key - 1 - keyNumOfHand]) >= median(&items[handRight][key - keyNumOfHand][key - keyNumOfHand])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* 中指連打より中指→人差し指のほうが速いよね？ */
			for(key_t key = key3; key <= keyC; key += 6){
				if(median(&items[handLeft][key][key - 1]) >= median(&items[handLeft][key][key])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			for(key_t key = key8; key <= keyComma; key += 6){
				if(median(&items[handRight][key - keyNumOfHand][key - 1 - keyNumOfHand]) >= median(&items[handRight][key - keyNumOfHand][key - keyNumOfHand])){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&wanted_stack, new_item);
				}
			}
			/* A,S,Dからは、Fが一番速いはずだよね？ */
			for(key_t pre = keyD; pre <= keyA; ++pre){
				for(key_t snd = 0; snd < keyNumOfHand; ++snd){
					if(snd % 6 < 2 && snd != keyF){ /* 人差し指のみ */
						if(median(&items[handLeft][pre][keyF]) > median(&items[handLeft][pre][snd])){
							key_pair_t new_item;
							new_item.first = pre;
							new_item.second = keyF;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			/* ;,L,Kからは、Jが一番速いはずだよね？ */
			for(key_t pre = keyK; pre <= keySemicolon; ++pre){
				for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
					if(snd % 6 < 2 && snd != keyJ){ /* 人差し指のみ */
						if(median(&items[handRight][pre - keyNumOfHand][keyJ - keyNumOfHand]) > median(&items[handRight][pre - keyNumOfHand][snd - keyNumOfHand])){
							key_pair_t new_item;
							new_item.first = pre;
							new_item.second = keyJ;
							push_to_wanted_stack(&wanted_stack, new_item);
							new_item.second = snd;
							push_to_wanted_stack(&wanted_stack, new_item);
						}
					}
				}
			}
			/* ZはXより速くあって欲しい…(願望) */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				if(pre % 6 <= 2 && pre < keyB){ /* 人差し指と中指のキーが対象、隣のCVBキーはXが速くていい */
					if(median(&items[handLeft][pre][keyZ]) > median(&items[handLeft][pre][keyX])){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyZ;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = keyX;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = 0; snd < keyNumOfHand; ++snd){
				if(snd % 6 <= 2 && snd < keyB){ /* 人差し指と中指のキーが対象、隣のCVBキーはXが速くていい */
					if(median(&items[handLeft][keyZ][snd]) > median(&items[handLeft][keyX][snd])){
						key_pair_t new_item;
						new_item.first = keyZ;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = keyX;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* ;は'より速くあって欲しい…(願望) */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				if(pre % 6 < 4){ /* 小指以外 */
					if(median(ofRight(&items, pre, keySemicolon)) > median(ofRight(&items, pre, keyApostrophe))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keySemicolon;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.second = keyApostrophe;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
				if(snd % 6 < 4){ /* 小指以外 */
					if(median(ofRight(&items, keySemicolon, snd)) > median(ofRight(&items, keyApostrophe, snd))){
						key_pair_t new_item;
						new_item.first = keySemicolon;
						new_item.second = snd;
						push_to_wanted_stack(&wanted_stack, new_item);
						new_item.first = keyApostrophe;
						push_to_wanted_stack(&wanted_stack, new_item);
					}
				}
			}
			/* E→Q < R→Q < T→Q < G→Q (願望) */
			if(median(&items[handLeft][keyE][keyQ]) > median(&items[handLeft][keyR][keyQ])){
				key_pair_t new_item;
				new_item.first = keyE;
				new_item.second = keyQ;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.first = keyR;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			if(median(&items[handLeft][keyR][keyQ]) > median(&items[handLeft][keyT][keyQ])){
				key_pair_t new_item;
				new_item.first = keyR;
				new_item.second = keyQ;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.first = keyT;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			if(median(&items[handLeft][keyT][keyQ]) > median(&items[handLeft][keyG][keyQ])){
				key_pair_t new_item;
				new_item.first = keyT;
				new_item.second = keyQ;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.first = keyG;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			/* Q→F < Q→D < Q→A (願望) */
			if(median(&items[handLeft][keyQ][keyF]) > median(&items[handLeft][keyQ][keyD])){
				key_pair_t new_item;
				new_item.first = keyQ;
				new_item.second = keyF;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.second = keyD;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			if(median(&items[handLeft][keyQ][keyD]) > median(&items[handLeft][keyQ][keyA])){
				key_pair_t new_item;
				new_item.first = keyQ;
				new_item.second = keyD;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.second = keyA;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			/* D→G < D→T (願望) */
			if(median(ofLeft(&items, keyD, keyG)) >= median(ofLeft(&items, keyD, keyT))){
				key_pair_t new_item;
				new_item.first = keyD;
				new_item.second = keyG;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.second = keyT;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			/* I→P < U→P < Y→P (願望) */
			if(median(&items[handRight][keyI - keyNumOfHand][keyP - keyNumOfHand]) > median(&items[handRight][keyU - keyNumOfHand][keyP - keyNumOfHand])){
				key_pair_t new_item;
				new_item.first = keyI;
				new_item.second = keyP;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.first = keyU;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			if(median(&items[handRight][keyU - keyNumOfHand][keyP - keyNumOfHand]) > median(&items[handRight][keyY - keyNumOfHand][keyP - keyNumOfHand])){
				key_pair_t new_item;
				new_item.first = keyU;
				new_item.second = keyP;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.first = keyY;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			/* P→J < P→K < P→; (願望) */
			if(median(&items[handRight][keyP - keyNumOfHand][keyJ - keyNumOfHand]) > median(&items[handRight][keyP - keyNumOfHand][keyK - keyNumOfHand])){
				key_pair_t new_item;
				new_item.first = keyP;
				new_item.second = keyJ;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.second = keyK;
				push_to_wanted_stack(&wanted_stack, new_item);
			}
			if(median(&items[handRight][keyP - keyNumOfHand][keyK - keyNumOfHand]) > median(&items[handRight][keyP - keyNumOfHand][keySemicolon - keyNumOfHand])){
				key_pair_t new_item;
				new_item.first = keyP;
				new_item.second = keyK;
				push_to_wanted_stack(&wanted_stack, new_item);
				new_item.second = keySemicolon;
				push_to_wanted_stack(&wanted_stack, new_item);
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
