//
//  NetTestVC.m
//  WL_NetWorkManger
//
//  Created by Mac on 2019/5/21.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "NetTestVC.h"
#import "WLNetWorkManger.h"

@interface NetTestVC ()

@end

@implementation NetTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor redColor];

    //点进去立刻返回，VC释放，触发request网络请求终止；由于download使用了延迟，导致任务的开启在VC释放之后，因此WLNetWorkManger收不到cancel消息，会继续执行下载
    NSString *questUrl = @"http://sao.cnki.net/TYApp_Test/Visualization/SubjectOfTenYear.ashx";
    [[WLNetWorkManger shareInstance] requestWithType:WLRequestPost urlString:questUrl parameters:@{@"mid":@"gylt"} cacheTime:0.5 success:^(id responceData) {

    } failure:^(NSError *error) {

    }];

    //为了方便分别查看request和download的log信息，使用了延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        NSString *downUrl = @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=2700376359,383693142&fm=26&gp=0.jpg";
        [[WLNetWorkManger shareInstance] downloadWithUrlString:downUrl parameters:nil progress:^(NSString *percent) {

        } success:^(id responceData) {
            NSLog(@"%@", [WLNetWorkManger cacheDirectorySize]);
            [WLNetWorkManger clearNetCaches];
            NSLog(@"%@", [WLNetWorkManger cacheDirectorySize]);
        } failure:^(NSError *error) {

        }];
    });
}

-(void)dealloc
{
    NSLog(@"子类 dealloc");
}


@end
