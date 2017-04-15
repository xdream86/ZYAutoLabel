//
//  ZYSubtitleLabel.m
//  ZYAutoResizeLabel
//
//  Created by Aegaeon on 15/04/2017.
//  Copyright © 2017 zhuyongqing. All rights reserved.
//

#import "ZYSubtitleLabel.h"

#define CGPointNull CGPointMake(NSNotFound, NSNotFound)

struct ZYCornerPoints {
    CGPoint topLeft;
    CGPoint topRight;
    CGPoint bottomLeft;
    CGPoint bottomRight;
};

typedef struct ZYCornerPoints ZYCornerPoints;

CGRect ZYCornerPointsExpandPoint(CGPoint point, CGFloat delta) {
    return CGRectMake(point.x - delta, point.y - delta, delta * 2, delta * 2);
}

CGPoint ZYCornerPointsContainPoint(ZYCornerPoints cornerPoints, CGPoint point) {
    CGFloat delta = 10;
    if (CGRectContainsPoint(ZYCornerPointsExpandPoint(cornerPoints.topLeft, delta), point)) {
        return cornerPoints.topLeft;
    }
    
    if (CGRectContainsPoint(ZYCornerPointsExpandPoint(cornerPoints.topRight, delta), point)) {
        return cornerPoints.topRight;
    }
    
    if (CGRectContainsPoint(ZYCornerPointsExpandPoint(cornerPoints.bottomLeft, delta), point)) {
        return cornerPoints.bottomLeft;
    }
    
    if (CGRectContainsPoint(ZYCornerPointsExpandPoint(cornerPoints.bottomRight, delta), point)) {
        return cornerPoints.bottomRight;
    }
    
    return CGPointNull;
}

@interface ZYSubtitleLabel()
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, assign)  CGPoint nearCornerPoint;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationGestureRecognizer;

@end

@implementation ZYSubtitleLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self addSubview:self.subtitleLabel];
    [self addGestureRecognizer:self.longPressGestureRecognizer];
        [self addGestureRecognizer:self.pinchGestureRecognizer];
        [self addGestureRecognizer:self.rotationGestureRecognizer];
    
    self.subtitleLabel.frame = CGRectInset(self.bounds, 10, 10);
    self.multipleTouchEnabled = YES;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.subtitleLabel.layer.borderColor = [UIColor redColor].CGColor;
    self.subtitleLabel.layer.borderWidth = 1.0f;
    
    return self;
}

#pragma mark - Action
- (void)longPressGestureRecognizerHandler:(UILongPressGestureRecognizer *)sender {
    static CGPoint startLocation;
    static CGAffineTransform startTransform;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            startLocation = [sender locationInView:self.superview];
            startTransform = self.transform;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat deltaX = [sender locationInView:self.superview].x * 1.0 - startLocation.x * 1.0;
            CGFloat deltaY = [sender locationInView:self.superview].y * 1.0 - startLocation.y * 1.0;
            
            self.transform = CGAffineTransformConcat(startTransform, CGAffineTransformTranslate(CGAffineTransformIdentity, deltaX, deltaY));
        }
            break;
        default:
            break;
    }
}

- (void)pinchGestureRecognizerHandler:(UIPinchGestureRecognizer *)sender {
    static CGAffineTransform transform;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            transform = self.transform;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.transform = CGAffineTransformConcat(transform, CGAffineTransformScale(CGAffineTransformIdentity, sender.scale, sender.scale));
        }
            break;
        default:
            break;
    }
}

- (void)rotationGestureRecognizerHandler:(UIRotationGestureRecognizer *)sender {
    static CGAffineTransform transform;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            transform = self.transform;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.transform = CGAffineTransformConcat(transform, CGAffineTransformRotate(CGAffineTransformIdentity, sender.rotation));
        }
            break;
        default:
            break;
    }
}

- (ZYCornerPoints)cornerPoints {
    CGPoint originalCenter = CGPointApplyAffineTransform(self.center, CGAffineTransformInvert(self.transform));
    
    CGPoint topLeft = originalCenter;
    topLeft.x -= self.bounds.size.width / 2;
    topLeft.y -= self.bounds.size.height / 2;
    topLeft = CGPointApplyAffineTransform(topLeft, self.transform);
    
    CGPoint topRight = originalCenter;
    topRight.x += self.bounds.size.width / 2;
    topRight.y -= self.bounds.size.height / 2;
    topRight = CGPointApplyAffineTransform(topRight, self.transform);
    
    CGPoint bottomLeft = originalCenter;
    bottomLeft.x -= self.bounds.size.width / 2;
    bottomLeft.y += self.bounds.size.height / 2;
    bottomLeft = CGPointApplyAffineTransform(bottomLeft, self.transform);
    
    CGPoint bottomRight = originalCenter;
    bottomRight.x += self.bounds.size.width / 2;
    bottomRight.y += self.bounds.size.height / 2;
    bottomRight = CGPointApplyAffineTransform(bottomRight, self.transform);
    
    ZYCornerPoints cornerPoint = {.topLeft = topLeft, .topRight = topRight, .bottomLeft = bottomLeft, .bottomRight = bottomRight};
    
    return cornerPoint;
}

#pragma mark - Getter Setter
- (void)setText:(NSString *)text {
    _text = text;
    self.subtitleLabel.text = text;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [UILabel new];
        _subtitleLabel.textColor = [UIColor whiteColor];
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.adjustsFontSizeToFitWidth = YES;
        _subtitleLabel.font = [UIFont systemFontOfSize:100];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return _subtitleLabel;
}

- (UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (!_longPressGestureRecognizer) {
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerHandler:)];
        _longPressGestureRecognizer.minimumPressDuration = 0;
    }
    return _longPressGestureRecognizer;
}

- (UIPinchGestureRecognizer *)pinchGestureRecognizer {
    if (!_pinchGestureRecognizer) {
        _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerHandler:)];
    }
    return _pinchGestureRecognizer;
}

- (UIRotationGestureRecognizer *)rotationGestureRecognizer {
    if (!_rotationGestureRecognizer) {
        _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureRecognizerHandler:)];
    }
    return _rotationGestureRecognizer;
}

@end
