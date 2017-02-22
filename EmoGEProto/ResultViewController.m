#import "ResultViewController.h"
#import <Photos/Photos.h>

@interface ResultViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) UIImageView *originalImageView;
@property (nonatomic) UIImageView *resultImageView;
@property (nonatomic) BOOL original;
@end

@implementation ResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _scrollView.delegate = self;
    
    _resultImageView = [[UIImageView alloc] initWithImage:_resultImage];
    [_scrollView addSubview:_resultImageView];
    _originalImageView = [[UIImageView alloc] initWithImage:_originalImage];
    _originalImageView.alpha = 0.0f;
    [_scrollView addSubview:_originalImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_resultImage) {
        CGSize size = _resultImage.size;
        CGFloat wrate = _scrollView.frame.size.width / size.width;
        CGFloat hrate = _scrollView.frame.size.height / size.height;
        CGFloat rate = MIN(wrate, hrate);
        _resultImageView.frame = (CGRect){0, 0, size.width * rate, size.height * rate};
        _originalImageView.frame = (CGRect){0, 0, size.width * rate, size.height * rate};
        
        _scrollView.contentSize = _resultImageView.frame.size;
        [self updateScrollInset];
    }
}

#pragma mark -
#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _original ? _originalImageView : _resultImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self updateScrollInset];
}



- (void)updateScrollInset {
    _scrollView.contentInset = UIEdgeInsetsMake(
                                               MAX((_scrollView.frame.size.height - _resultImageView.frame.size.height)/2, 0),
                                               MAX((_scrollView.frame.size.width - _resultImageView.frame.size.width)/2, 0),
                                               0,
                                               0
                                               );
}

- (IBAction)backAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)originalAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         _originalImageView.alpha = _original ? 0.0f : 1.0f;
                         _resultImageView.alpha = _original ? 1.0f : 0.0f;
                     }];
    _original = !_original;
    [self updateScrollInset];
}

- (IBAction)facebookAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"yet unsupported"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)twitterAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"yet unsupported"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)saveAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    
    typeof(self) __weak wself = self;
    PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
    [library performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:_resultImage];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:@"Saved"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
        [wself presentViewController:alertController animated:YES completion:nil];
    }];
}

@end
