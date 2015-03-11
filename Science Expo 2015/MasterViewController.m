//
//  MasterViewController.m
//  Science Expo 2015
//
//  Created by Timothy Roe Jr. on 2/21/15.
//  Copyright (c) 2015 Timothy Roe Jr. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import <MetaWear/MetaWear.h>

@interface MasterViewController ()

@property (nonatomic, strong) NSArray *devices;
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UISwitch *scanningSwitch;


@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activity.center = CGPointMake(95, 138);
    [self.tableView addSubview:self.activity];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setScanning:self.scanningSwitch.on];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setScanning:NO];
}


-(void)setScanning:(BOOL)on {
    if (on) {
        [self.activity startAnimating];
        [[MBLMetaWearManager sharedManager] startScanForMetaWearsAllowDuplicates:YES handler:^(NSArray *array) {
            self.devices = array;
            [self.tableView reloadData];
        }];
    } else {
        [self.activity stopAnimating];
        [[MBLMetaWearManager sharedManager] stopScanForMetaWears];
    }
}

-(IBAction)scanningSwitchPressed:(UISwitch *)sender {
    [self setScanning:sender.on];
}


#pragma mark - Segues


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    MBLMetaWear *cur = self.devices[indexPath.row];
    
    UILabel *uuid = (UILabel *)[cell viewWithTag:2];
    uuid.text = cur.identifier.UUIDString;
    
    UILabel *connected = (UILabel *)[cell viewWithTag:3];
    if (cur.state == CBPeripheralStateConnected) {
        [connected setHidden:NO];
    } else {
        [connected setHidden:YES];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    MBLMetaWear *selected = self.devices[indexPath.row];
    [self performSegueWithIdentifier:@"DeviceDetails" sender:selected];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Devices";
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailViewController *destination = segue.destinationViewController;
    destination.device = sender;
}


@end
