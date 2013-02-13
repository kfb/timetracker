//
//  KFBAppDelegate.h
//  TimeTracker
//
//  Created by KFB on 12/02/2013.
//  Copyright (c) 2013 KFB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DDHotKey/DDHotKeyCenter.h"
#import "KFBEntry.h"

@interface KFBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSMenu *statusMenu;
@property (retain) IBOutlet NSStatusItem *statusItem;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPanel  *entryPanel;
@property (assign) IBOutlet NSButton *addButton;
@property (assign) IBOutlet NSButton *enterButton;

@property (assign) IBOutlet NSTextField *entryText;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)showPanel:(id)sender;

- (IBAction)exportData:(id)sender;

@end
