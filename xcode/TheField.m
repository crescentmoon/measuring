//
//  TheField.m
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TheField.h"

static NSString *longFormOf (char c)
{
	NSString *result;
	char s[2];
	switch(c){
		case 't':
			result = @"<tab>";
			break;
		case 'c':
			result = @"<caps lock>";
			break;
		case 'l':
			result = @"<left shift>";
			break;
		case 'r':
			result = @"<right shift>";
			break;
		default:
			s[0] = c;
			s[1] = '\0';
				result = [[NSString alloc] initWithUTF8String:s];
			[result autorelease];
	}
	return result;
}

static NSString *longFormOf2 (char c1, char c2)
{
	NSString *s1 = longFormOf(c1);
	NSString *s2 = longFormOf(c2);
	NSString *result;
	if(islower(c1) || islower(c2)){
		result = [[s1 stringByAppendingString:@" "] stringByAppendingString:s2];
	}else{
		result = [s1 stringByAppendingString:s2];
	}
	return result;
}

@implementation TheField

@synthesize data;
@synthesize inputed;

@synthesize guide;
@synthesize leftDataSource;
@synthesize rightDataSource;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		 NSLog(@"Custom View Initialized");
		 
		 inputed = [[NSString alloc] initWithString:@""];
		 firstTime = nil;
		 
		 prevCapsLock = false;
		 tableInitialized = false;
		 
		 filename = nil;
    }
    return self;
}

- (void)dealloc
{
	[inputed release];
	[firstTime release];
	[super dealloc];
}

- (void)readyMeasuring
{
	//テーブル初期化
	if(!tableInitialized){
		tableInitialized = true;
		[leftDataSource setup:data hand:handLeft];
		[rightDataSource setup:data hand:handRight];
		//ついでにフォント設定
		[guide setFont:[NSFont fontWithName:@"Monaco" size:16]];
	}
	//測定の準備をする
	key_pair_t pair = [data wanted];
	NSString *sobj = longFormOf2(charOfKey(pair.first), charOfKey(pair.second));
	[guide setStringValue:sobj];
}

- (void)drawRect:(NSRect)dirtyRect {
	// Drawing code here.

	NSRect bounds = [self bounds];
	
	if ([data is_fixing_mode]){
		[[NSColor colorWithCalibratedRed:1.0 green:0.8 blue:0.8 alpha:1.0] set];
	}else{
		[[NSColor whiteColor] set];
	}
	[NSBezierPath fillRect:bounds];
	
	[[NSColor blackColor] set];
	
	NSRect innerBounds = bounds;
	innerBounds.origin.x += 10.0;
	innerBounds.size.height -= 10.0;
	
	[inputed drawInRect:innerBounds withAttributes:nil];
	
	if([[self window] firstResponder] == self){
		[[NSColor keyboardFocusIndicatorColor] set];
		[NSBezierPath setDefaultLineWidth:4.0];
		[NSBezierPath strokeRect:bounds];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	[self readyMeasuring];
	return YES;
}

- (void)handeKeyDown:(key_t) key
{
	key_pair_t wanted = [data wanted];
	if(firstTime != nil && key == wanted.second){
		NSLog(@"second");
		NSDate *secondTime = [NSDate date];
		NSTimeInterval interval = [secondTime timeIntervalSinceDate:firstTime];
		int32_t msec = (int32_t)(interval * 1000.0);
		[data add:wanted mesc:msec];
		//完成
		[inputed release];
		inputed = longFormOf2(charOfKey(wanted.first), charOfKey(wanted.second));
		[inputed retain];
		//時間クリア
		[firstTime release];
		firstTime = nil;
		//次の問題
		[self readyMeasuring];
		//再描画
		[self setNeedsDisplay:YES];
		if(handOf(wanted.second) == handLeft){
			[leftDataSource setNeedsDisplay:YES];
		}else{
			[rightDataSource setNeedsDisplay:YES];
		}
	}else if(key == wanted.first){
		NSLog(@"first");
		//入力文字
		[inputed release];
		inputed = longFormOf(charOfKey(key));
		[inputed retain];
		//時間
		[firstTime release];
		firstTime = [NSDate date];
		[firstTime retain];
		//再描画
		[self setNeedsDisplay:YES];
	}else{
		[inputed release];
		inputed = [[NSString alloc] initWithString:@""];
		[firstTime release];
		firstTime = nil;
		//再描画
		[self setNeedsDisplay:YES];
	}
}

- (void)keyDown:(NSEvent *)event
{
	NSString *s = [event charactersIgnoringModifiers];
	char const *img = [s UTF8String];
	key_t key;
	if(img[0] == '\t'){
		key = keyTab;
	}else{
		key = keyOfChar(toupper(img[0]));
	}
	if(key >= 0){
		[self handeKeyDown:key];
	}
}

- (void)flagsChanged:(NSEvent *)event
{
	NSEventMask flags = [event modifierFlags];
	NSLog(@"%x", flags);
	if (((flags & NSAlphaShiftKeyMask) == NSAlphaShiftKeyMask) != prevCapsLock) {
		prevCapsLock = !prevCapsLock;
		[self handeKeyDown:keyCapsLock]; /* CAPS LOCK */
	}
	if ((flags & NSShiftKeyMask) == NSShiftKeyMask) {
		if(flags & 2){
			[self handeKeyDown:keyLeftShift]; /* 左シフト */
		}else if(flags & 4){
			[self handeKeyDown:keyRightShift]; /* 右シフト */
		}
	}
}


- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"alert end");
}

- (void)loadFromFile:(NSURL *)the_filename
{
	if([data loadFromFile:the_filename]){
		//成功したのでファイル名を置き換え
		NSURL *old_filename = filename;
		filename = the_filename;
		[filename retain];
		[old_filename release];
		//問題も差し替えられているはず
		[self readyMeasuring];
		//再描画
		[self setNeedsDisplay:YES];
		[leftDataSource setNeedsDisplay:YES];
		[rightDataSource setNeedsDisplay:YES];
	}else{
		NSAlert *panel = [NSAlert alertWithMessageText:@"error!"
			defaultButton:@"OK"
			alternateButton:nil
			otherButton:nil
			informativeTextWithFormat:@"%@",[the_filename path]];
		[panel beginSheetModalForWindow:[self window]
			modalDelegate:self
			didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
			contextInfo:NULL];
	}
	[the_filename release]; //magic-1
}

- (void)saveToFile:(NSURL *)the_filename
{
	if([data saveToFile:the_filename]){
		//成功したのでファイル名を置き換え
		NSURL *old_filename = filename;
		filename = the_filename;
		[filename retain];
		[old_filename release];
	}else{
		NSAlert *panel = [NSAlert alertWithMessageText:@"error!"
			defaultButton:@"OK"
			alternateButton:nil
			otherButton:nil
			informativeTextWithFormat:@"%@",[the_filename path]];
		[panel beginSheetModalForWindow:[self window]
			modalDelegate:self
			didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
			contextInfo:NULL];
	}
	[the_filename release]; //magic-1
}

- (IBAction)openDocument:(id)sender
{
	NSLog(@"load");
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
      if (result == NSFileHandlingPanelOKButton) {
         NSArray *urls = [panel URLs];
         // Use the URLs to build a list of items to import.
			NSURL *url = [urls objectAtIndex:0];
			NSLog(@"%@", url);
			[url retain]; //magic+1
			//開くダイアログが完全に終了してから処理するように
			[self performSelector:@selector(loadFromFile:) withObject:url afterDelay:0.0];
      }
	}];
}

- (IBAction)saveDocument:(id)sender;
{
	NSLog(@"save");
	if(filename == nil){
		[self saveDocumentAs:sender];
	}else{
		[filename retain]; //magic+1
		[self saveToFile:filename];
	}
}

- (IBAction)saveDocumentAs:(id)sender;
{
	NSLog(@"save as");
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setCanSelectHiddenExtension:YES];
	if(filename){
		[panel setDirectoryURL:[filename baseURL]];
		[panel setNameFieldStringValue:[[filename path] lastPathComponent]];
	}
	[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
		if (result == NSFileHandlingPanelOKButton)
		{
			NSURL *url = [panel URL];
			// Write the contents in the new format.
			NSLog(@"%@", url);
			[url retain]; //magic+1
			//保存ダイアログが完全に終了してから処理するように
			[self performSelector:@selector(saveToFile:) withObject:url afterDelay:0.0];
		}
	}];
}

@end
