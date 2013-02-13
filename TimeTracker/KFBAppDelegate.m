//
//  KFBAppDelegate.m
//  TimeTracker
//
//  Created by KFB on 12/02/2013.
//  Copyright (c) 2013 KFB. All rights reserved.
//

#import "KFBAppDelegate.h"

@implementation KFBAppDelegate

- (void)dealloc
{
    [_persistentStoreCoordinator release];
    [_managedObjectModel release];
    [_managedObjectContext release];
    [super dealloc];
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)awakeFromNib
{
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    
    if (_statusItem == nil)
    {
        NSLog(@"Couldn't create statusItem!");
        
        [NSApp terminate:nil];
    }
    else
    {
        NSString *iconPath  = [[NSBundle mainBundle] pathForResource:@"clock" ofType:@"icns"];
        NSImage  *iconImage = [[[NSImage alloc] initWithContentsOfFile:iconPath] autorelease];
        
        [iconImage setSize:NSMakeSize(18, 18)];
        
        [_statusItem setImage:iconImage];
        [_statusItem setHighlightMode:YES];
        [_statusItem setMenu:_statusMenu];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DDHotKeyCenter *hotKeyCenter = [[[DDHotKeyCenter alloc] init] autorelease];
    
    [hotKeyCenter registerHotKeyWithKeyCode:17 modifierFlags:NSShiftKeyMask|NSCommandKeyMask task:^(NSEvent *event) {
        [self showPanel:nil];
    }];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.kfb.TimeTracker" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.kfb.TimeTracker"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TimeTracker" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"TimeTracker.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = [coordinator retain];
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (IBAction)showMainWindow:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction)showPanel:(id)sender
{
    [[self entryPanel] makeKeyAndOrderFront:nil];
}

- (IBAction)hidePanel:(id)sender
{
    [[self entryPanel] orderOut:nil];
}

- (IBAction)addEntry:(id)sender
{
    // Append a new object into the table
    NSDate *date = [NSDate date];

    KFBEntry *entry = [NSEntityDescription insertNewObjectForEntityForName:@"KFBEntry"
                                                    inManagedObjectContext:[self managedObjectContext]];

    [entry setTimestamp:date];
    [entry setText:[[self entryText] stringValue]];
    
    [self hidePanel:sender];
}

- (IBAction)exportData:(id)sender
{
    // Display the save panel
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];
            
//            NSLog(@"Saving to %@", [savePanel URL]);
            
            NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"KFBEntry" inManagedObjectContext:[self managedObjectContext]];
            NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES] autorelease];
            
            [fetchRequest setEntity:entity];
            [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            NSError *error;
            NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
            
            [[NSData data] writeToURL:[savePanel URL] options:0 error:&error];
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingURL:[savePanel URL] error:&error];
            
            for (KFBEntry *entry in fetchedObjects)
            {
                NSString *string = [NSString stringWithFormat:@"%@: %@\n", entry.timestamp, entry.text];
                NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:data];
                
//                NSLog(@"Wrote '%@' to %@", string, [savePanel URL]);
            }
        }
    }];
}

@end