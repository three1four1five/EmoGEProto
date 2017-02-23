#import "CameraViewController.h"
#import <AudioToolbox/AudioToolbox.h>
//#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "EditViewController.h"
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>

@interface CameraViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *captureView;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel;

@property CameraManager* captureManager;  // 動画マネージャクラス
//@property uint8_t captureType;               // キャプチャの方法(0:カメラ, 1:動画)
@property (nonatomic, strong) CALayer* indicatorLayer;  // ピント合わせる用のレイヤ

@property CIDetector *detector;
//@property (nonatomic, strong) CALayer *faceRectLayer;

@end

#define INDICATOR_RECT_SIZE 50.0

@implementation CameraViewController {
    BOOL _isNeededToSave;
    CGFloat _beginGestureScale;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.captureType = CAPTURE_TYPE_CAMERA; // 初期はカメラでキャプチャ
//    self.statusLabel.hidden = YES; // カメラなので時間ラベルは非表示
    
    // シャッターボタンを設定
//    UIImage *image;
//    image = [UIImage imageNamed:@"ShutterButtonStart"];
//    self.recStartImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    image = [UIImage imageNamed:@"ShutterButtonStop"];
//    self.recStopImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.recBtn setImage:self.recStartImage
//                 forState:UIControlStateNormal];
//    [self.recBtn setTintColor:[UIColor colorWithRed:245./255.
//                                              green:51./255.
//                                               blue:51./255.
//                                              alpha:1.0]];
    
    self.captureManager = [[CameraManager alloc] init];         // カメラクラスを初期化
    
    self.captureManager.delegate = self;
    [self.captureManager setPreview:_previewView];   // プレビューレイヤを設定
    
    // フォーカス位置を探す
    _indicatorLayer = [CALayer layer];
    _indicatorLayer.borderColor = [[UIColor yellowColor] CGColor];
    _indicatorLayer.borderWidth = 1.0;
    _indicatorLayer.cornerRadius = 3.0f;
    _indicatorLayer.masksToBounds = YES;
//    _indicatorLayer.frame = CGRectMake(self.view.bounds.size.width/2.0 - INDICATOR_RECT_SIZE/2.0,
//                                           self.view.bounds.size.height/2.0 - INDICATOR_RECT_SIZE/2.0,
//                                           INDICATOR_RECT_SIZE,
//                                           INDICATOR_RECT_SIZE);
//    self.indicatorLayer.hidden = NO;
    [self.view.layer addSublayer:_indicatorLayer];

//    _faceRectLayer = [CALayer layer];
//    _faceRectLayer.borderColor = [UIColor yellowColor].CGColor;
//    _faceRectLayer.borderWidth = 1.0f;
//    _faceRectLayer.cornerRadius = 3.0f;
//    _faceRectLayer.masksToBounds = YES;
//    [self.view.layer addSublayer:self.faceRectLayer];
    
    // ジェスチャ監視
    UIGestureRecognizer* gr = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(didTapGesture:)];
    [self.view addGestureRecognizer:gr];
    UIGestureRecognizer *recognizer = [[UIPinchGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(pinchedGesture:)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];

    
    // Face detection
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                        forKey:CIDetectorAccuracy];
    _detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                   context:nil
                                   options:options];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 回転禁止
- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark -
#pragma mark Action

- (IBAction)albumButtonAction:(UIButton *)sender {
    NSLog(@"albumButtonAction");
}

- (IBAction)shutterAction:(UIButton *)sender {
    NSLog(@"shutterAction");
    [_captureManager takePhoto:^(UIImage *image, NSError *error) {
        // 静止画保存ここでやってる
//        _captureView.image = image;
//        [self saveCaptureFile:image];
        
        [self pushEditViewController:image];
    }];
    if (!_captureManager.previewLayer) {
        UIImage *image = [UIImage imageNamed:@"SamplePhoto"];
        [self pushEditViewController:image];
    }
    //UIImage *prevImage = [_captureManager takeCapture];
    //_captureview.image = prevImage;
}

// 前後カメラ切り替え
- (IBAction)flipAction:(UIButton *)sender {
    [self.captureManager flipCamera];
}

// ライト切り替え
- (IBAction)lightAction:(UIButton *)sender {
    [self.captureManager lightToggle];
}

#pragma -
#pragma mark - Move Screen

- (void)pushEditViewController:(UIImage *)image {
    EditViewController *editViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"EditViewController"];
    editViewController.image = image;
    [self.navigationController pushViewController:editViewController animated:YES];
}


#pragma -
#pragma mark - Save function

// 静止画を保存する
- (void)saveCaptureFile:(UIImage*)captureImage {
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    [library writeImageToSavedPhotosAlbum:captureImage.CGImage
//                              orientation:(ALAssetOrientation)captureImage.imageOrientation // 明示的に
//                          completionBlock:^(NSURL *assetURL, NSError *error) {
//                              NSLog(@"saved");
//                          }];
    
    PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
    [library performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:captureImage];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"saved");
    }];
}



#pragma -
#pragma mark - フォーカス位置指定など

- (void)setPoint:(CGPoint)p {
    CGSize viewSize = self.view.bounds.size;
    CGPoint pointOfInterest = CGPointMake(p.y / viewSize.height,
                                          1.0 - p.x / viewSize.width);
    
    AVCaptureDevice* videoCaptureDevice = _captureManager.backCameraDevice;
    NSError* error = nil;
    if ([videoCaptureDevice lockForConfiguration:&error]) {
        // フォーカスの場合は、この値を focusPointOfInterest へ渡し、focusMode を設定すれば良い
        if ([videoCaptureDevice isFocusPointOfInterestSupported] &&
            [videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            videoCaptureDevice.focusPointOfInterest = pointOfInterest;
            videoCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        // 露出の方は、exposurePointOfInterest 渡すだけでは駄目で、もう少し手間が必要
        if ([videoCaptureDevice isExposurePointOfInterestSupported] &&
            [videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            self.adjustingExposure = YES;
            videoCaptureDevice.exposurePointOfInterest = pointOfInterest;
            videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        [videoCaptureDevice unlockForConfiguration];
    }
    else {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
    }
}

// 監視を設定しておき値が変化したら処理をする
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context {
    if (!self.adjustingExposure) {
        return;
    }
    
    if ([keyPath isEqual:@"adjustingExposure"]) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO) {
            self.adjustingExposure = NO;
            AVCaptureDevice* videoCaptureDevice = _captureManager.backCameraDevice;
            NSError *error = nil;
            if ([videoCaptureDevice lockForConfiguration:&error]) {
                NSLog(@"%s|%@", __PRETTY_FUNCTION__, @"locked!");
                [videoCaptureDevice setExposureMode:AVCaptureExposureModeLocked];
                [videoCaptureDevice unlockForConfiguration];
            }
        }
    }
}

// タップを検知
- (void)didTapGesture:(UITapGestureRecognizer*)tgr {
    CGPoint p = [tgr locationInView:tgr.view];
    //NSLog(@"*** x:%f y:%f", p.x, p.y);
    
    // プレビュー画面の範囲内の場合のみ移動する処理をする
//    if (p.x > 320 || p.y < 60 || p.y > 410) {
//        return;
//    }
    
    // フォーカスポイント移動
    self.indicatorLayer.frame = CGRectMake(p.x - INDICATOR_RECT_SIZE/2.0,
                                           p.y - INDICATOR_RECT_SIZE/2.0,
                                           INDICATOR_RECT_SIZE,
                                           INDICATOR_RECT_SIZE);
    
    [self setPoint:p];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        AVCaptureDevice *camera;
        if(_captureManager.isUsingFrontCamera) {
            camera = _captureManager.frontCameraDevice;
        } else {
            camera = _captureManager.backCameraDevice;
        }
        CGFloat currentZoomScale = camera.videoZoomFactor;
        _beginGestureScale = currentZoomScale;
    }
    return YES;
}

// ピンチを検知
- (void)pinchedGesture:(UIPinchGestureRecognizer *)recognizer {

    AVCaptureDevice *camera;
    if(_captureManager.isUsingFrontCamera) {
        camera = _captureManager.frontCameraDevice;
    } else {
        camera = _captureManager.backCameraDevice;
    }
    
    [camera lockForConfiguration:nil];

    CGFloat maxZoomScale = 6.0f;
    CGFloat minZoomScale = 1.0f;
    
    CGFloat currentZoomScale = _beginGestureScale * recognizer.scale;
    currentZoomScale = MAX(currentZoomScale, minZoomScale);
    currentZoomScale = MIN(currentZoomScale, maxZoomScale);

    _scaleLabel.text = [NSString stringWithFormat:@"%f", currentZoomScale];
    camera.videoZoomFactor = currentZoomScale;
    [camera unlockForConfiguration];
}

#pragma -
#pragma mark - CameraManagerDelegate

//- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
//    NSLog(@"didFinishRecordingToOutputFileAtURL");
//    if (error) {
//        NSLog(@"error:%@", error);
//        return;
//    }
//    
//    if (!_isNeededToSave) {
//        return;
//    }
//    
//    [self saveRecordedFile:outputFileURL];
//}

// リアルタイムにエフェクトかける場合に利用
-(void)videoFrameUpdate:(CGImageRef)cgImage sampleBuffer:(CMSampleBufferRef)sampleBuffer{
//    UIImage* imageRotate = [CameraManager rotateImage:[UIImage imageWithCGImage:cgImage] angle:270];
//    if(captureManager.isUsingFrontCamera)
//        imageRotate = [self mirrorImage:imageRotate];
//    _previewView.image = imageRotate;

//    LOG_CURRENT_METHOD;
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:cgImage];
    
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT          = 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT         = 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    NSInteger exifOrientation;
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation]
                                                             forKey:CIDetectorImageOrientation];
    NSArray *faceFeatures = [_detector featuresInImage:ciImage options:imageOptions];
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false);

    typeof(self) __weak wself = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [wself drawFaceBoxesForFeatures:faceFeatures clap:clap orientation:curDeviceOrientation];
    });

//    for (CIFaceFeature *faceFeature in faceFeatures) {
//        //            LOG(@"faceFeature=%@", faceFeature);
//        LOG(@"faceFeature.bounds: %@", NSStringFromCGRect(faceFeature.bounds));
////        CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
////        transform = CGAffineTransformTranslate(transform, 0, _previewView.bounds.size.height);
////        // UIKit座標系に変換
////        CGRect faceRect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
//
//
//    }
}


- (void)drawFaceBoxesForFeatures:(NSArray *)features clap:(CGRect)clap orientation:(UIDeviceOrientation)orientation {
    
    for (CIFaceFeature *ff in features) {
        LOG(@"faceFeature.bounds: %@", NSStringFromCGRect(ff.bounds));
        
        CGRect faceRect = (CGRect){
            ff.bounds.origin.y,
            ff.bounds.origin.x,
            ff.bounds.size.height,
            ff.bounds.size.width
        };
        
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = self.view.frame.size.width / clap.size.height;
        CGFloat heightScaleBy = self.view.frame.size.height / clap.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        
        if (_captureManager.isUsingFrontCamera) {
            faceRect.origin.x = self.view.frame.size.width - faceRect.origin.x - faceRect.size.width;
        }
        _indicatorLayer.frame = CGRectOffset(faceRect, self.view.frame.origin.x, self.view.frame.origin.y);
        
        CGFloat cx = CGRectGetMidX(_indicatorLayer.frame);
        CGFloat cy = CGRectGetMidY(_indicatorLayer.frame);
        [self setPoint:(CGPoint){cx, cy}];
    }
}



@end
