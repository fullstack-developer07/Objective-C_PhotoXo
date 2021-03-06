//
//  CLDotEffect.m
//
//  Created by Kevin Siml - Appzer.de on 2015/10/23.
//  Copyright (c) 2015 Appzer.de. All rights reserved.
//

#import "CLDotEffect.h"

#import "UIImage+Utility.h"
#import "UIView+Frame.h"

@implementation CLDotEffect
{
    UIView *_containerView;
    UISlider *_radiusSlider;
    UISlider *_intensitySlider;
    UISlider *_positionSlider;
    NSDate *lastCallSlider;
}

#pragma mark-

+ (NSString*)defaultTitle
{
    return NSLocalizedStringWithDefaultValue(@"CLDotEffect_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Dots", @"");
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 6.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 22;
}

- (id)initWithSuperView:(UIView*)superview imageViewFrame:(CGRect)frame toolInfo:(CLImageToolInfo *)info
{
    self = [super initWithSuperView:superview imageViewFrame:frame toolInfo:info];
    if(self){
        _containerView = [[UIView alloc] initWithFrame:superview.bounds];
        [superview addSubview:_containerView];
        
        [self setUserInterface];
    }
    lastCallSlider=[NSDate date];
    return self;
}

- (void)cleanup
{
    [_containerView removeFromSuperview];
}

- (UIImage*)applyEffect:(UIImage*)image
{
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIDotScreen" keysAndValues:kCIInputImageKey, ciImage, nil];
    
    //NSLog(@"%@", [filter attributes]);
    
    [filter setDefaults];
    
    [filter setValue:[NSNumber numberWithFloat:_radiusSlider.value] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:_intensitySlider.value] forKey:@"inputSharpness"];
    [filter setValue:[NSNumber numberWithFloat:_positionSlider.value] forKey:@"inputAngle"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    CGFloat dW = (result.size.width - image.size.width)/2;
    CGFloat dH = (result.size.height - image.size.height)/2;
    
    CGRect rct = CGRectMake(dW, dH, image.size.width, image.size.height);
    
    return [result crop:rct];
}

#pragma mark-

- (UISlider*)sliderWithValue:(CGFloat)value minimumValue:(CGFloat)min maximumValue:(CGFloat)max
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 260, 30)];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, slider.height)];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    container.layer.cornerRadius = slider.height/2;
    
    slider.continuous = YES;
    [slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
    
    slider.maximumValue = max;
    slider.minimumValue = min;
    slider.value = value;
    
    [container addSubview:slider];
    [_containerView addSubview:container];
    
    return slider;
}

- (void)setUserInterface
{
    _radiusSlider = [self sliderWithValue:100 minimumValue:0 maximumValue:200];
    _radiusSlider.superview.center = CGPointMake(_containerView.width/2, _containerView.height-30);
    
    _intensitySlider = [self sliderWithValue:0.5 minimumValue:0 maximumValue:1.0];
    _intensitySlider.superview.center = CGPointMake([[UIScreen mainScreen] applicationFrame].size.width-20, _radiusSlider.superview.top - 150);
    _intensitySlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
    
    _positionSlider = [self sliderWithValue:0 minimumValue:0 maximumValue:7];
    _positionSlider.superview.center = CGPointMake(20, _radiusSlider.superview.top-150);
    _positionSlider.superview.transform = CGAffineTransformMakeRotation(-M_PI * 90 / 180.0f);
}

- (void)sliderDidChange:(UISlider*)sender
{
    NSDate *nowCall = [NSDate date];// timestamp
    if ([nowCall timeIntervalSinceDate:lastCallSlider] > 0.11) {
        [self.delegate effectParameterDidChange:self];
        lastCallSlider = nowCall;
    }
}

@end
