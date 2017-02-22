#import "EditViewController.h"
#import "ResultViewController.h"
#import "UIImage+OpenCV.h"
#import <SVProgressHUD.h>

@interface EditViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *editImageView;

@end

@implementation EditViewController {
    CGFloat _progress;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    LOG_CURRENT_METHOD;

    _editImageView.image = _image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)backAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)startAction:(UIButton *)sender {
    LOG_CURRENT_METHOD;
    _progress = 0.0f;
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showProgress:_progress];
    typeof(self) __weak wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [wself interval];
    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        // time-consuming task
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD dismiss];
//            UIImage *resultImage = [UIImage grayScale:_editImageView.image];
//            [wself pushResultViewController:resultImage];
//        });
//    });
}


#pragma mark -
#pragma mark - Private

- (void)pushResultViewController:(UIImage *)resultImage {
    ResultViewController *resultViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ResultViewController"];
    resultViewController.originalImage = _image;
    resultViewController.resultImage = resultImage;
    [self.navigationController pushViewController:resultViewController animated:YES];
}

- (void)interval {
    
    _progress += 0.05f;
    [SVProgressHUD showProgress:_progress];
    
    if (_progress < 1.0f) {
        typeof(self) __weak wself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [wself interval];
        });
    } else {
        [SVProgressHUD dismiss];
        UIImage *resultImage = [UIImage grayScale:_editImageView.image];
        [self pushResultViewController:resultImage];
    }
}


@end
