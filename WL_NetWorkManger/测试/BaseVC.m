//
//  BaseVC.m
//  WL_NetWorkManger
//
//  Created by Mac on 2019/5/21.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "BaseVC.h"
#import "WLNetWorkManger.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"父类 viewDidLoad");
}

-(void)dealloc
{
    NSLog(@"父类 dealloc");
    
    [[WLNetWorkManger shareInstance] cancelRequest];
}

@end
