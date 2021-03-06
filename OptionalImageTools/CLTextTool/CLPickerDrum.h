//
//  CLPickerDrum.h
//
//  Created by Kevin Siml - Appzer.de on 2015/12/15.
//  Copyright (c) 2015 Appzer.de. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLPickerDrumDataSource;
@protocol CLPickerDrumDelegate;


@interface CLPickerDrum : UIView

@property (nonatomic, weak) id<CLPickerDrumDataSource> dataSource;
@property (nonatomic, weak) id<CLPickerDrumDelegate> delegate;
@property (nonatomic, strong) UIColor *foregroundColor;

- (void)reload;
- (void)selectRow:(NSInteger)row animated:(BOOL)animated;
- (NSInteger)selectedRow;

@end




@protocol CLPickerDrumDataSource <NSObject>
@required
- (NSInteger)numberOfRowsInPickerDrum:(CLPickerDrum *)pickerDrum;

@end


@protocol CLPickerDrumDelegate <NSObject>
@optional
- (CGFloat)rowHeightInPickerDrum:(CLPickerDrum *)pickerDrum;
- (UIView*)pickerDrum:(CLPickerDrum *)pickerDrum viewForRow:(NSInteger)row reusingView:(UIView *)view;
- (NSString *)pickerDrum:(CLPickerDrum *)pickerDrum titleForRow:(NSInteger)row;
- (void)pickerDrum:(CLPickerDrum *)pickerDrum didSelectRow:(NSInteger)row;

@end
