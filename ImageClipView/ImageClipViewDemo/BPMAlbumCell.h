//
//  BPMAlbumCell.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPMAlbumCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

+(BPMAlbumCell *)cellFromNib;

@end
