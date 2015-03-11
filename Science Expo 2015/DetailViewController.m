//
//  DetailViewController.m
//  Science Expo 2015
//
//  Created by Timothy Roe Jr. on 2/21/15.
//  Copyright (c) 2015 Timothy Roe Jr. All rights reserved.
//

#import "DetailViewController.h"
#import "MBProgressHUD.h"

@interface DetailViewController ()

@property (nonatomic) BOOL accelerometerRunning;
@property (weak, nonatomic) IBOutlet UIButton *startAccelerometer;
@property (weak, nonatomic) IBOutlet UIButton *stopAccelerometer;
@property (weak, nonatomic) IBOutlet UIButton *startLog;
@property (weak, nonatomic) IBOutlet UIButton *stopLog;
@property (strong, nonatomic) NSArray *accelerometerDataArray;
@property (strong, nonatomic) UIView *grayScreen;
@property (strong, nonatomic) IBOutlet UISwitch *connectionSwitch;
@property (nonatomic) BOOL switchRunning;
@property (strong, nonatomic) IBOutlet UILabel *xLabel;
@property (strong, nonatomic) IBOutlet UILabel *yLabel;
@property (strong, nonatomic) IBOutlet UILabel *zLabel;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.grayScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height - 120)];
    self.grayScreen.backgroundColor = [UIColor grayColor];
    self.grayScreen.alpha = 0.4;
    [self.view addSubview:self.grayScreen];
    
    [self.stopAccelerometer setEnabled:NO];
    [self.stopLog setEnabled:NO];


}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.device addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [self connectDevice:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.device removeObserver:self forKeyPath:@"state"];
    if (self.accelerometerRunning) {
        [self stopRecordingData:nil];
    } if (self.switchRunning) {
        [self StopSwitchNotifyPressed:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)connectDevice:(BOOL)on {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (on) {
        hud.labelText = @"Connecting...";
        [self.device connectWithHandler:^(NSError *error) {
            [self setConnected:(error == nil)];
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                hud.labelText = @"Connected!";
                [hud hide:YES afterDelay:0.5];
            }
        }];
    } else {
        hud.labelText = @"Disconnecting...";
        [self.device disconnectWithHandler:^(NSError *error) {
            [self setConnected:NO];
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                hud.labelText = @"Disconnected!";
                [hud hide:YES];
            }
        }];
    }
}

-(IBAction)StopSwitchNotifyPressed:(id)sender {
    self.switchRunning = NO;
    [self.device.mechanicalSwitch.switchUpdateEvent stopNotifications];
}

-(void)setConnected:(BOOL)on {
    [self.connectionSwitch setOn:on animated:YES];
    [self.grayScreen setHidden:on];
    [self.device.led setLEDColor:[UIColor greenColor] withIntensity:0.50];
}

-(IBAction)startRecordingData:(id)sender {
    [self accelerometerSettings];
    
    [self.startLog setEnabled:NO];
    [self.stopLog setEnabled:YES];
    [self.startAccelerometer setEnabled:NO];
    [self.stopAccelerometer setEnabled:YES];
    self.accelerometerRunning = YES;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1000];
    self.accelerometerDataArray = array;
    
    [self.device.accelerometer.dataReadyEvent startNotificationsWithHandler:^(MBLAccelerometerData *acceleration, NSError *error) {
        NSString *xString = [NSString stringWithFormat:@"%d", acceleration.x/1000];
        NSString *yString = [NSString stringWithFormat:@"%d", acceleration.y/1000];
        NSString *zString = [NSString stringWithFormat:@"%d", acceleration.z/1000];
        [self.xLabel setText:xString];
        [self.yLabel setText:yString];
        [self.zLabel setText:zString];
        
    }];
    
    [self.device.accelerometer.dataReadyEvent startLogging];
}

-(IBAction)stopRecordingData:(id)sender {
    self.accelerometerRunning = NO;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.labelText = @"Downloading...";
    [self.device.accelerometer.dataReadyEvent downloadLogAndStopLogging:YES handler:^(NSArray *array, NSError *error) {
        [hud hide:YES];
        if (!error) {
            self.accelerometerDataArray = array;
            [self data];
        }
    } progressHandler:^(float number, NSError *error) {
        hud.progress = number;
    }];
    [self.startAccelerometer setEnabled:YES];
    [self.stopAccelerometer setEnabled:NO];
    [self.startLog setEnabled:YES];
    
    
}

-(void)data {
    NSMutableData *accelerometerData = [NSMutableData data];
    for (MBLAccelerometerData *dataElement in self.accelerometerDataArray) {
        @autoreleasepool {
            [accelerometerData appendData:[[NSString stringWithFormat:@"%f, %d, %d, %d\n", dataElement.timestamp.timeIntervalSince1970, dataElement.x/1000, dataElement.y/1000,dataElement.z/1000] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    [self sendMail:accelerometerData];
}

- (void)sendMail:(NSData *)attachment
{
    if (![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:@"Mail Error" message:@"This device does not have an email account setup" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    
    // Get current Time/Date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    // Some filesystems hate colons
    NSString *dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    // I hate spaces in dates
    dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    // OS hates forward slashes
    dateString = [dateString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
    emailController.mailComposeDelegate = self;
    
    // attachment
    NSString *name = [NSString stringWithFormat:@"AccData_%@.txt", dateString, nil];
    [emailController addAttachmentData:attachment mimeType:@"text/plain" fileName:name];
    
    // subject
    NSString *subject = [NSString stringWithFormat:@"Accelerometer Data %@.txt", dateString, nil];
    [emailController setSubject:subject];
    
    NSMutableString *body = [[NSMutableString alloc] initWithFormat:@"The data was recorded on %@.\n", dateString];
    [emailController setMessageBody:body isHTML:NO];
    
    [self presentViewController:emailController animated:YES completion:NULL];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)connectionSwitchPressed:(id)sender
{
    [self connectDevice:self.connectionSwitch.on];
}

-(void)accelerometerSettings {
    self.device.accelerometer.sampleFrequency = 50;
    self.device.accelerometer.filterCutoffFreq = 3;
    self.device.accelerometer.highPassFilter = YES;
}

@end
