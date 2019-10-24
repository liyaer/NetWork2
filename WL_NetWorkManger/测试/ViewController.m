//
//  ViewController.m
//  WL_NetWorkManger
//
//  Created by Mac on 2019/5/16.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "ViewController.h"
#import "NetTestVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
}

-(void)tapAction
{
    [self.navigationController pushViewController:[NetTestVC new] animated:YES];
}

@end
