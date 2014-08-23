//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by AgPC on 14-8-23.
//  Copyright (c) 2014年 TwoEggs. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <netdb.h>

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

#include "DataQueue.h"
#include "DataProtocol.h"
#include "ZSyncObj.h"


@implementation OpenGLView


typedef struct {
    float Position[3];
    float Color[4];
} Vertex;


/*
const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}};
*/

/* // Modify vertices so they are within projection near/far planes
const Vertex Vertices[] = {
    {{1, -1, -7}, {1, 0, 0, 1}},
    {{1, 1, -7}, {0, 1, 0, 1}},
    {{-1, 1, -7}, {0, 0, 1, 1}},
    {{-1, -1, -7}, {0, 0, 0, 1}}
};
*/

/* // Revert vertices back to z-value 0
const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};
*/
const Vertex Vertices[] = {
    {{ 2, -1,  0}, {0, 1, 0, 1}},
    {{ 2,  1,  0}, {0, 0, 1, 1}},
    {{-2,  1,  0}, {1, 0, 0, 1}},
    {{-2, -1,  0}, {0, 0, 1, 1}},
    {{ 2, -1, -0.5}, {0, 0, 1, 1}},
    {{ 2,  1, -0.5}, {1, 0, 0, 1}},
    {{-2,  1, -0.5}, {0, 1, 0, 1}},
    {{-2, -1, -0.5}, {1, 0, 0, 1}}
};

/*
 const GLubyte Indices[] = {
 0, 1, 2,
 2, 3, 0};
 */

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};


typedef struct {
	bool bUpdated;
	DataQueue<float, 16> qDataQueue;
}SensorRcvData;

SensorRcvData sSensorRcvData;

ZSyncObj zSyncObj;
float qSensorData[4];

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    
    // Add to bottom of compileShaders
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    
    // Add to end of compileShaders
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    
}

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}


// Replace initWithFrame with this
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        
        // Add to initWithFrame, right before call to setupRenderBuffer
        [self setupDepthBuffer];
        
        [self setupRenderBuffer];
        [self setupFrameBuffer];        
        
        [self compileShaders];
        [self setupVBOs];
        
        [self setupDisplayLink];
        
        [self executeConnect:nil];
    }
    return self;
}

// Replace dealloc method with this
- (void)dealloc
{
    [_context release];
    _context = nil;
    [super dealloc];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

// Add new method right after setupRenderBuffer
- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    // Add to end of setupFrameBuffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

// Add new method before init
- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderSensorData:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) renderSensorData:(CADisplayLink*)displayLink {
    
   	bool bSnsUpdated = false;
	zSyncObj.SyncStart();
	bSnsUpdated = sSensorRcvData.bUpdated;
	if (sSensorRcvData.bUpdated)
	{
		for (int i=0; i< 4; i++)
		{
			sSensorRcvData.qDataQueue.pop(qSensorData[i]);
		}
	}
	else
	{
		memset(qSensorData, 0, sizeof(qSensorData));
	}
	zSyncObj.SyncEnd();
    
	if (bSnsUpdated)
	{
		for (int i=0; i< 4; i++)
		{
			[self render:displayLink];
		}
	}
	else
	{
		[self render:displayLink];
	}
}


- (void)render:(CADisplayLink*)displayLink {
    /* //sample1
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    */
    
    /* //sample2
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    */
    
    // In the render method, replace the call to glClear with the following
    glClearColor(1, 1, 1, 1.0); //white background
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    
    // Add to render, right before the call to glViewport
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h =4.0f* self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    // Add to render, right before call to glViewport
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    CC3Vector cc3v;
    cc3v.x = 0;
    cc3v.y = 0;
    cc3v.z = -7;
    [modelView populateFromTranslation:cc3v];
    //add rotation
    //_currentRotation += displayLink.duration *90;
    //[modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    
    //quarts
    CC3Vector4 cc3v4;
    cc3v4.x = qSensorData[2];
    cc3v4.y = -qSensorData[1];
    cc3v4.z = -qSensorData[3];
    cc3v4.w = qSensorData[0];
    
    [modelView rotateByQuaternion:cc3v4];
    
    //matrix
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    [_context presentRenderbuffer:GL_RENDERBUFFER];

    
}



- (IBAction)executeConnect:(id)sender
{
    NSURL *url = [NSURL URLWithString:@""];
    
    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(loadDataFromServerWithURL:)
                                                            object:url];
    [backgroundThread start];
    
}

- (void)loadDataFromServerWithURL:(NSURL *)url
{
    NSString * host = @"10.0.0.31";
    NSNumber * port = [[NSNumber alloc] initWithInt:4000];;
    
    // Create socket
    //
    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == socketFileDescriptor) {
        NSLog(@"Failed to create socket.");
        return;
    }
    
    // Get IP address from host
    //
    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
    if (NULL == remoteHostEnt) {
        close(socketFileDescriptor);
        
        //[self networkFailedWithErrorMessage:@"Unable to resolve the hostname of the warehouse server."];
        return;
    }
    
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    
    // Set the socket parameters
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET;
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons([port intValue]);
    
    // Connect the socket
    //
    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (-1 == ret) {
        close(socketFileDescriptor);
        
        NSString * errorInfo = [NSString stringWithFormat:@" >> Failed to connect to %@:%@", host, port];
        //[self networkFailedWithErrorMessage:errorInfo];
        return;
    }
    
    NSLog(@" >> Successfully connected to %@:%@", host, port);
    
    // Continually receive data until we reach the end of the data
    //
    unsigned char DataBuffer[256];
    int length = sizeof(DataBuffer);
    float fSensorData[16];
    
    while (1) {
        
        
        // Read a buffer's amount of data from the socket; the number of bytes read is returned
        int nDataSize = recv(socketFileDescriptor, (char*)DataBuffer, length, 0);
        if (nDataSize < 0) {
            printf("Receive Data Error!\n");
            break;
        }
        else if ( nDataSize == 0 )
        {
			printf("server shutdown ok. Error!\n");
            break;
        }
        
		//UnpackSensorData(DataBuffer, nDataSize);
		int nSize = 0;
		bool bDec = DecodeData(DataBuffer, nDataSize, fSensorData, &nSize);
		if (bDec && nSize == 16)
		{
            /*
			//ok
			printf("Data=%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n",
                   fSensorData[0], fSensorData[1], fSensorData[2], fSensorData[3],
                   fSensorData[4], fSensorData[5], fSensorData[6], fSensorData[7],
                   fSensorData[8], fSensorData[9], fSensorData[10], fSensorData[11],
                   fSensorData[12], fSensorData[13], fSensorData[14], fSensorData[15]);
            */
            zSyncObj.SyncStart();
			sSensorRcvData.bUpdated = true;
			for(int i=0; i<16; i++)
			{
				sSensorRcvData.qDataQueue.push(fSensorData[i]);
			}
			zSyncObj.SyncEnd();

		}
		else
		{
			printf("Rcv Data Error!");
		}
        
    }
    
    // Close the socket
    //
    close(socketFileDescriptor);
    
    //[self networkSucceedWithData:data];
}





@end
