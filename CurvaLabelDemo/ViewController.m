//
//  ViewController.m
//  CurvaLabelDemo
//
//  Created by javen on 13-3-6.
//  Copyright (c) 2013年 yuezo.com. All rights reserved.
//

#import "ViewController.h"
#import "CoreTextArcView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{        
    CGRect rect1 = CGRectMake(0, 120, 320, 120);
    UIFont * font1 = [UIFont fontWithName:@"Helvetica" size:26.0f];
    UIColor * color1 = [UIColor whiteColor];
    CoreTextArcView * cityLabel = [[[CoreTextArcView alloc] initWithFrame:rect1
                                                                    font:font1
                                                                    text:@"New York City"
                                                                  radius:85
                                                                 arcSize:110
                                                                   color:color1] autorelease];
    cityLabel.backgroundColor = [UIColor clearColor];
    
    
    CGRect rect2 = CGRectMake(0, 235, 320, 200);
    CoreTextArcView * cityLabel2 = [[[CoreTextArcView alloc] initWithFrame:rect2
                                                                     font:font1
                                                                     text:@"Google"
                                                                   radius:-80
                                                                  arcSize:-80
                                                                    color:color1] autorelease];
    
    [cityLabel2 showsLineMetrics];
    cityLabel2.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:cityLabel];
    [self.view addSubview:cityLabel2];
    
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [super dealloc];
}
@end
