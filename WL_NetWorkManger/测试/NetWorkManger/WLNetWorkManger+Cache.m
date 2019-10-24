//
//  WLNetWorkManger+Cache.m
//  WL_NetWorkManger
//
//  Created by Mac on 2019/10/22.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import "WLNetWorkManger+Cache.h"

#import <CommonCrypto/CommonDigest.h>


@implementation WLNetWorkManger (Cache)

#pragma mark - 缓存文件名

+ (NSString *)creatCacheKeyWithUrlString:(NSString *)urlString params:(id)params {
    NSString *md5Key;
    NSString *absoluteURL = [self generateGETAbsoluteURL:urlString params:params];
    if (absoluteURL.length > 0) {
        md5Key = [self networkingUrlString_md5:absoluteURL];
    }
    return md5Key;
}

/**  --- DWL ---
 *   生成Get请求方式的完整URL（仅对一级字典结构起作用）
 *   @return url和params拼接后的完整URL
 */
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(NSDictionary *)params {
    NSString *queries = @"";
    
    //参数合法性检查
    if ([url isKindOfClass:[NSString class]] && ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"])) {
        if ([params isKindOfClass:[NSDictionary class]] && [params count] != 0) {
            //字典key、value拼接
            for (NSString *key in params) {
                id value = [params objectForKey:key];
                
                if ([value isKindOfClass:[NSDictionary class]]) {
                    continue;
                } else if ([value isKindOfClass:[NSArray class]]) {
                    continue;
                } else if ([value isKindOfClass:[NSSet class]]) {
                    continue;
                } else {
                    queries = [NSString stringWithFormat:@"%@%@=%@&",/* (queries.length == 0 ? @"&" : queries) */queries,key,value];
                }
            }
            //去掉最后的&(实际测试，开头和结尾有&也不影响，但是为了标准，还是都去掉，上面局部注释是去除开头&)
            if (queries.length > 1) {
                queries = [queries substringToIndex:queries.length - 1];
            }
            
            //和URL拼接
            if (queries.length > 1) {
                if ([url rangeOfString:@"?"].location != NSNotFound || [url rangeOfString:@"#"].location != NSNotFound){
                    url = [NSString stringWithFormat:@"%@%@", url, queries];
                } else {
                    url = [NSString stringWithFormat:@"%@?%@", url, queries];
                }
            }
        } else {
            return url;
        }
    }
    
    return queries.length == 0 ? queries : url;
}

/**  --- DWL ---
 *   MD5加密
 *   @param string 要加密的字符串
 *   @return 加密后的字符串
 */
+ (NSString *)networkingUrlString_md5:(NSString *)string {
    if (string == nil || ![string isKindOfClass:[NSString class]] || [string length] == 0 ) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    
    NSMutableString *ms = [NSMutableString string];
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    return [ms copy];
}

#pragma mark - 添加本地缓存

+ (BOOL)addCacheDataWithCacheFileName:(NSString *)cacheFileName cacheData:(id)responseObject {
    if (responseObject) {
        if (cacheFileName.length > 0) {
            NSString *path = [[self cachesPathStringWithNetTaskType:WLRequst] stringByAppendingPathComponent:cacheFileName];
            //不删除旧的缓存文件也可以，写文件会直接覆盖
//            [self deleteFileWithPath:path];
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:responseObject attributes:nil];
            if (isOk) {
                WLLog(@"add cache file success: %@\n", path);
                return YES;
            } else {
                WLLog(@"add cache file error: %@\n", path);
            }
        }
    }
    return NO;
}

/**  --- DWL ---
 *   判断文件是否已经存在，若存在删除
 *   @parem path 文件路径
 *   @return 是否删除成功
 */
+ (BOOL)deleteFileWithPath:(NSString *)path {
    //入参检查
    if (![path isKindOfClass:[NSString class]] || path.length == 0) {
        WLLog(@"传入的待删除文件地址无效！");
        return NO;
    }
    
    //文件删除
    NSError *err;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&err];
        if (err) {
            WLLog(@"file remove error, %@", err.localizedDescription);
        } else {
            WLLog(@"file remove success");
            return YES;
        }
    } else {
        WLLog(@"no file by that name");
    }
    return NO;
}

#pragma mark - 读取本地缓存

+ (id)readCacheDataWithCacheFileName:(NSString *)cacheFileName {
    id cacheData = nil;
    if (cacheFileName.length > 0) {
        NSString *path = [[self cachesPathStringWithNetTaskType:WLRequst] stringByAppendingPathComponent:cacheFileName];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
        }
    }
    return cacheData;
}

#pragma mark - 获取本地缓存大小

+ (NSString *)cacheDirectorySize {
    unsigned long long cacheSize = [self cacheDataSizeWithNetTaskType:WLRequst] + [self cacheDataSizeWithNetTaskType:WLUpload] + [self cacheDataSizeWithNetTaskType:WLDownload];
    return [self calculateFileSizeInUnit:cacheSize];
}

// 遍历文件夹获得文件夹大小，返回多少KB
+ (unsigned long long)cacheDataSizeWithNetTaskType:(WLNetTaskType)taskType {
    if (taskType != WLNetworkCache) {
        NSString *folderPath = [self cachesPathStringWithNetTaskType:taskType];
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:folderPath]) return 0;
        NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
        NSString *fileName;
        long long folderSize = 0;
        while ((fileName = [childFilesEnumerator nextObject]) != nil) {
            NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            folderSize += [self fileSizeAtPath:fileAbsolutePath];
        }
        return folderSize;
    }
    
    WLLog(@"已知缓存文件夹层级结构，该计算方式不可传入WLNetworkCache参数");
    return 0.0;
}

// 单个文件的大小
+ (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

// 单位
+ (NSString *)calculateFileSizeInUnit:(unsigned long long)contentLength {
    if(contentLength >= pow(1024, 3))
        return [NSString stringWithFormat:@"%.2fGB", (float) (contentLength / (float)pow(1024, 3))];
    else if(contentLength >= pow(1024, 2))
        return [NSString stringWithFormat:@"%.2fMB", (float) (contentLength / (float)pow(1024, 2))];
    else if(contentLength >= 1024)
        return [NSString stringWithFormat:@"%.2fKB", (float) (contentLength / (float)1024)];
    else
        return [NSString stringWithFormat:@"%.2fB", (float) (contentLength)];
}

#pragma mark - 删除本地缓存

+ (void)clearNetCaches {
    NSFileManager *manager = [NSFileManager defaultManager];
    // 删除键值对
    NSString *requestPath = [self cachesPathStringWithNetTaskType:WLRequst];
    if ([manager fileExistsAtPath:requestPath]) {
        NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:requestPath] objectEnumerator];
        NSString *key;
        while ((key = [childFilesEnumerator nextObject]) != nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            WLLog(@"remove_cache_key == %@",key);
        }
    }
    
    // 删除缓存文件夹
    NSString *cachePath = [self cachesPathStringWithNetTaskType:WLNetworkCache];
    if ([manager fileExistsAtPath:cachePath isDirectory:nil]) {
        NSError *error = nil;
        [manager removeItemAtPath:cachePath error:&error];
        if (error) {
            WLLog(@"clear caches error: %@", error);
        } else {
            WLLog(@"clear caches success");
        }
    }
}

#pragma mark - 其他

+ (NSString *)cachesPathStringWithNetTaskType:(WLNetTaskType)taskType {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath;
    switch (taskType) {
        case WLRequst:
            createPath = [cachesPath stringByAppendingPathComponent:@"NetworkCache/Request"];
            break;
        case WLUpload:
            createPath = [cachesPath stringByAppendingPathComponent:@"NetworkCache/Upload"];
            break;
        case WLDownload:
            createPath = [cachesPath stringByAppendingPathComponent:@"NetworkCache/Download"];
            break;
        default:
            createPath = [cachesPath stringByAppendingPathComponent:@"NetworkCache"];
            break;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return createPath;
}

+ (NSString *)stringNowTimeDifferenceWithRequestTime:(NSDate *)requestTime {
    if (!requestTime || ![requestTime isKindOfClass:[NSDate class]]) {
        return nil;
    }
    
    long dd = (long)[[NSDate date] timeIntervalSince1970] - [requestTime timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%.2f", dd/60.0];
    WLLog(@"%@分钟前",timeString);
    return timeString;
}

+ (NSString *)currentTimeAsFileNameWithFileSuffix:(NSString *)fileSuffix index:(NSInteger)index {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@%ld.%@", str,index,fileSuffix];
}

@end
