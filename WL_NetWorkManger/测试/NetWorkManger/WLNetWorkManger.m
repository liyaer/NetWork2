//
//  checkNet.m
//  WeChatMaker
//
//  Created by 杜文亮 on 2017/9/6.
//  Copyright © 2017年 CompanyName（公司名）. All rights reserved.
//

#import "WLNetWorkManger.h"

#import "Reachability.h"
#import "AFNetworking.h"
#import "WLNetWorkManger+Cache.h"


static WLNetWorkManger *_instance;
static inline void NetworkActivityIndicatorVisible(BOOL isShow) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = isShow;
}


@interface WLNetWorkManger ()

// 网络监测
@property (nonatomic,strong) Reachability *reachability;
@property (nonatomic,strong) AFNetworkReachabilityManager *ReachabilityManager;

// 网络请求
@property (nonatomic,strong) AFHTTPSessionManager *sessionManger;
@property (nonatomic,strong) AFSecurityPolicy *securityPolicy;

@end


@implementation WLNetWorkManger

#pragma mark - 指定初始化方法

+ (instancetype)shareInstance {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    
    // 由于alloc方法内部会调用allocWithZone: 所以我们只需要保证在该方法只创建一个对象即可
    dispatch_once(&onceToken,^{
        
        // 只执行1次的代码(这里面默认是线程安全的)
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

#pragma mark - 网络监测
#pragma mark -- 1，苹果自带的Reachability检测网络状态 --

- (void)startCheckNetLinkByReachability {
    [self.reachability startNotifier];
}

- (Reachability *)reachability {
    if (!_reachability) {
        // 监听网络状态改变的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
        
        _reachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    }
    return _reachability;
}

- (void)networkStateChange {
    self.networkStatus = [self.reachability currentReachabilityStatus];
    switch(self.networkStatus) {
        case NotReachable:
            WLLog(@"没网");
            break;
        case ReachableViaWWAN:
            WLLog(@"移动网络");
            break;
        case ReachableViaWiFi:
            WLLog(@"WIFI");
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark -- 2，AFNetworkReachabilityManager --

- (void)startCheckNetLinkByReachabilityManger {
    [self.ReachabilityManager startMonitoring];
}

- (AFNetworkReachabilityManager *)ReachabilityManager {
    if (!_ReachabilityManager) {
        // 1.获得网络监控的管理者
        _ReachabilityManager = [AFNetworkReachabilityManager sharedManager];
        // 2.设置网络状态改变后的处理
        __weak typeof(self) weakSelf = self;
        // 当网络状态改变了, 就会调用这个block
        [_ReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
             weakSelf.networkStatus = status;
             switch (status) {
                 case AFNetworkReachabilityStatusUnknown: // 未知网络
                     NSLog(@"Unknown Net");
                     break;
                 case AFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
                     NSLog(@"NotReachable Net");
                     break;
                 case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                     NSLog(@"WAN Net");
                     break;
                 case AFNetworkReachabilityStatusReachableViaWiFi: // WIFI
                     NSLog(@"WiFi Net");
                     break;
             }
             
             //在网络监测完成时（hasNet已经被赋值），再执行检查新版本这部分代码
             if (weakSelf.launchNetResult) {
                 weakSelf.launchNetResult();
             }
         }];
    }
    return _ReachabilityManager;
}

#pragma mark -- 3，根据当前状态栏的显示判断网络状态（当然，此方法存在一定的局限性，比如当状态栏被隐藏的时候，无法使用此方法）--

- (NSString *)statusBarShowNet {
    // 状态栏是由当前app控制的，首先获取当前app
    UIApplication *app = [UIApplication sharedApplication];
    
    //私有属性，有被拒的风险
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    
    int type = 0;
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
        }
    }
    switch (type) {
        case 1: return @"2G";
            break;
            
        case 2: return @"3G";
            break;
            
        case 3: return @"4G";
            break;
            
        case 5: return @"WIFI";
            break;
            
        default: return @"NO-WIFI";//代表未知网络
            break;
    }
}

#pragma mark - 接口

- (AFHTTPSessionManager *)sessionManger {
    if (!_sessionManger) {
        _sessionManger = [AFHTTPSessionManager manager];
        
        //设置超时时间
        _sessionManger.requestSerializer.timeoutInterval = 15.0;
        
        //方式一（后续的封装适配了方式二，因此使用方式一的话要进行些许修改才行）
//        _sessionManger.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain",@"text/xml",@"image/gif", nil];
        //方式二（推荐，需要将请求结果进行json解析）
        _sessionManger.responseSerializer = [AFHTTPResponseSerializer serializer];

        //根据需要确定是否开启HTTPS
//        _sessionManger.securityPolicy = self.securityPolicy;
    }
    return _sessionManger;
}

//AFNetWorking 3.x版本  适配HTTPS请求 （根据需要确定是否开启HTTPS）
- (AFSecurityPolicy *)securityPolicy {
    if (!_securityPolicy) {
        //获取本地证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"zz.oricg.com" ofType:@"cer"];
        NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
        
        //设置证书模式(AFSSLPinningModeCertificate证书认证模式，抓包无法抓取到；需要抓包测试的话，更改认证模式即可)
         _securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[[NSSet alloc] initWithObjects:cerData, nil]];
        //客户端是否信任非法证书
        _securityPolicy.allowInvalidCertificates = YES;
        //是否在证书域字段中验证域名
        [_securityPolicy setValidatesDomainName:NO];
    }
    return _securityPolicy;
}

#pragma mark -- 请求 --

- (void)requestWithType:(WLNetWorkRequestType)requestType urlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)cacheTime success:(WLSuccess)success failure:(WLFailure)failure {
    //入参检查
    if (!([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"])) {
        WLLog(@"传入无效的url!");
        return;
    }
    WLLog(@"\n   request: %@\n   url: %@\n   parameters: %@",(requestType ? @"get" : @"post"),urlString,parameters);
    
    //缓存处理（判断走缓存还是请求）
    NSString *cacheKey;
    if (cacheTime) { //开启了缓存
        cacheKey = [WLNetWorkManger creatCacheKeyWithUrlString:urlString params:parameters];
        if (cacheKey) {
            NSDate *questTime = [[NSUserDefaults standardUserDefaults] objectForKey:cacheKey];
            NSString *spaceTime = [WLNetWorkManger stringNowTimeDifferenceWithRequestTime:questTime];
            if (spaceTime && (spaceTime.floatValue < cacheTime)) { //在缓存时间内
                id cacheData = [WLNetWorkManger readCacheDataWithCacheFileName:cacheKey];
                if (cacheData) { //本地存在缓存数据
                    id dict = [NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
                    if (success) {
                        success(dict);
                    }
                    WLLog(@"缓存有效期内，使用了缓存的数据");
                    return;
                }
            }
        }
    }

    //开始请求
    NetworkActivityIndicatorVisible(YES);
    if (requestType) {
        [self.sessionManger GET:urlString parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {

        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NetworkActivityIndicatorVisible(NO);
            
            //缓存处理（缓存数据写入本地）
            if (cacheTime && cacheKey) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:cacheKey];
                [WLNetWorkManger addCacheDataWithCacheFileName:cacheKey cacheData:responseObject];
            }
            
            id dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
            if (success) {
                success(dict);
            }
            
            [self logDic:dict];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NetworkActivityIndicatorVisible(NO);
            
            if (failure) {
                failure(error);
            }
            
            WLLog(@"request fail : %@",error.localizedDescription);
        }];
    } else {
        [self.sessionManger POST:urlString parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {

        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NetworkActivityIndicatorVisible(NO);
            
            //缓存处理（缓存数据写入本地）
            if (cacheTime && cacheKey) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:cacheKey];
                [WLNetWorkManger addCacheDataWithCacheFileName:cacheKey cacheData:responseObject];
            }
            
            //方式一
//            if (sucess) {
//                sucess(responseObject);
//            }
//
//            [self logDic:responseObject];

            //方式二
            id dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
            if (success) {
                success(dict);
            }
            
            [self logDic:dict];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NetworkActivityIndicatorVisible(NO);
            
            if (failure) {
                failure(error);
            }
            
            WLLog(@"request fail : %@",error.localizedDescription);
        }];
    }
}

#pragma mark -- 上传 --

/**  --- DWL ---
 *   方法说明 : 除了图片以外，其他都只考虑只存在fileURL的情况，如果遇到了存在fileData的情况，再另行处理。【情景模拟：拍照 / 从沙盒选图片上传；从沙盒选文件（比如写的笔记 / 录制的音频、视频）上传】
 */
- (void)appendWithMediaArray:(NSArray <WLMediaModel *>*)mediaArray formData:(id<AFMultipartFormData> _Nonnull)formData {
    [mediaArray enumerateObjectsUsingBlock:^(WLMediaModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        switch (obj.fileType) {
            case WLUploadImage: {
                NSString *imageName = obj.fileName.length ? obj.fileName : [WLNetWorkManger currentTimeAsFileNameWithFileSuffix:obj.fileSuffix index:idx];
                if (obj.image) {
                    //压缩处理（UIImageJPEGRepresentation产生的图片后缀为jpg）
                    NSData *imageData = UIImageJPEGRepresentation(obj.image, 0.5);
                    [formData appendPartWithFileData:imageData name:obj.field fileName:imageName mimeType:obj.mimeType];
                } else if (obj.fileURL.absoluteString.length) {
                    //通常情况下，图片要进行压缩处理，因此不会使用这种直接上传原图的
//                    [formData appendPartWithFileURL:model.fileURL name:model.field fileName:imageName mimeType:model.mimeType error:nil];
                    //还是使用处理后的二进制流上传
                    UIImage *image = [UIImage imageWithContentsOfFile:obj.fileURL.absoluteString];
                    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
                    [formData appendPartWithFileData:imageData name:obj.field fileName:imageName mimeType:obj.mimeType];
                }
            }
                break;
            case WLUploadFile: {
                if (obj.fileData.length) {

                } else if (obj.fileURL.absoluteString.length) {
                    NSString *fileName = [WLNetWorkManger currentTimeAsFileNameWithFileSuffix:obj.fileSuffix index:idx];
                    //如果上传不成功，打开下面注释使用二进制流上传
                    [formData appendPartWithFileURL:obj.fileURL name:obj.field fileName:fileName mimeType:obj.mimeType error:nil];
//                    NSData *fileData = [NSData dataWithContentsOfURL:obj.fileURL];
//                    [formData appendPartWithFileData:fileData name:obj.field fileName:fileName mimeType:obj.mimeType];
                }
            }
                break;
            case WLUploadAudio: {
                if (obj.fileData.length) {

                } else if (obj.fileURL.absoluteString.length) {
                    //音频压缩逻辑

                }
            }
                break;
            case WLUploadVideo: {
                if (obj.fileData.length) {

                } else if (obj.fileURL.absoluteString.length) {
                    [self appendVideoWith:obj index:idx formData:formData];
                }
            }
                break;
                
            default:
                WLLog(@"传入的WLNetWorkUploadType类型参数无效！");
                break;
        }
    }];
}

- (void)appendVideoWith:(WLMediaModel *)obj index:(NSInteger)idx formData:(id<AFMultipartFormData> _Nonnull)formData {
    //取出视频源文件
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:obj.fileURL options:nil];
    //将源文件转成MP4格式
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    NSString *videoName = [WLNetWorkManger currentTimeAsFileNameWithFileSuffix:@"mp4" index:idx];
    NSString *mp4Path = [[WLNetWorkManger cachesPathStringWithNetTaskType:WLUpload] stringByAppendingFormat:@"/output-%@", videoName];
    exportSession.outputURL = [NSURL fileURLWithPath: mp4Path]; //转换后的视频存放位置
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusFailed: {
                WLLog(@"视频转码压缩出错！");
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                //如果上传不成功，打开下面注释使用二进制流上传
                [formData appendPartWithFileURL:exportSession.outputURL name:obj.field fileName:videoName mimeType:obj.mimeType error:nil];
//                NSData *videoData = [NSData dataWithContentsOfFile:mp4Path];
//                [formData appendPartWithFileData:videoData name:obj.field fileName:videoName mimeType:obj.mimeType];
                break;
            }
            default:
                break;
        }
    }];
}

- (void)uploadWithUrlString:(NSString *)urlString parameters:(id)parameters mediaArray:(NSArray <WLMediaModel *>*)mediaArray progress:(WLProgress)progress success:(WLSuccess)success failure:(WLFailure)failure {
    //入参检查
    if (!([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"])) {
        WLLog(@"传入无效的url!");
        return;
    }
    if (mediaArray.count == 0) {
        WLLog(@"传入无效的上传数据!");
        return;
    }
    WLLog(@"\n   upload\n    url: %@\n    parameters: %@\n     uploadData: %@",urlString,parameters,mediaArray);
    
    //开始上传
    NetworkActivityIndicatorVisible(YES);
    [self.sessionManger POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [self appendWithMediaArray:mediaArray formData:formData];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) { //若出现进度显示不正常，参考下面 downloadWithUrlString 中的写法
            progress([NSString stringWithFormat:@"%lld%%", uploadProgress.completedUnitCount / uploadProgress.totalUnitCount * 100]);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NetworkActivityIndicatorVisible(NO);
        
        id dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
        if (success) {
            success(dict);
        }
        
        [self logDic:dict];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NetworkActivityIndicatorVisible(NO);
        
        if (failure) {
            failure(error);
        }
        
        WLLog(@"upload fail : %@",error.localizedDescription);
    }];
}

#pragma mark -- 下载 --

- (void)downloadWithUrlString:(NSString *)urlString parameters:(id)parameters progress:(WLProgress)progress success:(WLSuccess)success failure:(WLFailure)failure {
    // 下载地址
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    //开始下载
    NetworkActivityIndicatorVisible(YES);
    NSURLSessionDownloadTask *downloadTask = [self.sessionManger downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress([NSString stringWithFormat:@"%.0f%%", downloadProgress.fractionCompleted * 100]);
        }
        
        WLLog(@"下载进度：%.0f%%", downloadProgress.fractionCompleted * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // targetPath 是AFN默认临时下载数据的路径
        WLLog(@"destinationBlock\n   targetPath: %@", targetPath);
        
        // 指定下载到的位置（targetPath 中临时下载的内容 剪切 到 指定的路径中）
        NSString *filePath = [[WLNetWorkManger cachesPathStringWithNetTaskType:WLDownload] stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NetworkActivityIndicatorVisible(NO);

        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(filePath);
            }
        }
        
        // 这里的 filePath 就是 destination 的返回值
        WLLog(@"completionHandler\n   filePath:%@\n", filePath);
    }];
    [downloadTask resume];
}

#pragma mark -- 取消网络任务，包括请求、上传、下载 --

- (void)cancelRequest {
    if (self.sessionManger.tasks.count) {
        [self.sessionManger.tasks makeObjectsPerformSelector:@selector(cancel)];
        WLLog(@"取消网络请求");
    }
}

#pragma mark -- 打印相关（Unicode转中文） --

- (void)logDic:(id)data {
    if (data == nil || [data isKindOfClass:[NSNull class]]) {
        WLLog(@"requestSucess:%@",data);
    } else {
        NSDictionary *dic = (NSDictionary *)data;
        NSString *tempStr1 = [[dic description] stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
        NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
        NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *str = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
        WLLog(@"requestSucess:%@",str);
    }
}





//检查是否有新版本
-(void)postGetAppInfo:(NSString *)url sucess:(WLSuccess)sucess fail:(WLFailure)fail;
{
#warning 这里不能用hasNet判断，原因是因为AF的网络监测结果还未回调。
//    if (self.hasNet)//可以将判断写在上面封装的Post、Get方法中，调用更加简洁；写在这里的好处可以对不同的接口做不同的处理
//    {
        [self requestWithType:WLRequestGet urlString:url parameters:nil cacheTime:0 success:sucess failure:fail];
//    }
//    else
//    {
//        DLog(@"没网的时候,本地存的是啥就按啥显示就可以！");
//    }
}

/*
 *                                              构造网络请求类的初衷
 
 *    寻求网络请求的最优操作，每次网络请求前进行网络连接是否正常的判断，有网进行请求，无网络不进行请求。将网络监测和接口请求封装在这一个类中，外界调用简单方便
 
 
 *                                                   注意事项
 
 *   1，【在App启动时】需要进行一些接口的请求（比如检查版本更新，检查是否过审核，自己服务器返回的一些标识等接口）：这类接口不能直接使用hasNet属性进行网络判断，因为有可能此时AF的网络监测结果回调还未执行，也就意味着hasNet并未被赋值，此时hasNet是不准确的。（可以参考上面的警告中的内容）
 
 *   2，【App启动后】需要进行一些接口的请求：可以直接使用hasNet属性
 
 *   3，~!~ 1中所说的一些在App启动时进行请求的这类接口，不一定都是写在【didFinishLaunchingWithOptions】方法里的才算，有时候写在MainVC中的也属于这类接口。
        ~!~ 本质上来说，这和接口在哪里请求的位置无关，而是和AF的网络监测结果的执行相对于接口的执行先后顺序有关，如果AF先回调了网络监测结果，然后执行了接口请求，那么此接口属于2中的那类接口，可以直接使用hasNet来判断，反之属于1中那类接口。
        ~!~ 所以1，2中所说的【在App启动时】和【App启动后】并不是绝对的，只是描述最一般的情况，具体使用时，不能只根据接口写的位置来判断是属于1还是2，需要根据其本质原理来进行调试区分
 
 *   4，由于每次网络改变AF都会回调网络监测结果，我们的getLaunchNetResult也会跟着调用多次，但是一般的接口我们只进行一次请求（过审核接口的除外），此时使用时有两种情况：
        ~!~ 有过审核的接口，【外界调用】这类接口时 ，除了过审核的接口用过审核标识判断是否跟随网络变化进行请求之外，其他接口都用dispatch_once来保证只执行一次
        ~!~ 没有过审核的接口，【直接在本类】的AF网络回调中，在getLaunchNetResult调用写在dispatch_once中，外界正常调用即可
 
 *   5，如果1中的这类接口过多，处理起来过于复杂，是在没有办法的时候，可以考虑放弃最优操作（放弃hasNet的判断）
 */

@end
