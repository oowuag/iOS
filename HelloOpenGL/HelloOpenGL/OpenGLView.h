//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by AgPC on 14-8-23.
//  Copyright (c) 2014年 TwoEggs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>



@interface OpenGLView : UIView {
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    
    GLuint _positionSlot;
    GLuint _colorSlot;    
    
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    float _currentRotation;
    
    
    GLuint _depthRenderBuffer;
}


- (void) renderSensorData:(CADisplayLink*)displayLink;
- (IBAction)executeConnect:(id)sender;
- (void)loadDataFromServerWithURL:(NSURL *)url;

@end
