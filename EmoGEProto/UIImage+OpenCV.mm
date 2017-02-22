#import "UIImage+OpenCV.h"

@implementation UIImage (OpenCV)

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    NSLog(@"cvMatFromUIImage");
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    
    cv::Mat cvMat(rows,cols,CV_8UC4);
    CGContextRef contextRef;
    contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    return cvMat;
}


+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat image:(UIImage *)image {
    NSLog(@"UIImageFromCVMat");
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if(cvMat.elemSize() == 1){
        colorSpace = CGColorSpaceCreateDeviceGray();
    }else{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider;
    provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef;
    imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8*cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}

+ (UIImage *)grayScale:(UIImage *)image {
    NSLog(@"grayScale");
    
    cv::Mat srcMat = [UIImage cvMatFromUIImage:image];
    cv::Mat grayMat;
    cv::cvtColor(srcMat, grayMat, CV_BGR2GRAY);
    return [UIImage UIImageFromCVMat:grayMat image:image];
}

@end
