//
//  Product.h
//  WPEducation
//
//  Created by iOS-Dev on 2017/12/27.
//  Copyright © 2017年 Administrator. All rights reserved.
//

#ifndef Product_h
#define Product_h
#import "AppDelegate.h"
#import "UIColor+hex.h"

#define MainColor [UIColor colorWithHexString:@"#37a8ff"];
#define BackgroundColor [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.75]

#define AVATAR_SIZE CGSizeMake(300, 300)

#define APPDELEGATE ((AppDelegate*)[[UIApplication sharedApplication] delegate])
#define SCREENHEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREENWIDTH [[UIScreen mainScreen] bounds].size.width

#define STATEBARHEIGHT 64

#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125,2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define MAINHEIGHT iPhoneX ? (SCREENHEIGHT - STATEBARHEIGHT - 64 - 44):(SCREENHEIGHT - STATEBARHEIGHT)

#define MAINWIDTH SCREENWIDTH

#define TABLEVIEWHEADERHEIGHT 3.f

#define APP_URL @"http://60.166.36.66/wpedu/app/portal.jhtml"

#endif /* Product_h */
