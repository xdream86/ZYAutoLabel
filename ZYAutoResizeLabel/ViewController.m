//
//  ViewController.m
//  ZYAutoResizeLabel
//
//  Created by zhuyongqing on 2017/4/13.
//  Copyright © 2017年 zhuyongqing. All rights reserved.
//

#import "ViewController.h"
#import "ZYAutoLabel.h"
#import "ZYSubtitleLabel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor grayColor];
    
//    ZYAutoLabel *autoLabel = [[ZYAutoLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
//    autoLabel.center = self.view.center;
//    autoLabel.text = @"AUTOLABEL";
//    [self.view addSubview:autoLabel];
    
    
    ZYSubtitleLabel *autoLabel = [[ZYSubtitleLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    autoLabel.center = self.view.center;
    autoLabel.text = @"AUTOLABEL";
    [self.view addSubview:autoLabel];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
