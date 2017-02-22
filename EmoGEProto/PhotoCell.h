#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface PhotoCell : UICollectionViewCell
@property (nonatomic) PHAsset *asset;
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@end
