//
//  WLMediaModel.h
//  WL_NetWorkManger
//
//  Created by Mac on 2019/6/20.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Photos/Photos.h>


//上传的文件类型
typedef NS_ENUM(NSInteger, WLUploadFileType) {
    WLUploadImage,
    WLUploadFile,
    WLUploadAudio,
    WLUploadVideo
};


@interface WLMediaModel : NSObject

@property (nonatomic, assign) WLUploadFileType fileType;
@property (nonatomic, copy) NSString *fileName; //文件名
@property (nonatomic, copy) NSString *fileSuffix; //文件后缀名
@property (nonatomic, copy) NSString *mimeType; //文件类型对应的mimeType
@property (nonatomic, copy) NSString *field; //服务器对应接收的字段名

//文件资源可能的几种来源(根据实际情况对以下任意一个属性赋值)：
//1，文件资源存储在了沙盒中（不需要对资源进行二次处理的情况下，可直接使用沙盒地址上传）
@property (nonatomic, strong) NSURL *fileURL;
//2，文件内容直接以二进制流形式存在
@property (nonatomic, strong) NSData *fileData;
//3，主要用于驻留在内存中不需要写入沙盒存储的图片，比如拍照上传、从相册选图片上传
@property (nonatomic, strong) UIImage *image;

@end


