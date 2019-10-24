//
//  WLNetWorkManger+Cache.h
//  WL_NetWorkManger
//
//  Created by Mac on 2019/10/22.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "WLNetWorkManger.h"

#import "Macrodefine.h"


// 何种网络任务
typedef NS_ENUM(NSInteger, WLNetTaskType) {
    WLNetworkCache, // 占位，代表最外层缓存文件夹
    WLRequst,
    WLUpload,
    WLDownload
};


@interface WLNetWorkManger (Cache)

#pragma mark - 缓存文件名

/**  --- DWL ---
 *   缓存文件夹下某次请求数据的缓存文件名，同时也是UserDefaulets中的key值
 *   @param urlString 请求地址
 *   @param params    请求参数
 *   @return 返回一个MD5加密后的字符串
 */
+ (NSString *)creatCacheKeyWithUrlString:(NSString *)urlString params:(id)params;

#pragma mark - 添加本地缓存

/**  --- DWL ---
 *   添加本地缓存
 *   @param responseObject 请求成功的数据
 *   @param cacheFileName 缓存文件名
 *   @return 是否添加成功
 */
+ (BOOL)addCacheDataWithCacheFileName:(NSString *)cacheFileName cacheData:(id)responseObject;

#pragma mark - 读取本地缓存

/**  --- DWL ---
 *   读取本地缓存内容
 *   @param cacheFileName 本地缓存文件名
 *   @return 本地缓存数据
 */
+ (id)readCacheDataWithCacheFileName:(NSString *)cacheFileName;

#pragma mark - 获取本地缓存大小

// 整个缓存文件夹的大小
+ (NSString *)cacheDirectorySize;

#pragma mark - 删除本地缓存

// 清空缓存（删除UserDefaults中的存放时间和地址的键值对，并删除缓存文件夹）
+ (void)clearNetCaches;

#pragma mark - 其他

/**  --- DWL ---
 *   方法说明: 网络缓存内容在本地的路径
 *   @parem taskType : 何种网络任务
 *   @return  网络任务对应的本地缓存路径
 */
+ (NSString *)cachesPathStringWithNetTaskType:(WLNetTaskType)taskType;

/**  --- DWL ---
 *   方法说明 : 某次网络请求时间与当前时间的差值
 *   @parem requestTime : 某次网络请求的时间
 *   @return  时间差(以分钟为单位)
 */
+ (NSString *)stringNowTimeDifferenceWithRequestTime:(NSDate *)requestTime;

/**  --- DWL ---
 *   方法说明 : 要保存在服务器上的[文件名]
 *   @parem fileSuffix : 文件后缀名
 *   @param index : for循环计数下标
 *   @return  当前时间命名的文件名
 */
+ (NSString *)currentTimeAsFileNameWithFileSuffix:(NSString *)fileSuffix index:(NSInteger)index;

@end

