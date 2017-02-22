#import "PhotoCell.h"

@interface PhotoCell ()
@end

@implementation PhotoCell

- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    typeof(self) __weak wself = self;
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:CGSizeMake(300,300)
                                              contentMode:PHImageContentModeAspectFill
                                                  options:nil
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                if (result) {
                                                    wself.photoImageView.image = result;
                                                }
                                            }];
}

@end
