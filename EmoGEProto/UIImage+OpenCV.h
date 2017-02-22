#import <UIKit/UIKit.h>
//#ifdef __cplusplus
#import <opencv2/opencv.hpp>
//#endif

@interface UIImage (OpenCV)
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat image:(UIImage *)image;
+ (UIImage *)grayScale:(UIImage *)image;
@end
