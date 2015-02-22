//
//  DetailViewController.h
//  Science Expo 2015
//
//  Created by Timothy Roe Jr. on 2/21/15.
//  Copyright (c) 2015 Timothy Roe Jr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

