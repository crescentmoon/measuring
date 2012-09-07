//
//  TheField.m
//  measuring
//
//  Created by crescentmoon on 12/09/07.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TheField.h"


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
	char s[3];
	s[0] = charOfKey(pair.first);
	s[1] = charOfKey(pair.second);
	s[2] = '\0';
	NSString *sobj = [[NSString alloc] initWithUTF8String:s];
	[guide setStringValue:sobj];
	[sobj release];
}

- (void)drawRect:(NSRect)dirtyRect {
	// Drawing code here.

	NSRect bounds = [self bounds];
	
	[[NSColor whiteColor] set];
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
	if(firstTime == nil && key == wanted.first){
		NSLog(@"first");
		//入力文字
		char s[2];
		s[0] = charOfKey(key);
		s[1] = '\0';
		[inputed release];
		inputed = [[NSString alloc] initWithUTF8String:s];
		//時間
		firstTime = [NSDate date];
		[firstTime retain];
		//再描画
		[self setNeedsDisplay:YES];
	}else if(firstTime != nil && key == wanted.second){
		NSLog(@"second");
		NSDate *secondTime = [NSDate date];
		NSTimeInterval interval = [secondTime timeIntervalSinceDate:firstTime];
		int32_t msec = (int32_t)(interval * 1000.0);
		[data add:wanted mesc:msec];
		//完成
		char s[3];
		s[0] = charOfKey(wanted.first);
		s[1] = charOfKey(wanted.second);
		s[2] = '\0';
		[inputed release];
		inputed = [[NSString alloc] initWithUTF8String:s];
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
	key_t key = keyOfChar(toupper(img[0]));
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
		[self handeKeyDown:12]; /* CAPS LOCK */
	}
	if ((flags & NSShiftKeyMask) == NSShiftKeyMask) {
		if(flags & 2){
			[self handeKeyDown:18]; /* 左シフト */
		}else if(flags & 4){
			[self handeKeyDown:(keyNumOfHand + 23)]; /* 右シフト */
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
		//問題差し替え
		[data regenerateWanted];
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
