#import <UIKit/UIKit.h>
#import "CameraManager.h"

@interface CameraViewController : UIViewController<CameraManagerDelegate>
@property (nonatomic) BOOL adjustingExposure;

@end
