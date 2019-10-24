//
//  Macrodefine.h
//  WL_NetWorkManger
//
//  Created by Mac on 2019/5/17.
//  Copyright © 2019 DuWenliang. All rights reserved.
//

#ifndef Macrodefine_h
#define Macrodefine_h



#ifdef DEBUG
    #define WLLog(format, ...) printf("\n=============Log Start==============\n---Class: <%p %s:(%d)>    \n---Method: %s    \n---打印内容: %s\n=============Log End================\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )
#else
    #define WLLog(format, ...)
#endif

//keyWindow
#define WLWindow [UIApplication sharedApplication].keyWindow
//全屏的高、宽
#define WLScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define WLScreenWidth  ([UIScreen mainScreen].bounds.size.width)
//RGB 颜色、随机色
#define WLColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define WLRandomColor  [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0f];




#endif /* Macrodefine_h */
