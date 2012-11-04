//
//  data.c
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include "data.h"
#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>

#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#if defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>
extern void NSLog(CFStringRef, ...);
#define log(fmt, ...) \
	do{ \
		CFStringRef fmtObj; \
		fmtObj = CFStringCreateWithCStringNoCopy(NULL, fmt, kCFStringEncodingUTF8, kCFAllocatorNull); \
		NSLog(fmtObj, __VA_ARGS__); \
		CFRelease(fmtObj); \
	}while(0)
#else
#define log(fmt, ...) fprintf(stderr, fmt, __VA_ARGS__)
#endif

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
	log("%c,%c", charOfKey(new_item.first), charOfKey(new_item.second));
	wanted_stack->items[wanted_stack->count] = new_item;
	++ wanted_stack->count;
}

static bool is_near_equal(int32_t a, int32_t b)
{
	int32_t lo = min(a, b);
	int32_t hi = max(a, b);
	return (hi <= lo * 4 / 3);
}

static void updateWanted(data_t *data)
{
	/* データが欲しい組み合わせを列挙 */
	if(data->wanted_stack.count == 0){
		log("update wanted...", 0);
		/* 全部埋まっているかチェック */
		bool filled = is_filled(&data->items);
		/* 全てのデータが埋まっている場合のみ、不自然データのチェック */
		if(filled){
			/* 1000msを超えていたらいくらなんでもおかしいと思う */
			for(hand_t hand = 0; hand < handNum; ++hand){
				for(int i = 0; i < keyNumOfHand; ++i){
					for(int j = 0; j < keyNumOfHand; ++j){
						if(median(&data->items[hand][i][j]) >= 1000){
							key_pair_t new_item;
							new_item.first = (hand == handLeft) ? i : i + keyNumOfHand;
							new_item.second = (hand == handLeft) ? j : j + keyNumOfHand;;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			/* VよりもBのほうが速かったからおかしいよね？ */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				if(pre % 6 >= 2){ /* 人差し指以外 */
					if(median(ofLeft(&data->items, pre, keyV)) > median(ofLeft(&data->items, pre, keyB))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyB;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = keyV;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = 0; snd < keyNumOfHand; ++snd){
				if(snd % 6 >= 2){ /* 人差し指以外 */
					if(median(ofLeft(&data->items, keyV, snd)) > median(ofLeft(&data->items, keyB, snd))){
						key_pair_t new_item;
						new_item.first = keyB;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = keyV;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* UよりもYのほうが速かったらおかしいよね？ */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				if(pre % 6 >= 2){ /* 人差し指以外 */
					if(median(ofRight(&data->items, pre, keyU)) > median(ofRight(&data->items, pre, keyY))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyY;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = keyU;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
				if(snd % 6 >= 2){ /* 人差し指以外 */
					if(median(ofRight(&data->items, keyU, snd)) > median(ofRight(&data->items, keyY, snd))){
						key_pair_t new_item;
						new_item.first = keyY;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = keyU;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手上から下2) */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				for(key_t snd_1 = (pre / 6) * 6 + 6; snd_1 < keyNumOfHand - 6; ++snd_1){
					key_t snd_2 = snd_1 + 6;
					assert(snd_2 < keyNumOfHand);
					if(median(ofLeft(&data->items, pre, snd_1)) >= median(ofLeft(&data->items, pre, snd_2))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手上から下2) */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				for(key_t snd_1 = (pre / 6) * 6 + 6; snd_1 < 2 * keyNumOfHand - 6; ++snd_1){
					key_t snd_2 = snd_1 + 6;
					assert(snd_2 < 2 * keyNumOfHand);
					if(median(ofRight(&data->items, pre, snd_1)) >= median(ofRight(&data->items, pre, snd_2))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手下から上2) */
			for(key_t pre = 12; pre < keyNumOfHand; ++pre){
				for(key_t snd_1 = 6; snd_1 < (pre / 6) * 6; ++snd_1){
					key_t snd_2 = snd_1 - 6;
					assert(snd_2 >= 0);
					if(median(ofLeft(&data->items, pre, snd_1)) >= median(ofLeft(&data->items, pre, snd_2))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手下から上2) */
			for(key_t pre = 12 + keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				for(key_t snd_1 = 6 + keyNumOfHand; snd_1 <= (pre / 6) * 6; ++snd_1){
					key_t snd_2 = snd_1 - 6;
					assert(snd_2 >= keyNumOfHand);
					if(median(ofRight(&data->items, pre, snd_1)) >= median(ofRight(&data->items, pre, snd_2))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = snd_1;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = snd_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手上2から下) */
			for(key_t pre_1 = 0; pre_1 < keyNumOfHand - 12; ++pre_1){
				key_t pre_2 = pre_1 + 6;
				for(key_t snd = (pre_2 / 6) * 6 + 6; snd < keyNumOfHand; ++snd){
					assert(snd < keyNumOfHand);
					if(median(ofLeft(&data->items, pre_1, snd)) <= median(ofLeft(&data->items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手上2から下) */
			for(key_t pre_1 = keyNumOfHand; pre_1 < 2 * keyNumOfHand - 12; ++pre_1){
				key_t pre_2 = pre_1 + 6;
				for(key_t snd = (pre_2 / 6) * 6 + 6; snd < 2 * keyNumOfHand; ++snd){
					assert(snd < 2 * keyNumOfHand);
					if(median(ofRight(&data->items, pre_1, snd)) <= median(ofRight(&data->items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(左手下2から上) */
			for(key_t pre_1 = 12; pre_1 < keyNumOfHand; ++pre_1){
				key_t pre_2 = pre_1 - 6;
				for(key_t snd = 0; snd < (pre_2 / 6) * 6; ++snd){
					if(median(ofLeft(&data->items, pre_1, snd)) <= median(ofLeft(&data->items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 跳躍が一段差よりも速かったらおかしいよね？(右手下2から上) */
			for(key_t pre_1 = keyNumOfHand + 12; pre_1 < 2 * keyNumOfHand; ++pre_1){
				key_t pre_2 = pre_1 - 6;
				for(key_t snd = keyNumOfHand; snd < (pre_2 / 6) * 6; ++snd){
					if(median(ofRight(&data->items, pre_1, snd)) <= median(ofRight(&data->items, pre_2, snd))){
						key_pair_t new_item;
						new_item.first = pre_1;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = pre_2;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* 同じ指の連打が余りにも違いすぎたらおかしいよね？ */
			for(key_t key = 0; key < 18; ++key){
				key_t snd = key + 6;
				int32_t a = median(ofLeft(&data->items, key, key));
				int32_t b = median(ofLeft(&data->items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				key_t snd = key + 6;
				int32_t a = median(ofRight(&data->items, key, key));
				int32_t b = median(ofRight(&data->items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 同じ指の連打が余りにも違いすぎたらおかしいよね？人差し指横方向 */
			for(key_t key = 0; key <= 18; key += 6){
				key_t snd = key + 1;
				int32_t a = median(ofLeft(&data->items, key, key));
				int32_t b = median(ofLeft(&data->items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key <= keyNumOfHand + 18; key += 6){
				key_t snd = key + 1;
				int32_t a = median(ofRight(&data->items, key, key));
				int32_t b = median(ofRight(&data->items, snd, snd));
				if(! is_near_equal(a, b)){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = snd;
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 同じ指によるアルペジオが余りにも違いすぎたらおかしいよね？ */
			for(key_t key = key3; key <= keyD; key += 6){
				key_t bottom = key + 6;
				if(! is_near_equal(median(ofLeft(&data->items, key, key - 1)), median(ofLeft(&data->items, bottom, bottom - 1)))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = bottom;
					new_item.second = bottom - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = key8; key <= keyK; key += 6){
				key_t bottom = key + 6;
				if(! is_near_equal(median(ofRight(&data->items, key, key - 1)), median(ofRight(&data->items, bottom, bottom - 1)))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = bottom;
					new_item.second = bottom - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 左右同形の箇所は余りにも違いすぎたらおかしいよね？(DSAFG→V, HJKL;→N) */
			for(key_t leftFst = keyG; leftFst <= keyA; ++leftFst){
				key_t rightFst = leftFst + keyNumOfHand;
				if(! is_near_equal(median(ofLeft(&data->items, leftFst, keyV)), median(ofRight(&data->items, rightFst, keyN)))){
					key_pair_t new_item;
					new_item.first = leftFst;
					new_item.second = keyV;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = rightFst;
					new_item.second = keyN;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
				if(! is_near_equal(median(ofLeft(&data->items, keyV, leftFst)), median(ofRight(&data->items, keyN, rightFst)))){
					key_pair_t new_item;
					new_item.first = keyV;
					new_item.second = leftFst;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.first = keyN;
					new_item.second = rightFst;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 連打のほうが同指異段より速いよね？(下) */
			for(key_t key = 0; key < 18; ++key){
				key_t snd = key + 6;
				if(median(ofLeft(&data->items, key, key)) >= median(ofLeft(&data->items, key, snd))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				key_t snd = key + 6;
				if(median(ofRight(&data->items, key, key)) >= median(ofRight(&data->items, key, snd))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 連打のほうが同指異段より速いよね？(上) */
			for(key_t key = 6; key < keyNumOfHand; ++key){
				key_t snd = key - 6;
				if(median(ofLeft(&data->items, key, key)) >= median(ofLeft(&data->items, key, snd))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = keyNumOfHand + 6; key < 2 * keyNumOfHand; ++key){
				key_t snd = key - 6;
				if(median(ofRight(&data->items, key, key)) >= median(ofRight(&data->items, key, snd))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = snd;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 同指異段が隣の指より速かったらおかしいよね？(下) */
			for(key_t key = 0; key < 18; ++key){
				for(key_t snd_1 = key + 6; snd_1 < keyNumOfHand; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofLeft(&data->items, key, snd_1)) <= median(ofLeft(&data->items, key, snd_2))
							&& !((key == keyA || key == keyQ || key == key1) && snd_1 == keyZ)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofLeft(&data->items, key, snd_1)) <= median(ofLeft(&data->items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			for(key_t key = keyNumOfHand; key < keyNumOfHand + 18; ++key){
				for(key_t snd_1 = key + 6; snd_1 < 2 * keyNumOfHand; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofRight(&data->items, key, snd_1)) <= median(ofRight(&data->items, key, snd_2))
							&& !((key == key0 || key == keyP) && snd_1 == keySlash)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofRight(&data->items, key, snd_1)) <= median(ofRight(&data->items, key, snd_2))
							&& !(key == keyJ && snd_1 == keyM)) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			/* 同指異段が隣の指より速かったらおかしいよね？(上) */
			for(key_t key = 6; key < keyNumOfHand; ++key){
				for(key_t snd_1 = key % 6; snd_1 < key; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofLeft(&data->items, key, snd_1)) <= median(ofLeft(&data->items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofLeft(&data->items, key, snd_1)) <= median(ofLeft(&data->items, key, snd_2))
							&& !((key == keyX || key == keyS) && (snd_1 == keyW || snd_1 == key2))
							&& !(key == keyC && (snd_1 == keyE || snd_1 == key3))) /* 例外 */
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			for(key_t key = keyNumOfHand; key < 2 * keyNumOfHand; ++key){
				for(key_t snd_1 = keyNumOfHand + key % 6; snd_1 < key; snd_1 += 6){
					if(key % 6 >= 2 && key % 6 <= 4){ /* 中指薬指小指 */
						key_t snd_2 = snd_1 - 1;
						if(median(ofRight(&data->items, key, snd_1)) <= median(ofRight(&data->items, key, snd_2))
							&& !((key == keyI || key == keyK || key == keyComma) && snd_1 == key8))
						{
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
					if(key % 6 >= 1 && key % 6 <= 3){ /* 人差し指中指薬指 */
						key_t snd_2 = snd_1 + 1;
						if(median(ofRight(&data->items, key, snd_1)) <= median(ofRight(&data->items, key, snd_2))){
							key_pair_t new_item;
							new_item.first = key;
							new_item.second = snd_1;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd_2;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			/* 薬指連打より薬指→中指のほうが速いよね？ */
			for(key_t key = key2; key <= keyX; key += 6){
				if(median(ofLeft(&data->items, key, key - 1)) >= median(ofLeft(&data->items, key, key))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = key9; key <= keyPeriod; key += 6){
				if(median(ofRight(&data->items, key, key - 1)) >= median(ofRight(&data->items, key, key))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* 中指連打より中指→人差し指のほうが速いよね？ */
			for(key_t key = key3; key <= keyC; key += 6){
				if(median(ofLeft(&data->items, key, key - 1)) >= median(ofLeft(&data->items, key, key))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			for(key_t key = key8; key <= keyComma; key += 6){
				if(median(ofRight(&data->items, key, key - 1)) >= median(ofRight(&data->items, key, key))){
					key_pair_t new_item;
					new_item.first = key;
					new_item.second = key;
					push_to_wanted_stack(&data->wanted_stack, new_item);
					new_item.second = key - 1;
					push_to_wanted_stack(&data->wanted_stack, new_item);
				}
			}
			/* A,S,Dからは、Fが一番速いはずだよね？ */
			for(key_t pre = keyD; pre <= keyA; ++pre){
				for(key_t snd = 0; snd < keyNumOfHand; ++snd){
					if(snd % 6 < 2 && snd != keyF){ /* 人差し指のみ */
						if(median(ofLeft(&data->items, pre, keyF)) > median(ofLeft(&data->items, pre, snd))){
							key_pair_t new_item;
							new_item.first = pre;
							new_item.second = keyF;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			/* ;,L,Kからは、Jが一番速いはずだよね？ */
			for(key_t pre = keyK; pre <= keySemicolon; ++pre){
				for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
					if(snd % 6 < 2 && snd != keyJ){ /* 人差し指のみ */
						if(median(ofRight(&data->items, pre, keyJ)) > median(ofRight(&data->items, pre, snd))){
							key_pair_t new_item;
							new_item.first = pre;
							new_item.second = keyJ;
							push_to_wanted_stack(&data->wanted_stack, new_item);
							new_item.second = snd;
							push_to_wanted_stack(&data->wanted_stack, new_item);
						}
					}
				}
			}
			/* ZはXより速くあって欲しい…(願望) */
			for(key_t pre = 0; pre < keyNumOfHand; ++pre){
				if(pre % 6 <= 2 && pre < keyB){ /* 人差し指と中指のキーが対象、隣のCVBキーはXが速くていい */
					if(median(ofLeft(&data->items, pre, keyZ)) > median(ofLeft(&data->items, pre, keyX))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keyZ;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = keyX;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = 0; snd < keyNumOfHand; ++snd){
				if(snd % 6 <= 2 && snd < keyB){ /* 人差し指と中指のキーが対象、隣のCVBキーはXが速くていい */
					if(median(ofLeft(&data->items, keyZ, snd)) > median(ofLeft(&data->items, keyX, snd))){
						key_pair_t new_item;
						new_item.first = keyZ;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = keyX;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* ;は'より速くあって欲しい…(願望) */
			for(key_t pre = keyNumOfHand; pre < 2 * keyNumOfHand; ++pre){
				if(pre % 6 < 4){ /* 小指以外 */
					if(median(ofRight(&data->items, pre, keySemicolon)) > median(ofRight(&data->items, pre, keyApostrophe))){
						key_pair_t new_item;
						new_item.first = pre;
						new_item.second = keySemicolon;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.second = keyApostrophe;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			for(key_t snd = keyNumOfHand; snd < 2 * keyNumOfHand; ++snd){
				if(snd % 6 < 4){ /* 小指以外 */
					if(median(ofRight(&data->items, keySemicolon, snd)) > median(ofRight(&data->items, keyApostrophe, snd))){
						key_pair_t new_item;
						new_item.first = keySemicolon;
						new_item.second = snd;
						push_to_wanted_stack(&data->wanted_stack, new_item);
						new_item.first = keyApostrophe;
						push_to_wanted_stack(&data->wanted_stack, new_item);
					}
				}
			}
			/* E→Q < R→Q < T→Q < G→Q (願望) */
			if(median(ofLeft(&data->items, keyE, keyQ)) > median(ofLeft(&data->items, keyR, keyQ))){
				key_pair_t new_item;
				new_item.first = keyE;
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.first = keyR;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			if(median(ofLeft(&data->items, keyR, keyQ)) > median(ofLeft(&data->items, keyT, keyQ))){
				key_pair_t new_item;
				new_item.first = keyR;
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.first = keyT;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			if(median(ofLeft(&data->items, keyT, keyQ)) > median(ofLeft(&data->items, keyG, keyQ))){
				key_pair_t new_item;
				new_item.first = keyT;
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.first = keyG;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* Q→F < Q→D < Q→A (願望) */
			if(median(ofLeft(&data->items, keyQ, keyF)) > median(ofLeft(&data->items, keyQ, keyD))){
				key_pair_t new_item;
				new_item.first = keyQ;
				new_item.second = keyF;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyD;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			if(median(ofLeft(&data->items, keyQ, keyD)) > median(ofLeft(&data->items, keyQ, keyA))){
				key_pair_t new_item;
				new_item.first = keyQ;
				new_item.second = keyD;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyA;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* D→G < D→T (願望) */
			if(median(ofLeft(&data->items, keyD, keyG)) >= median(ofLeft(&data->items, keyD, keyT))){
				key_pair_t new_item;
				new_item.first = keyD;
				new_item.second = keyG;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyT;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* S→Z < S→Q (願望) */
			if(median(ofLeft(&data->items, keyS, keyZ)) >= median(ofLeft(&data->items, keyS, keyQ))){
				key_pair_t new_item;
				new_item.first = keyS;
				new_item.second = keyZ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* R→ZとR→Qは近い (願望, R→A < R→Zは段差チェックに含まれる) */
			if(! is_near_equal(median(ofLeft(&data->items, keyR, keyZ)), median(ofLeft(&data->items, keyR, keyQ)))){
				key_pair_t new_item;
				new_item.first = keyR;
				new_item.second = keyZ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* T→ZとT→Qは近い (願望, T→A < T→Zは段差チェックに含まれる) */
			if(! is_near_equal(median(ofLeft(&data->items, keyT, keyZ)), median(ofLeft(&data->items, keyT, keyQ)))){
				key_pair_t new_item;
				new_item.first = keyT;
				new_item.second = keyZ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyQ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* I→P < U→P < Y→P (願望) */
			if(median(ofRight(&data->items, keyI, keyP)) > median(ofRight(&data->items, keyU, keyP))){
				key_pair_t new_item;
				new_item.first = keyI;
				new_item.second = keyP;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.first = keyU;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			if(median(ofRight(&data->items, keyU, keyP)) > median(ofRight(&data->items, keyY, keyP))){
				key_pair_t new_item;
				new_item.first = keyU;
				new_item.second = keyP;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.first = keyY;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			/* P→J < P→K < P→; (願望) */
			if(median(ofRight(&data->items, keyP, keyJ)) > median(ofRight(&data->items, keyP, keyK))){
				key_pair_t new_item;
				new_item.first = keyP;
				new_item.second = keyJ;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keyK;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
			if(median(ofRight(&data->items, keyP, keyK)) > median(ofRight(&data->items, keyP, keySemicolon))){
				key_pair_t new_item;
				new_item.first = keyP;
				new_item.second = keyK;
				push_to_wanted_stack(&data->wanted_stack, new_item);
				new_item.second = keySemicolon;
				push_to_wanted_stack(&data->wanted_stack, new_item);
			}
		}
		/* 少ないデータを求める */
		if(data->wanted_stack.count == 0){
			int n = INT_MAX;
			for(hand_t hand = 0; hand < handNum; ++hand){
				for(int i = 0; i < keyNumOfHand; ++i){
					for(int j = 0; j < keyNumOfHand; ++j){
						key_t first = (hand == handLeft) ? i : i + keyNumOfHand;
						key_t second = (hand == handLeft) ? j : j + keyNumOfHand;;
						if(data->items[hand][i][j].count < n){
							n = data->items[hand][i][j].count;
							data->wanted_stack.items[0].first = first;
							data->wanted_stack.items[0].second = second;
							data->wanted_stack.count = 1;
						} else if(data->items[hand][i][j].count == n){
							data->wanted_stack.items[data->wanted_stack.count].first = first;
							data->wanted_stack.items[data->wanted_stack.count].second = second;
							++ data->wanted_stack.count;
						}
					}
				}
			}
		}
	}
	/* 出題 */
	if(data->wanted_stack.count == 0){
		log("maybe bug", 0);
		data->current_wanted.first = 0;
		data->current_wanted.second = 0;
	}else{
		/* ランダムに出題 */
		int wanted_index = rand() % data->wanted_stack.count;
		data->current_wanted = data->wanted_stack.items[wanted_index];
		/* 出題した分を取り除く */
		-- data->wanted_stack.count;
		for(int i = wanted_index; i < data->wanted_stack.count; ++i){
			data->wanted_stack.items[i] = data->wanted_stack.items[i + 1];
		}
	}
}

void init_data(data_t *data)
{
	for(hand_t hand = 0; hand < handNum; ++hand){
		for(int i = 0; i < keyNumOfHand; ++i){
			for(int j = 0; j < keyNumOfHand; ++j){
				data->items[hand][i][j].count = 0;
			}
		}
	}
	data->wanted_stack.count = 0;
	updateWanted(data);
}

key_pair_t wanted(data_t const *data)
{
	return data->current_wanted;
}

void add(data_t *data, key_pair_t seq, int32_t msec)
{
	hand_t hand = handOf(seq.first);
	if(hand == handOf(seq.second)){
		int firstIndex = (hand == handLeft) ? seq.first : seq.first - keyNumOfHand;
		int secondIndex = (hand == handLeft) ? seq.second : seq.second - keyNumOfHand;
		key_record_t *rec = &data->items[hand][firstIndex][secondIndex];
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
		updateWanted(data);
	}
}

int32_t msecOf(data_t const *data, key_pair_t seq)
{
	int32_t result = 0;
	hand_t hand = handOf(seq.first);
	if(hand == handOf(seq.second)){
		int firstIndex = (hand == handLeft) ? seq.first : seq.first - keyNumOfHand;
		int secondIndex = (hand == handLeft) ? seq.second : seq.second - keyNumOfHand;
		key_record_t const *rec = &data->items[hand][firstIndex][secondIndex];
		result = median(rec); /* 中央値 */
	}
	return result;
}

bool saveToFile(data_t *data, char const *filename)
{
	bool result = false;
	FILE *file = fopen(filename, "wb");
	if(file){
		for(hand_t hand = 0; hand < handNum; ++hand){
			for(int i = 0; i < keyNumOfHand; ++i){
				for(int j = 0; j < keyNumOfHand; ++j){
					key_record_t *rec = &data->items[hand][i][j];
					/* clear unused area */
					for(int k = rec->count; k < recordNum; ++k){
						rec->msec[k] = 0;
					}
					/* write */
					if(fwrite(rec->msec, sizeof(int32_t), recordNum, file) < recordNum) goto error;
				}
			}
		}
		result = true;
	error:
		if(fclose(file) < 0) result = false;
	}
	return result;
}

bool loadFromFile(data_t *data, char const *filename)
{
	bool result = false;
	FILE *file = fopen(filename, "rb");
	if(file){
		for(hand_t hand = 0; hand < handNum; ++hand){
			for(int i = 0; i < keyNumOfHand; ++i){
				for(int j = 0; j < keyNumOfHand; ++j){
					key_record_t *rec = &data->items[hand][i][j];
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
		result = true;
	error:
		if(fclose(file) < 0) result = false;
	}
	//問題差し替え
	if(result){
		data->wanted_stack.count = 0;
		updateWanted(data);
	}
	return result;
}
