//
//  StartViewController.m
//  WPEducation
//
//  Created by xyt on 2017/12/26.
//  Copyright © 2017年 Administrator. All rights reserved.
//

#import "StartViewController.h"
#import "UIDevice+Util.h"
#import "Product.h"
@interface StartViewController ()<UIWebViewDelegate>

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   // [[NSURLCache sharedURLCache] removeAllCachedResponses];
    self.navigationController.navigationBar.hidden = YES;
    self.urlString = APP_URL;
//    //判断是否登录
//    if (autokenString.length) {
//       self.urlString = @"http://60.166.36.66/wpedu/app/portal.jhtml";
//    }else {http://192.168.1.110:8080/wpedu/app/portal.jhtml
//       self.urlString = @"http://60.166.36.66/wpedu/app/login.jhtml";
//    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidNav) name:@"Hidden_nav" object:nil];
   // [self.webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString: self.urlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0]];
    // Do any additional setup after loading the view.
}

-(void)hidNav {
    
    self.navigationController.navigationBar.hidden = YES;

}

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
