//
//  AppDelegate.h
//  HelloOpenGL
//
//  Created by AgPC on 14-8-23.
//  Copyright (c) 2014年 TwoEggs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OpenGLView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    // Inside @interface
    OpenGLView* _glView;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;
// After @interface
@property (nonatomic, retain) IBOutlet OpenGLView *glView;

@end
