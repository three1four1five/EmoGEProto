#import <UIKit/UIKit.h>
#import "CameraManager.h"

@interface CameraViewController : UIViewController<CameraManagerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) BOOL adjustingExposure;

@end
