#import "GPUImageOrchidFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@implementation GPUImageOrchidFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"Orchid.png"];
#else
    NSImage *image = [NSImage imageNamed:@"Orchid.png"];
#endif
    
    NSAssert(image, @"To use GPUImageOrchidFilter you need to add Orchid.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];

    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end
