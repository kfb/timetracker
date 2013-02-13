//
//  KFBEntry.h
//  TimeTracker
//
//  Created by KFB on 12/02/2013.
//  Copyright (c) 2013 KFB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KFBEntry : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * text;

@end
