#import "AlbumViewController.h"
#import <Photos/Photos.h>
#import "PhotoCell.h"
#import "EditViewController.h"

@interface AlbumViewController ()
//@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSArray *assets;
@end

@implementation AlbumViewController

- (void)viewDidLoad {
    LOG_CURRENT_METHOD;
    [super viewDidLoad];
    
    [self readImage];
    [self.collectionView reloadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



#pragma -
#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    cell.asset = _assets[indexPath.row];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    NSUInteger space = 5;
    CGSize listCellSize = CGSizeMake((screenSize.size.width - space * 3) / 3, (screenSize.size.width - space * 3) / 3);
    return listCellSize;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LOG_CURRENT_METHOD;
    [self dismissViewControllerAnimated:YES completion:nil];
    
    EditViewController *editViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"EditViewController"];
    PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    editViewController.image = cell.photoImageView.image;
    [(UINavigationController *)self.presentingViewController pushViewController:editViewController animated:NO];
    
}

#pragma -
#pragma mark - Action

- (IBAction)closeAction:(UIBarButtonItem *)sender {
    NSLog(@"closeAction");
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)readImage {
    PHAssetCollection *myAlbum = [self getMyAlbum];
    PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:myAlbum options:nil];
    _assets = [self getAssets:assets];
}

- (PHAssetCollection *)getMyAlbum {
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                               subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                               options:nil];
//    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
//                                                                               subtype:PHAssetCollectionSubtypeAlbumRegular
//                                                                               options:nil];
    
    __block PHAssetCollection * myAlbum;
    [assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *album, NSUInteger idx, BOOL *stop) {
        myAlbum = album;
        *stop = YES;
    }];
    return myAlbum;
}

- (NSArray *)getAssets:(PHFetchResult *)fetch {
    __block NSMutableArray * assetArray = NSMutableArray.new;
    [fetch enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [assetArray addObject:asset];
    }];
    return assetArray;
}

@end
