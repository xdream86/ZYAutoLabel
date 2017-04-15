//
//  ZYAutoLabel.m
//  ImageSlide
//
//  Created by zhuyongqing on 2017/4/6.
//  Copyright © 2017年 zhuyongqing. All rights reserved.
//

#import "ZYAutoLabel.h"
#import "UIView+ITTAdditions.h"

typedef NS_ENUM(NSInteger,ZYAutoLabelTouchType) {
    ZYAutoLabelTouchTypeLeftTop,
    ZYAutoLabelTouchTypeRightTop,
    ZYAutoLabelTouchTypeLeftBottom,
    ZYAutoLabelTouchTypeRifhtBottom,
};

@interface ZYAutoLabel()<UIGestureRecognizerDelegate>{
    UITouch *_lastTouch;
    CGPoint _lastPoint;
    
    CGPoint _viewPoint;
    
    CGRect _defalutRect;
    
    Float64 _scaleX;
    Float64 _scaleY;
    
    float _offSetX;
    float _offSetY;
}

@property(nonatomic,assign) CGFloat translateX;
@property(nonatomic,assign) CGFloat translateY;

@property(nonatomic,strong) UILabel *autoLabel;

@property(nonatomic,strong) UIView *touchView;

@property(nonatomic,strong) UIView *leftTop;

@property(nonatomic,strong) UIView *rightTop;

@property(nonatomic,strong) UIView *leftBottom;


@property(nonatomic,assign) double rotationAngle;

@property(nonatomic,strong) NSOperationQueue *rotationQueue;

@property(nonatomic,strong) UIView *boardView;


@property(nonatomic,assign) ZYAutoLabelTouchType touchType; //



@end

//static inline double radians (double degrees) {return degrees * M_PI/180;}
//static inline double degrees (double radians) {return radians * 180/M_PI;}

//CGFloat angleBetweenPoints(CGPoint first, CGPoint second) {
//    CGFloat height = second.y - first.y;
//    CGFloat width = first.x - second.x;
//    CGFloat rads = atan(height/width);
//    return degrees(rads);
//    //degs = degrees(atan((top - bottom)/(right - left)))
//}

#define KMaxWidth [UIScreen mainScreen].bounds.size.width
#define KMaxHeight [UIScreen mainScreen].bounds.size.height

#define KTouchViewWidth 10
#define KSpace 10
/** 随机色 */
#define KarcRandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]

@implementation ZYAutoLabel

- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
//        self.backgroundColor = [UIColor whiteColor];
//        self.layer.borderColor = [UIColor whiteColor].CGColor;
//        self.layer.borderWidth = 1;
        
        self.rotationQueue = [[NSOperationQueue alloc] init];
        self.rotationQueue.maxConcurrentOperationCount = 1;
        
        _autoLabel = [[UILabel alloc] init];
        _autoLabel.numberOfLines = 0;
        _autoLabel.adjustsFontSizeToFitWidth = YES;
        _autoLabel.font = [UIFont systemFontOfSize:100];
        _autoLabel.textColor = KarcRandomColor;
        _autoLabel.textAlignment = NSTextAlignmentCenter;
        _autoLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_autoLabel];
        
        _touchView = [self getTouchView];
        _leftTop = [self getTouchView];
        _rightTop = [self getTouchView];
        _leftBottom = [self getTouchView];
        
        [self addSubview:_leftTop];
        [self addSubview:_leftBottom];
        [self addSubview:_rightTop];
        [self addSubview:_touchView];
        
        _boardView = [[UIView alloc] init];
        _boardView.layer.borderColor = [UIColor whiteColor].CGColor;
        _boardView.backgroundColor = [UIColor clearColor];
        _boardView.opaque = YES;
        _boardView.layer.borderWidth = 1;
        [self addSubview:_boardView];
        
        UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchAndRotate:)];
        rotation.delegate = self;
        [self addGestureRecognizer:rotation];
        
        
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchAndRotate:)];
        [self addGestureRecognizer:pinch];
        _scaleY = 1;
        _scaleX = 1;
        
//        self.layer.anchorPoint = CGPointMake(0, 0);
    }
    return self;
}

#pragma mark - 初始化 设置 文字 大小
- (void)setText:(NSString *)text{
    _text = text;
    CGSize labelSize = [text boundingRectWithSize:CGSizeMake(KMaxWidth, KMaxHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:50]} context:nil].size;
    self.z_size = labelSize;
    self.center = CGPointMake(KMaxWidth/2, KMaxWidth/2);
    
    _defalutRect = self.frame;
    
    _autoLabel.text = text;
    
    _autoLabel.frame = CGRectMake(KSpace, KSpace, self.z_width - KTouchViewWidth*2, self.z_height - KTouchViewWidth*2);
    _boardView.frame = CGRectMake(KSpace/2, KSpace/2, self.z_width - KTouchViewWidth,self.z_height - KTouchViewWidth);
    
    [self layoutAutoLabelTouchViewWithRect:self.bounds];

}

- (void)layoutAutoLabelTouchViewWithRect:(CGRect)bounds{
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
    _touchView.frame = CGRectMake(width - KSpace, height - KSpace, KTouchViewWidth, KTouchViewWidth);
    _leftTop.frame = CGRectMake(0, 0, KTouchViewWidth, KTouchViewWidth);
    _rightTop.frame = CGRectMake(width - KSpace, 0, KTouchViewWidth, KTouchViewWidth);
    _leftBottom.frame = CGRectMake(0, height - KSpace, KTouchViewWidth, KTouchViewWidth);
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)layoutSubviews{
    if (self.z_left < -self.z_width || self.z_top < - self.z_height) {
        self.center = CGPointMake(KMaxWidth/2, KMaxHeight/2);
    }
    
    if (self.z_left > KMaxWidth || self.z_top > KMaxHeight) {
        self.center = CGPointMake(KMaxWidth/2, KMaxHeight/2);
    }
    
    [super layoutSubviews];
}


- (BOOL)isContainsViewWithPoint:(CGPoint)point{
    
    BOOL leftTop = [self jugeTouchView:self.leftTop containPoint:point];
    BOOL rightTop = [self jugeTouchView:self.rightTop containPoint:point];
    BOOL leftBottom = [self jugeTouchView:self.leftBottom containPoint:point];
    BOOL rightBottom = [self jugeTouchView:self.touchView containPoint:point];
    
    if (!leftTop && !leftBottom && !rightTop && !rightBottom) {
        return NO;
    }
    if (leftTop) {
        self.touchType = ZYAutoLabelTouchTypeLeftTop;
    }else if (rightTop){
        self.touchType = ZYAutoLabelTouchTypeRightTop;
    }else if (leftBottom){
        self.touchType = ZYAutoLabelTouchTypeLeftBottom;
    }else if (rightBottom){
        self.touchType = ZYAutoLabelTouchTypeRifhtBottom;
    }
    return YES;
}

- (BOOL)jugeTouchView:(UIView *)touchView containPoint:(CGPoint)point{
    CGRect donwR = [self convertRect:touchView.frame toView:self.superview];
    donwR = CGRectMake(donwR.origin.x - 10, donwR.origin.y - 10, donwR.size.width + 10, donwR.size.height + 10);
    if (CGRectContainsPoint(donwR, point)) {
        return YES;
    }
    return NO;
}

#pragma mark - 手指点击 移动
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.superview];
    
    if ([self isContainsViewWithPoint:point]) {
        _lastTouch = touch;
        _lastPoint = point;
        
    }else if(touch.tapCount == 1){
        _viewPoint = point;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.superview];
    
    if (touch == _lastTouch) {
        
        //改变 锚点
//        [self changeTouchViewArchPoint];
        
        CGFloat offsetX = point.x - _lastPoint.x;
        CGFloat offsetY = point.y - _lastPoint.y;
        
//        if (self.z_width + offsetX > KMaxWidth || self.z_height + offsetY > KMaxHeight) {
//            return;
//        }
        
        if (self.z_width + offsetX < 50 || self.z_height + offsetY < 30) {
            return;
        }
        
        //改变 大小
        //计算 缩放的 比例
        CGFloat tempScaleX = (self.z_width + offsetX) / self.z_width;
        CGFloat tempScaleY = (self.z_height + offsetY) / self.z_height;
        
        _scaleX *= tempScaleX;
        _scaleY *= tempScaleY;
        
        [self.rotationQueue cancelAllOperations];
        [self.rotationQueue addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resizeFrame];
            });
        }];
        
        _lastPoint = point;
    }else if(touch.tapCount == 1){
        
        //移动位置
        CGFloat offsetX = point.x - _viewPoint.x;
        CGFloat offsetY = point.y - _viewPoint.y;
        
        [self.rotationQueue cancelAllOperations];
        [self.rotationQueue addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                CGAffineTransform t = CGAffineTransformTranslate(self.transform, 0, 0);
                self.transform = t;
                self.z_centerX += offsetX;
                self.z_centerY += offsetY;
            });
        }];
        
        _viewPoint = point;
    }
    
}



- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _lastTouch = nil;
    _lastPoint = CGPointZero;
    
    _viewPoint = CGPointZero;
}


#pragma mark - 更新界面大小
- (void)resizeFrame{
    
    self.transform = CGAffineTransformScale(self.transform, 1, 1);
    
    CGRect rect = CGRectZero;
    rect.size.width = _defalutRect.size.width * _scaleX;
    rect.size.height = _defalutRect.size.height * _scaleY;
    self.bounds = rect;
    self.autoLabel.z_size = CGSizeMake(rect.size.width - KSpace*2, rect.size.height - KSpace*2);
    self.autoLabel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.boardView.z_size = CGSizeMake(rect.size.width - KSpace, rect.size.height - KSpace);
    self.boardView.center = self.autoLabel.center;
    
    [self layoutAutoLabelTouchViewWithRect:rect];

    NSLog(@"%@",NSStringFromCGRect(self.frame));
}

- (void)handlePinchAndRotate:(UIGestureRecognizer *)gesture{
//    [gesture isKindOfClass:[UIPinchGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateChanged
    if ([gesture isKindOfClass:[UIPinchGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateChanged) {
        if (self.layer.anchorPoint.x != 0.5 || self.layer.anchorPoint.y != 0.5) {
            [self changeArchPointToCenter];
        }
        //缩放
        _scaleX *= [(UIPinchGestureRecognizer *)gesture scale];
        _scaleY *= [(UIPinchGestureRecognizer *)gesture scale];
        [self.rotationQueue cancelAllOperations];
        [self.rotationQueue addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resizeFrame];
            });
        }];
        [(UIPinchGestureRecognizer *)gesture setScale:1.0];
    }else if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateChanged){
        //旋转
        UIView *view = gesture.view;
        if (self.layer.anchorPoint.x != 0.5 || self.layer.anchorPoint.y != 0.5) {
            [self changeArchPointToCenter];
        }
        
        double angle = [(UIRotationGestureRecognizer *)gesture rotation];
        self.rotationAngle += angle;
        CGRect frame = self.frame;
        view.transform = CGAffineTransformRotate(view.transform, angle);
        [(UIRotationGestureRecognizer *)gesture setRotation:0];
        _offSetY += self.frame.origin.y - frame.origin.y;
        _offSetX += self.frame.origin.x - frame.origin.x;
        if ((self.rotationAngle > -0.01 && self.rotationAngle < 0) || (self.rotationAngle < 0.01 && self.rotationAngle > 0)) {
            _offSetX = 0;
            _offSetY = 0;
        }
        NSLog(@"%@",NSStringFromCGRect(self.frame));
        
    }

}

- (UIView *)getTouchView{
    UIView *touchView = [[UIView alloc] init];
    touchView.backgroundColor = [UIColor yellowColor];
    touchView.userInteractionEnabled = YES;
    touchView.layer.cornerRadius = KTouchViewWidth/2;
    touchView.clipsToBounds = YES;
    
    return touchView;
}

- (void)changeArchPointToCenter{
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    CGFloat centerX = self.center.x + self.frame.size.width/2;
    CGFloat centerY = self.center.y + self.frame.size.height/2;
    if (self.rotationAngle > 0) {
        centerX += _offSetY;
    }else{
        centerY += _offSetY*2;
    }
    self.layer.position = CGPointMake(centerX, centerY);
}

- (void)changeTouchViewArchPoint{
#warning 有问题 待修改
    switch (self.touchType) {
        case ZYAutoLabelTouchTypeLeftTop:{
            if (CGPointEqualToPoint(self.layer.anchorPoint, CGPointMake(1, 1))) {
                return;
            }
            CGPoint origin = self.frame.origin;
            CGFloat originX = origin.x + self.frame.size.width;
            CGFloat originY = origin.y + self.frame.size.height;
            if (self.rotationAngle > 0) {
                originY = origin.y - _offSetY*2;
                originX = origin.x - _offSetY*4;
            }else if(self.rotationAngle < 0){
//                originX +=  _offSetY;
                originY +=  _offSetY*2;
            }
            
            self.layer.anchorPoint = CGPointMake(1, 1);
            self.center = CGPointMake(originX, originY);
            
        }
            
            break;
        case ZYAutoLabelTouchTypeRightTop:{
            if (CGPointEqualToPoint(self.layer.anchorPoint, CGPointMake(0, 1))) {
                return;
            }
            CGPoint origin = self.frame.origin;
            CGFloat originX = origin.x;
            CGFloat originY = origin.y + self.frame.size.height;
            if (self.rotationAngle > 0) {
                originY = origin.y;
                originX = origin.x - _offSetY;
            }else if(self.rotationAngle < 0){
                originX += - _offSetY;
//                originY +=  - _offSetY;
            }
            
            self.layer.anchorPoint = CGPointMake(0, 1);
            self.center = CGPointMake(originX, originY);
        }
            break;
        case ZYAutoLabelTouchTypeRifhtBottom:{
            if (CGPointEqualToPoint(self.layer.anchorPoint, CGPointMake(0, 0))) {
                return;
            }
            CGPoint origin = self.frame.origin;
            CGFloat originX;
            CGFloat originY;
            if (self.rotationAngle > 0) {
                originY = origin.y;
                originX = origin.x - _offSetY;
            }else{
                originX = origin.x;
                originY = origin.y - _offSetY*2;
            }
            
            self.layer.anchorPoint = CGPointMake(0, 0);
            self.center = CGPointMake(originX, originY);
        }
            
            break;
        case ZYAutoLabelTouchTypeLeftBottom:{
            if (CGPointEqualToPoint(self.layer.anchorPoint, CGPointMake(1, 0))) {
                return;
            }
            CGPoint origin = self.frame.origin;
            CGFloat originX = origin.x + self.frame.size.width;
            CGFloat originY = origin.y;
            if (self.rotationAngle > 0) {
                originY = origin.y;
                originX = origin.x - _offSetY;
            }else if(self.rotationAngle < 0){
//                originX += - _offSetY*2;
                //                originY +=  - _offSetY;
            }
            
            self.layer.anchorPoint = CGPointMake(1, 0);
            self.center = CGPointMake(originX, originY);
        }
            
            break;
        default:
            break;
    }
    
}
 
@end
