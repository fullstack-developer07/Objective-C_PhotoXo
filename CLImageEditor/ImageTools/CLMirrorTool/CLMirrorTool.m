//
//  CLMirrorTool.m
//
//  Created by Kevin Siml - Appzer.de on 2015/10/23.
//  Copyright (c) 2015 Appzer.de. All rights reserved.
//

#import "CLMirrorTool.h"


@interface CLMirrorTool()
@property (nonatomic, strong) UIView *selectedMenu;
@property (nonatomic, strong) CLMirrorBase *selectedMirror;
@end


@implementation CLMirrorTool
{
    UIImage *_originalImage;
    UIImage *_thumnailImage;
    
    UIScrollView *_menuScroll;
    UIActivityIndicatorView *_indicatorView;
}

+ (NSArray*)subtools
{
    return [CLImageToolInfo toolsWithToolClass:[CLMirrorBase class]];
}

+ (NSString*)defaultTitle
{
    return NSLocalizedStringWithDefaultValue(@"CLMirrorTool_DefaultTitle", nil, [CLImageEditorTheme bundle], @"Mirror", @"");
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 5;
}

#pragma mark- 

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    _thumnailImage = self.editor.imageView.image;
    //_thumnailImage = [_originalImage resize:self.editor.imageView.frame.size];
    _thumnailImage = [_originalImage resize:CGSizeMake(self.editor.imageView.frame.size.width*2,self.editor.imageView.frame.size.height*2)];
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    [self setMirrorMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.selectedMirror cleanup];
    [_indicatorView removeFromSuperview];
    
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void(^)(UIImage *image, NSError *error, NSDictionary *userInfo))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _indicatorView = [CLImageEditorTheme indicatorView];
        _indicatorView.center = self.editor.view.center;
        [self.editor.view addSubview:_indicatorView];
        [_indicatorView startAnimating];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self.selectedMirror applyMirror:_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark- 

- (void)setMirrorMenu
{
    CGFloat W = 70;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;
    
    for(CLImageToolInfo *info in self.toolInfo.sortedSubtools){
        if(!info.available){
            continue;
        }
        
        CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedMenu:) toolInfo:info];

        [_menuScroll addSubview:view];
        x += W;
        
        if(self.selectedMenu==nil){
            self.selectedMenu = view;
        }
    }
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(-300, 0, x+600, 100);
    UIColor *startColour = [[UIColor whiteColor] colorWithAlphaComponent:0.0];
    UIColor *endColour = [[UIColor whiteColor] colorWithAlphaComponent:1.0];
    gradient.colors = [NSArray arrayWithObjects:(id)[startColour CGColor], (id)[endColour CGColor], nil];
    [_menuScroll.layer insertSublayer:gradient atIndex:0];
}

- (void)tappedMenu:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
    
    self.selectedMenu = view;
}

- (void)setSelectedMenu:(UIView *)selectedMenu
{
    if(selectedMenu != _selectedMenu){
        _selectedMenu.backgroundColor = [UIColor clearColor];
        _selectedMenu = selectedMenu;
        _selectedMenu.backgroundColor = [CLImageEditorTheme toolbarSelectedButtonColor];
        _selectedMenu.layer.cornerRadius = 5.0;
        _selectedMenu.layer.masksToBounds = YES;
        
        Class MirrorClass = NSClassFromString(_selectedMenu.toolInfo.toolName);
        self.selectedMirror = [[MirrorClass alloc] initWithSuperView:self.editor.imageView.superview imageViewFrame:self.editor.imageView.frame toolInfo:_selectedMenu.toolInfo];
    }
}

- (void)setSelectedMirror:(CLMirrorBase *)selectedMirror
{
    if(selectedMirror != _selectedMirror){
        [_selectedMirror cleanup];
        _selectedMirror = selectedMirror;
        _selectedMirror.delegate = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildThumnailImage];
        });
    }
}

- (void)buildThumnailImage
{
    UIImage *image;
    if(self.selectedMirror.needsThumnailPreview){
        image = [self.selectedMirror applyMirror:_thumnailImage];
    }
    else{
        image = [self.selectedMirror applyMirror:_originalImage];
    }
    [self.editor.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
}

#pragma mark- CLMirror delegate

- (void)MirrorParameterDidChange:(CLMirrorBase *)Mirror
{
    if(Mirror == self.selectedMirror){
        static BOOL inProgress = NO;
        
        if(inProgress){ return; }
        inProgress = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildThumnailImage];
            inProgress = NO;
        });
    }
}

@end
