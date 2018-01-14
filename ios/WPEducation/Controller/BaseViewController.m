//
//  BaseViewController.m
//  WPEducation
//
//  Created by iOS-Dev on 2017/12/26.
//  Copyright © 2017年 Administrator. All rights reserved.
//

#import "BaseViewController.h"
#import "NSString+Helpers.h"
#import "DeviceModel.h"
#import "MJExtension.h"
#import "GXToast.h"
#import "UIDevice+Util.h"
#import "BSLCalendar.h"
#import "CustomAlertView.h"
#import "KLCPopup.h"
#import "UIView+CNKit.h"
#import "DatePicker.h"
#import "DatePicker2.h"
#import "MSSCalendarViewController.h"
#import "MSSCalendarDefine.h"
#import "CropImageViewController.h"
#import "UIView+Util.h"
#import "DateRangeView.h"
#import "KLCPopup.h"
#import "PGDatePicker.h"
#import "JSmodel.h"
#import "StartViewController.h"

@interface BaseViewController ()<UIWebViewDelegate,JSObjcDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIScrollViewDelegate,ConfirmSureBtnDelegate,DatePickerDelegate,DatePicker2Delegate,UIAlertViewDelegate,MSSCalendarViewControllerDelegate,CropImageViewControllerDelegate,DateRangeViewDelegate,PGDatePickerDelegate>{
    DatePicker *datePick;
    DatePicker2 *datePicker2;
    int distance;
    NSString *deviceid ;
    NSString *updateUrlStr;
    NSTimer *timer ;
    NSString *dateType;
    NSDictionary *dic;
    NSError *err;
    //CGSize cropZize ;
  //  NSString *imagePath;

}

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _dictCallback = [[NSMutableDictionary alloc] init] ;
    [self.view addSubview:[self webView]];
    _header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(headerRefresh)];
    _header.lastUpdatedTimeLabel.hidden = YES;
    self.webView.scrollView.mj_header = _header;
    self.webView.scrollView.delegate = self;
    
    // Do any additional setup after loading the view.
}

#pragma mark 懒加载
-(UIWebView*)webView {
    if (!_webView) {
        if(iPhoneX){
            _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,-44,MAINWIDTH, [UIScreen mainScreen].bounds.size.height + 44)];
        }else {
           _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,-20,MAINWIDTH, [UIScreen mainScreen].bounds.size.height + 20)];
        }
        
        _webView.delegate = self;
        _webView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }
    return _webView;
}

#pragma mark - 下拉刷新的方法
- (void)headerRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    });
}

#pragma mark webViewDidStartLoad
-(void)webViewDidStartLoad:(UIWebView *)webView{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.label.text = @"加载中...";
    });
    [self addCustomActions];
   
}

#pragma mark webViewDidFinishLoad
-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self addCustomActions];

    [self executeCallback:@"onPageFinished" params:nil];
    if(self.header){
        [self endRefresh];
        [self.webView.scrollView.mj_header endRefreshing];
    }
    [_hud setHidden:YES];

}

#pragma mark didFailLoadWithError
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@",error);
    [self endRefresh];
    [_hud setHidden:YES];
     NSString *path = [[NSBundle mainBundle] pathForResource:@"error" ofType:@"html" inDirectory:@"assets"];
     NSURL*Url = [NSURL fileURLWithPath:path];
   [self.webView loadRequest:[NSURLRequest requestWithURL:Url]];
}

#pragma mark - 结束下拉刷新和上拉加载
- (void)endRefresh {
    [self.webView.scrollView.mj_header endRefreshing];
    [self.webView.scrollView.mj_footer endRefreshing];
    
}
#pragma mark Js 调用客户端OC的方法
-(void)addCustomActions{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    [context setExceptionHandler:^(JSContext *ctx, JSValue *expectValue) {
        NSLog(@"%@", expectValue);
    }];
    self.context = context;
    self.context[@"app"] = self;
    
}

#pragma mark OC代码调用js函数
-(void)executeCallback:(NSString *)callback params:(id)params{
        if ([callback containsString:@"("] && [callback containsString:@")"]) {
            [_webView stringByEvaluatingJavaScriptFromString:callback];
        }else{
            JSValue *funcValue = self.context[callback];
            if (params != nil) {
                [funcValue callWithArguments:@[params]];
            }else{
                NSString *sss = [NSString stringWithFormat:@"%@()", callback];
                [_webView stringByEvaluatingJavaScriptFromString:sss];
            }
            
        }
}

#pragma mark ---JSBridgedelegate
-(void)openNew:(id)data {
   // NSLog(@"打开窗口 ---%@--",[NSString st]);
    NSLog(@"打开窗口 === %@",data);
    if (data) {
        if ([data isKindOfClass:[NSString class]]) {
            [self goToNewPageWithUrlString:data params:nil];
        }else if ([data isKindOfClass:[NSDictionary class]]){
            [self goToNewPageWithUrlString:data[@"url"] params:nil];
        }
    }
}

- (void)close:(id)data {
    NSLog(@"---关闭窗口---");
    NSLog(@"&&&&&&&&%lu",self.navigationController.viewControllers.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController.viewControllers.count > 2) {
            CATransition *transition = [CATransition animation];
            transition.duration = 0.4f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
            transition.type = @"oglApplicationSuspend";
            transition.subtype = kCATransitionFromBottom;
            [self.navigationController.view.layer addAnimation:transition forKey:nil];
            [self.navigationController popViewControllerAnimated:YES];

        }
    });
    
}

#pragma mark get
-(NSString*)get:(id)data {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *string = [defaults objectForKey:@"authToken"];
    return string;
}

#pragma mark remove
-(void)remove:(id)data {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"authToken"];
    [defaults synchronize];
    //退出登录的时候
    StartViewController *VC = [[StartViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:VC];
    APPDELEGATE.window.rootViewController = nav;
}

#pragma mark put
-(void)put:(id)data {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults] ;
    [defaults setObject:[data objectForKey:@"value"] forKey:@"authToken"];
    [defaults synchronize];
}

#pragma mark goToNewPageWithUrlString
-(void)goToNewPageWithUrlString:(NSString *)urlString params:(NSDictionary *)params {
    dispatch_async(dispatch_get_main_queue(), ^{
        BaseViewController *newVC = [[BaseViewController alloc] init];
      //  newVC.mbParentController = self;
        __block NSString *paramsString = nil;
        if (params != nil) {
            [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                paramsString = [NSString stringWithFormat:@"%@=%@&", key, obj];
            }];
        }
        if (paramsString != nil) {
            if ([urlString hasSuffix:@"?"]) {
                newVC.urlString = [NSString stringWithFormat:@"%@%@", urlString, paramsString];
            }else{
                newVC.urlString = [NSString stringWithFormat:@"%@?%@", urlString, paramsString];
            }
        }else{
            newVC.urlString = urlString;
        }
        

        [newVC.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newVC.urlString ]]];
        
        [UIView transitionWithView:self.navigationController.view
                          duration:0.4
                           options:UIViewAnimationOptionCurveLinear
                        animations:^{
                            [self.navigationController pushViewController:newVC animated:NO];
                        }
                        completion:nil];


       // [self presentViewController:newVC animated:YES completion:nil];
        
        });
  }

#pragma mark  json转字典
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    @try {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&err];
    }
    @catch (NSException *exception) {
        [self prompt:exception.reason];
    }
    return dic;
}

#pragma mark base64
-(NSString*)base64File:(id)data {
    NSData *imageData = [NSData dataWithContentsOfFile:data];
    NSString *encodedImageStr = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedImageStr;
    
}

#pragma mark 选择图片
-(void)selectImage:(id)data {
    NSDictionary *dataDic =  [self dictionaryWithJsonString:data];;
    NSDictionary *paramsDic = [dataDic objectForKey:@"params"];
  
     _dictCallback[@"setImage"] = dataDic[@"callback"];
    NSString *srcType = [paramsDic objectForKey:@"srcType"];

    APPDELEGATE.cropSize = CGSizeMake([[paramsDic objectForKey:@"cropWith"] floatValue] , [[paramsDic objectForKey:@"cropHeight"] floatValue]);
    if ([[paramsDic objectForKey:@"autoCrop"] isEqualToString:@"true"]) {
        _isNeedCropBool = YES;
    } else {
        _isNeedCropBool = NO;
    }
    
    if ([srcType isEqualToString:@"Grallery"]) {
        [self _takeAPhotoWithAlbum];
    }else {
        
        [self _takeAPhotoWithCamera];
    }
}

- (void)acceptMessage:(id)data {
    
}


- (void)actions:(id)data {
    
}

- (void)alert:(id)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        CustomAlertView * alertView = [[CustomAlertView alloc]initWithFrame:CGRectMake(60, 200, MAINWIDTH-120, 160)WithData:data isAlert:YES];
        [alertView aletBtnClickWithBlock:^(NSInteger index, NSString *callback) {
            [alertView dismissPresentingPopup];
            
        }];
        
        KLCPopup * popView = [KLCPopup popupWithContentView:alertView showType:KLCPopupShowTypeGrowIn dismissType:KLCPopupDismissTypeGrowOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO isNoAllView:NO];
        [popView showAtCenter:CGPointMake(self.view.centerX, 160+32) inView:self.view];
        popView.didFinishDismissingCompletion = ^{
            
        };
    });
}


- (void)callHostPlugin:(id)data {
    
}


- (void)callParent:(id)data {
    NSString *param = data[@"params"];
    
    JSValue *funcValue = _mbParentController.context[data[@"callback"]];
    [funcValue callWithArguments:@[param]];
}
-(NSString*)getUrl {
    [self headerRefresh];
    return self.urlString;
}

- (void)closeParent:(id)data {
    [self.mbParentController dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirm:(id)data {
    NSDictionary *dict = data;
    NSString *message = dict[@"message"];
    NSDictionary *params = dict[@"params"];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertView = [[CustomAlertView alloc]initWithFrame:CGRectMake(60, 200, MAINWIDTH-120, 160)WithData:data isAlert:NO];
        [self.alertView aletBtnClickWithBlock:^(NSInteger index, NSString *callback) {
            [self.alertView dismissPresentingPopup];
            if(index == 1){
                
                [self executeCallback:callback params:params];
            }
        }];
        
        
        self.alertView.delegate = self;
        
        KLCPopup * popView = [KLCPopup popupWithContentView:self.alertView showType:KLCPopupShowTypeGrowIn dismissType:KLCPopupDismissTypeGrowOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO isNoAllView:NO];
        //    [popView showAtCenter:CGPointMake(self.view.centerX, SCREEN_HEIGHT-400) inView:self.view];
        [popView showAtCenter:CGPointMake(self.view.centerX, 160+32) inView:self.view];
        popView.didFinishDismissingCompletion = ^{
            
        };
    });
    
}

- (void)debug:(id)data {
    
}

- (void)dial:(id)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"telprompt://%@",data];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    });
   
}

- (void)dragRefresh:(id)data {
    self.isNeedRefresh = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_header removeFromSuperview];
        _header = nil;
        if(!_header){
            _header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(headerRefresh)];
        }
        _header.lastUpdatedTimeLabel.hidden = YES;
        _header.stateLabel.hidden = YES;
        self.webView.scrollView.mj_header = _header;
        self.webView.scrollView.delegate = self;
    });
}

- (void)getLocation:(id)data {
    
}

- (void)getNavValue:(id)data {
    
}

- (void)hideTopRight:(id)data {
    
}

- (void)message:(id)data {
    
}


- (void)onPageEnd:(id)data {
    
}

- (void)onResume:(id)data {
    
}

- (void)onSaveState:(id)data {
    
}

- (void)openModal:(id)data {
    
}

- (void)postData:(id)url :(id)requestMapping :(id)callback :(id)content :(id)files {
    
}

- (void)readFile:(id)data {
    
}

- (void)refreshParent:(id)data {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.mbParentController.header){
            if (!self.mbParentController.webView.scrollView.mj_header.isRefreshing) {
                [self.mbParentController.webView.scrollView.mj_header beginRefreshing];
            }
        }
        else{
            [self.mbParentController.webView reload];
            
        }
    });
}

#pragma mark 选择日历
- (void)selectCalendar:(id)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        BSLCalendar *calendar = [[BSLCalendar alloc]initWithFrame:CGRectMake(0, MAINHEIGHT - 300, MAINWIDTH, 300)];
        [self.view addSubview:calendar];
        calendar.showChineseCalendar = YES;
        [calendar selectDateOfMonth:^(NSInteger year, NSInteger month, NSInteger day) {
            NSLog(@"%ld-%ld-%ld",(long)year,(long)month,(long)day);
            [calendar removeFromSuperview];
            NSString *chosecalenValueStr = [NSString stringWithFormat:@"%ld-%ld-%ld",(long)year,(long)month,(long)day];
            
            [self executeCallback:@"setCalendar" params:chosecalenValueStr];
            
        }];
        
    });
}

- (void)selectTime:(id)data {
    [self datePickerDidCancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        datePick = [[DatePicker alloc] init];
        datePick.tag = 1000;
        [self.view addSubview:datePick];
        [datePick setDelegate:self];
        [datePick setCenter:CGPointMake(self.view.frame.size.width*.5, self.view.frame.size.height-datePick.frame.size.height*.5)];
    });
}

#pragma mark 选择日期
-(void)selectDate:(id)data {
    [self datePickerDidCancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        datePicker2 = [[DatePicker2 alloc] init];
        datePicker2.tag = 2000;
        [self.view addSubview:datePicker2];
        [datePicker2 setDelegate:self];
        [datePicker2 setCenter:CGPointMake(self.view.frame.size.width*.5, self.view.frame.size.height-datePicker2.frame.size.height*.5)];
        
    });
}

#pragma mark 移除
-(void)datePickerDidCancel{
    dispatch_async(dispatch_get_main_queue(), ^{
        for(UIView *view in self.view.subviews){
            if([view isKindOfClass:[DatePicker2 class]]){
                
                [view removeFromSuperview];
            }
        }
        
        CGRect tableFrame = self.view.frame;
        tableFrame.origin.y += distance;
        distance = 0;
        [self.view setFrame:tableFrame];
        [datePicker2 removeFromSuperview];
        [datePick removeFromSuperview];    });
    
}

#pragma mark datePickerDidDone
-(void)datePickerDidDone:(DatePicker2*)picker{
    if (picker.tag == 1000) {
        //setTime
        NSString *time = [NSString stringWithFormat:@"%lu-%@-%@ %@:%@",(unsigned long)datePick.yearValue,[self intToDoubleString:datePick.monthValue],[self intToDoubleString:datePick.dayValue],[self intToDoubleString:datePick.hourValue],[self intToDoubleString:datePick.minuteValue]] ;
        JSValue *funcValue = self.context[@"setTime"];
        [funcValue callWithArguments:@[time]];
    }else {
        // setDate
        
        NSString *date = [NSString stringWithFormat:@"%lu-%@-%@",(unsigned long)datePicker2.yearValue,[self intToDoubleString:datePicker2.monthValue],[self intToDoubleString:datePicker2.dayValue]] ;
        JSValue *funcValue = self.context[@"setDate"];
        [funcValue callWithArguments:@[date]];
    }
    
    [self datePickerDidCancel];
}

#pragma mark intToDoubleString
-(NSString *)intToDoubleString:(NSInteger)d {
    if (d<10) {
        return [NSString stringWithFormat:@"0%ld",(long)d];
    }
    return [NSString stringWithFormat:@"%ld",(long)d];
    
}

- (void)selector:(id)data {
    
}


- (void)setBottomBadge:(id)data {
    
}

#pragma mark setFootMenu 底部菜单
- (void)setFootMenu:(id)data {
    
}


#pragma mark setNavigator
- (void)setNavigator:(id)data {
    
}

#pragma mark setTitleIcon
- (void)setTitleIcon:(id)data {
    
}

#pragma mark setTopMenu
- (void)setTopMenu:(id)data {
    
}

#pragma mark show2dCode 二维码
- (void)show2dCode:(id)data {
    
}

#pragma mark showLoading
- (void)showLoading:(id)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        _hud = [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.label.text = @"加载中...";
    });
   
}

#pragma mark hideLoading
- (void)hideLoading:(id)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_hud setHidden:YES];

    });
}

#pragma mark prompt
- (void)prompt:(id)data {
    NSLog(@"++++++%@++++++++",data);
    dispatch_async(dispatch_get_main_queue(), ^{
        //[GXToast showText:data];
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeText;
        _hud.label.text = data;
        timer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hiddenHUD) userInfo:nil repeats:NO];
        
    });
    
}

#pragma mark hiddenHUD
-(void)hiddenHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_hud setHidden:YES];
        [MBProgressHUD hideHUDForView:self.view animated:YES];

    });
}

#pragma mark topMessage
- (void)topMessage:(id)data {
   
    
}

#pragma mark viewPicture
- (void)viewPicture:(id)data {
    
}

#pragma mark actionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag == 0) {
        switch (buttonIndex) {
            case 0:{
                [self _takeAPhotoWithCamera];
            }
                break;
            case 1:{
                [self _takeAPhotoWithAlbum];
            }
                break;
            default:
                break;
        }
    }
    
}

#pragma mark 访问相册
-(void)_takeAPhotoWithAlbum {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIImagePickerController *imgPickerVC = [[UIImagePickerController alloc] init];
        [imgPickerVC setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imgPickerVC.navigationBar setBarStyle:UIBarStyleBlack];
        [imgPickerVC setDelegate:self];
        [imgPickerVC setAllowsEditing:NO];
        //显示Image Picker
        [self presentViewController:imgPickerVC animated:YES completion:nil];
    }else {
        NSLog(@"Album is not available.");
    }
    
}

#pragma mark 实时拍照
-(void)_takeAPhotoWithCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *cameraVC = [[UIImagePickerController alloc] init];
        [cameraVC setSourceType:UIImagePickerControllerSourceTypeCamera];
        [cameraVC.navigationBar setBarStyle:UIBarStyleBlack];
        [cameraVC setDelegate:self];
        [cameraVC setAllowsEditing:NO];
        cameraVC.hidesBottomBarWhenPushed = YES;
        //显示Camera VC
        
        self.hidesBottomBarWhenPushed = YES;
        [self presentViewController:cameraVC animated:YES completion:nil];
        
    }else {
        NSLog(@"Camera is not available.");
    }
    
}

#pragma mark imagePickerController  delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Obtain the path to save to
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imageFile = [[NSString alloc] initWithString:[NSString UUID]];


    APPDELEGATE.imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",imageFile]];
    
    // Extract image from the picker and save it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        //判断是否需要裁剪
        if (!_isNeedCropBool) {
            CropImageViewController *vctrl = [[CropImageViewController alloc] init];
            vctrl.image = [UIView fitSmallImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
            vctrl.delegate = self;
            [self.navigationController pushViewController:vctrl animated:YES];
            
        }else {
            UIImage *image = [UIView scaleToSize:[info objectForKey:UIImagePickerControllerOriginalImage] size:APPDELEGATE.cropSize];

           // UIImage *image = [self fitSmallImage:[info objectForKey:UIImagePickerControllerOriginalImage]] ;
            
            NSData *data = UIImageJPEGRepresentation(image, 0.5);//UIImagePNGRepresentation(image);
            [data writeToFile:APPDELEGATE.imagePath atomically:YES];
            JSValue *funcValue = self.context[_dictCallback[@"setImage"]];
            NSLog(@"address === %@",APPDELEGATE.imagePath);
             [funcValue callWithArguments:@[APPDELEGATE.imagePath]];
        }
        
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark 图片裁剪
- (void)cropImageController:(CropImageViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage {
    UIImage *image = [UIView scaleToSize:croppedImage size:APPDELEGATE.cropSize];
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    [data writeToFile:APPDELEGATE.imagePath atomically:YES];
    
    JSValue *funcValue = self.context[_dictCallback[@"setImage"]];
    [funcValue callWithArguments:@[APPDELEGATE.imagePath]];
//    NSData *imageData = UIImagePNGRepresentation(image);
    

}

#pragma mark 小图片
-(UIImage *)fitSmallImage:(UIImage *)image {
    if (nil == image)
    {
        return nil;
    }
    if (image.size.width<720 && image.size.height<960)
    {
        return image;
    }
    CGSize size = [self fitsize:image.size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [image drawInRect:rect];
    UIImage *newing = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newing;
}

#pragma mark fitsize
- (CGSize)fitsize:(CGSize)thisSize {
    if(thisSize.width == 0 && thisSize.height ==0)
        return CGSizeMake(0, 0);
    CGFloat wscale = thisSize.width/720;
    CGFloat hscale = thisSize.height/960;
    CGFloat scale = (wscale>hscale)?wscale:hscale;
    CGSize newSize = CGSizeMake(thisSize.width/scale, thisSize.height/scale);
    return newSize;
}

#pragma mark 获取手机型号
-(NSString*)getDeviceModel {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if(![defaults objectForKey:@"deviceid"]){
        [defaults setObject:[UIDevice deviceId] forKey:@"deviceid"];
        [defaults synchronize];
    }
   
    deviceid = [defaults objectForKey:@"deviceid"];
    DeviceModel *model = [[DeviceModel alloc] init];
    model.sdk = @"";
    model.version = [UIDevice osVersion];
    model.display = @"";
    model.model = [UIDevice model];
    model.id = deviceid;
  
    NSString *jsonObj = [model mj_JSONString];
    return jsonObj;
}

#pragma mark 检查版本更新
-(void)checkNewVersion:(id)updateUrl :(id)isShowTip {
    updateUrlStr = updateUrl;
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:updateUrl]];
    if (dict) {
        
        NSArray* list = [dict objectForKey:@"items"];
        NSDictionary* dict2 = [list objectAtIndex:0];
        
        NSDictionary* dict3 = [dict2 objectForKey:@"metadata"];
        NSString *changelogStr = [dict3 objectForKey:@"changelog"];
        changelogStr = [changelogStr stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        NSString* newVersion = [dict3 objectForKey:@"bundle-version"];
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *myVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        
        _hud = [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.label.text = @"正在检查版本升级...";
        timer =  [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hiddenHUD) userInfo:nil repeats:NO];
        
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0/*延迟执行时间*/ * NSEC_PER_SEC));
        
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            if(isShowTip){
                if (![newVersion isEqualToString:myVersion]) {
                    //提示让用户来肯定更新不更新
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"版本升级"
                                                                        message:changelogStr
                                                                       delegate:self
                                                              cancelButtonTitle:@"稍后再说"
                                                              otherButtonTitles:@"现在升级", nil];
                    
                    [self alrterViewShow:alertView];
                }else {
                    
                    UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"版本升级"
                                                                   message:@"目前已是最新版本，无需升级。"
                                                                  delegate:self
                                                         cancelButtonTitle:@"确定"
                                                         otherButtonTitles:nil];
                    NSLog(@"您已经是最新版");
                    [alert show];
                }
            }else{
                if (![newVersion isEqualToString:myVersion]) {
                    //这里博主是直接更新的，你可以给用户弹个提示让用户来肯定更新不更新
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"版本升级"
                                                                        message:changelogStr
                                                                       delegate:self
                                                              cancelButtonTitle:@"稍后再说"
                                                              otherButtonTitles:@"现在升级", nil];
                    [self alrterViewShow:alertView];
                    
                }
            }
        });
        
       
        
    }
}

#pragma mark alrterView  自定义显示
-(void)alrterViewShow:(UIAlertView*)alertView {
    //如果你的系统大于等于7.0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    {
        // CGSize size = [_changelog sizeWithFont:[UIFont systemFontOfSize:15]constrainedToSize:CGSizeMake(240,400) lineBreakMode:NSLineBreakByTruncatingTail];
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont systemFontOfSize:15];
        textLabel.textColor = [UIColor blackColor];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.lineBreakMode =NSLineBreakByWordWrapping;
        textLabel.numberOfLines =0;
        textLabel.textAlignment =NSTextAlignmentLeft;
        
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:alertView.message];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.headIndent = 15;//缩进
        style.firstLineHeadIndent = 15;
        [text addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, text.length)];
        
        textLabel.attributedText = text;
        [alertView setValue:textLabel forKey:@"accessoryView"];
        
        alertView.message =@"";
    }else{
        NSInteger count = 0;
        for( UIView * view in alertView.subviews )
        {
            if( [view isKindOfClass:[UILabel class]] )
            {
                count ++;
                if ( count == 2 ) { //仅对message左对齐
                    UILabel* label = (UILabel*) view;
                    label.textAlignment =NSTextAlignmentLeft;
                }
            }
        }
    }
    [alertView show];
}

#pragma mark clickedButtonAtIndex
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"%ld+++++++++",(long)buttonIndex);
    switch (buttonIndex) {
        case 0:
            
            break;
        case 1:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",updateUrlStr]]];
            break;
        default:
            break;
    }
    
}

#pragma mark 选择时间范围
-(void)selectDateRange:(id)data {
    NSDictionary *dict;
    if ([data isKindOfClass:[NSDictionary class]]) {
        dict =data;
    }else {
        dict = [self dictionaryWithJsonString:data];

    }
    dateType = [dict objectForKey:@"params"];
    //为空时默认的格式
    if (dateType == nil) {
        dateType = @"yyyy-MM-dd HH:mm";
    }
    
    DateRangeView *dateViewRange = [[DateRangeView alloc] initWithFrame:CGRectMake(15, 0,MAINWIDTH - 30 , 200)];
    dateViewRange.delegate = self;
    self.dateRangePopView = [KLCPopup popupWithContentView:dateViewRange showType:KLCPopupShowTypeSlideInFromBottom dismissType:KLCPopupDismissTypeSlideOutToBottom maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO isNoAllView:NO];
    [self.dateRangePopView showAtCenter:CGPointMake(self.view.centerX, self.view.centerY ) inView:self.view];
}

#pragma mark DateRangeViewdelegate
#pragma mark 选择开始时间
-(void)choseStartTime {
    PGDatePicker *datePicker = [[PGDatePicker alloc]init];
    datePicker.tag = 1000;
    datePicker.delegate = self;
    [datePicker show];
    datePicker.datePickerType = PGPickerViewType3;
    datePicker.isHiddenMiddleText = false;
    datePicker.datePickerMode = [self selectDateType];
    
    datePicker.minimumDate = [NSDate setYear:2015 month:9 day:30];
    datePicker.maximumDate = [NSDate setYear:2027 month:10 day:2];
    
}

#pragma mark 选择结束时间
-(void)choseEndTime{
    PGDatePicker *datePicker = [[PGDatePicker alloc]init];
    datePicker.tag = 1001;
    datePicker.delegate = self;
    [datePicker show];
    datePicker.datePickerType = PGPickerViewType3;
    datePicker.isHiddenMiddleText = false;
    datePicker.datePickerMode = [self selectDateType];
    
    datePicker.minimumDate = [NSDate setYear:2015 month:9 day:30];
    datePicker.maximumDate = [NSDate setYear:2027 month:10 day:2];
}

#pragma mark 时间选择器类型
-(PGDatePickerMode)selectDateType {
    //年月日
    if ([dateType isEqualToString:@"yyyy-MM-dd"] || [dateType isEqualToString:@"yyyy/MM/dd"]) {
        NSLog(@"年月日");
        return  PGDatePickerModeDate;
    }
    //年月
    if ([dateType isEqualToString:@"yyyy-MM"] || [dateType isEqualToString:@"yyyy/MM"] ) {
        NSLog(@"年月");
        return PGDatePickerModeDate;
    }
    //年月日时分
    if ([dateType isEqualToString:@"yyyy-MM-dd HH:mm"] || [dateType isEqualToString:@"yyyy/MM/dd HH:mm"] ) {
        NSLog(@"年月日时分");
        return PGDatePickerModeDateHourMinute;
    }
    //月日
    if ([dateType isEqualToString:@"MM-dd"] || [dateType isEqualToString:@"MM/dd"] ) {
        NSLog(@"月日");
        return PGDatePickerModeDate;
    }
    
    //月日时分
    if ([dateType isEqualToString:@"MM-dd HH:mm"] || [dateType isEqualToString:@"MM/dd HH:mm"] ) {
        NSLog(@"月日时分");
        return PGDatePickerModeDateHourMinute;
    }
     //时分
    if ([dateType isEqualToString:@"HH:mm"]) {
        NSLog(@"时分");
        return PGDatePickerModeTime;
    }
    
  
    return 0;
}


#pragma mark 时间选择提交
-(void)submitWithStartDate:(NSString *)startDate andEndDate:(NSString *)endDate {
    NSLog(@"----时间范围选择----");
    //json数据组装
    NSMutableArray *jsonMulArray = [[NSMutableArray alloc] init];
    JSmodel *startModel = [[JSmodel alloc] init];
    startModel.fieldLabel = @"开始日期";
    startModel.fieldName = @"startDate";
    startModel.value = startDate;
    [jsonMulArray addObject:[startModel mj_JSONObject]];
    
    JSmodel *endModel = [[JSmodel alloc] init];
    endModel.fieldLabel = @"结束日期";
    endModel.fieldName = @"endDate";
    endModel.value = endDate;
    [jsonMulArray addObject:[endModel mj_JSONObject]];
    if(!([startDate isEqualToString:@"(null)"] && [endDate isEqualToString:@"(null)"])){
        
        [self executeCallback:@"selectDateRangeCallback" params:jsonMulArray];

    }
    [self.dateRangePopView removeFromSuperview];
}

#pragma mark PGDatePickerdelegate
-(void)datePicker:(PGDatePicker *)datePicker didSelectDate:(NSDateComponents *)dateComponents {
    NSLog(@"dateComponents ====== %@",dateComponents);
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDate * date = [calendar dateFromComponents:dateComponents];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = dateType;
    NSString * selectDateString = [formatter stringFromDate:date];
    
   // [selectDateString stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
    
    //NSString *selectDateString = [NSString stringWithFormat:@"%ld-%ld-xr%ld",(long)dateComponents.year,(long)dateComponents.month,(long)dateComponents.day];
   
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:selectDateString,@"selectDate",@(datePicker.tag),@"tag",nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refshSelectTime" object:dict];
}

-(void)cancel {
    [self.dateRangePopView removeFromSuperview];

}

#pragma mark didReceiveMemoryWarning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end
