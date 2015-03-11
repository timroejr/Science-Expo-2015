//
//  DetailViewController.h
//  Science Expo 2015
//
//  Created by Timothy Roe Jr. on 2/21/15.
//  Copyright (c) 2015 Timothy Roe Jr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetaWear/MetaWear.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) MBLMetaWear *device;

@end

