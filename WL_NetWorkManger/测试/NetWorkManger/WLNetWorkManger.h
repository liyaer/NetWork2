//
//  checkNet.h
//  WeChatMaker
//
//  Created by 杜文亮 on 2017/9/6.
//  Copyright © 2017年 CompanyName（公司名）. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WLMediaModel.h"


// 网络监测
typedef void (^WLLaunchNetResult)(void);
// 接口
typedef void (^WLSuccess)(id responceData);
typedef void (^WLFailure)(NSError *error);
typedef void (^WLProgress)(NSString *percent);
// 请求方式
typedef NS_ENUM(NSInteger, WLNetWorkRequestType) {
    WLRequestPost,
    WLRequestGet
};


@interface WLNetWorkManger : NSObject<NSCopying,NSMutableCopying>

// 单例初始化
+ (instancetype)shareInstance;

#pragma mark - 网络监测

//每次启动时，在AppDelegate中先开启了网络监测，然后执行了检查是否有新版的代码。但是由于网络监测的block回调慢于检查更新代码的执行，导致在执行检查更新的时候，hasNet还未被赋值，此时是默认值NO(导致即使是联网状态下hasNet为NO)。为了解决上述问题，设置一个block，在网络监测完成时（hasNet已经被赋值），再执行检查新版本这部分代码
@property (nonatomic,copy) WLLaunchNetResult launchNetResult;

// 当前是否有网络链接
@property (nonatomic,assign) NSInteger networkStatus;

/*
 *   说明：1，2为实时监测；3仅仅是一个判断当前网络的方法，无法实时监测
 *        1，2使用时在APP启动时调用一次即可，之后可用networkStatus判断；3每次使用前需要调用
 */

// 1 - 苹果自带的Reachability检测网络状态(封装的这个通知会调用多次，不知为何？)
- (void)startCheckNetLinkByReachability;

// 2 - AFNetworkReachabilityManager（最省事，一般都是用AF进行网络请求）
- (void)startCheckNetLinkByReachabilityManger;

// 3 - 根据当前状态栏的显示判断网络状态（当然，此方法存在一定的局限性，比如当状态栏被隐藏的时候，无法使用此方法）
- (NSString *)statusBarShowNet;

#pragma mark - 接口

/**  --- DWL ---
 *   方法说明 : 网络请求的封装（含缓存机制）
 *   @parem cacheTime : 0不缓存；!0开启缓存（时间单位是分钟）
 */
- (void)requestWithType:(WLNetWorkRequestType)requestType urlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)cacheTime success:(WLSuccess)success failure:(WLFailure)failure;

/**  --- DWL ---
 *   方法说明 : 上传文件（另一种说法叫表单提交）
 *   @parem mediaArray : 将待上传的资源（图片、音频、视频、文字）统一用WLMediaModel包装，装进数组中
 */
- (void)uploadWithUrlString:(NSString *)urlString parameters:(id)parameters mediaArray:(NSArray <WLMediaModel *>*)mediaArray progress:(WLProgress)progress success:(WLSuccess)success failure:(WLFailure)failure;

// 下载
- (void)downloadWithUrlString:(NSString *)urlString parameters:(id)parameters progress:(WLProgress)progress success:(WLSuccess)success failure:(WLFailure)failure;

// 取消请求
- (void)cancelRequest;

#pragma mark - 删除本地缓存

//缓存功能使用分类 WLNetWorkManger+Cache 实现，目的是将功能分离开来（当然你也可以再定义一个类来实现缓存功能，但是不能利用分类的特点来实现下面两个方法的调用了）。
//这里设计思路是，分类只对 WLNetWorkManger 暴露，不对外界暴露（意思是在 WLNetWorkManger.m 引用头文件）
//利用分类方法优先级高的特性，在这里只进行方法声明即可，会自动调用分类的实现

// 整个缓存文件夹的大小
+ (NSString *)cacheDirectorySize;

// 清空缓存（删除UserDefaults中的存放时间和地址的键值对，并删除缓存文件夹）
+ (void)clearNetCaches;



//检查是否有新版本
-(void)postGetAppInfo:(NSString *)url sucess:(WLSuccess)sucess fail:(WLFailure)fail;

@end


