#import "CameraViewController.h"
#import <AudioToolbox/AudioToolbox.h>
//#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "EditViewController.h"

@interface CameraViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *captureView;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel;

@property CameraManager* captureManager;  // 動画マネージャクラス
//@property uint8_t captureType;               // キャプチャの方法(0:カメラ, 1:動画)
@property (nonatomic, strong) CALayer* indicatorLayer;  // ピント合わせる用のレイヤ

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
    self.indicatorLayer = [CALayer layer];
    self.indicatorLayer.borderColor = [[UIColor whiteColor] CGColor];
    self.indicatorLayer.borderWidth = 1.0;
    self.indicatorLayer.frame = CGRectMake(self.view.bounds.size.width/2.0 - INDICATOR_RECT_SIZE/2.0,
                                           self.view.bounds.size.height/2.0 - INDICATOR_RECT_SIZE/2.0,
                                           INDICATOR_RECT_SIZE,
                                           INDICATOR_RECT_SIZE);
    self.indicatorLayer.hidden = NO;
    [self.view.layer addSublayer:self.indicatorLayer];
    
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
//-(void)videoFrameUpdate:(CGImageRef)cgImage from:(CameraManager*)captureManager {
//UIImage* imageRotate = [CameraManager rotateImage:[UIImage imageWithCGImage:cgImage] angle:270];
//   if(captureManager.isUsingFrontCamera)
//       imageRotate = [self mirrorImage:imageRotate];
//_previewView.image = imageRotate;
//}


@end
