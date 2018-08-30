//
//  BPMAlbumCell.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BPMAlbumCell.h"

@implementation BPMAlbumCell

+(BPMAlbumCell *)cellFromNib
{
    return [[NSBundle mainBundle]loadNibNamed:@"BPMAlbumCell" owner:nil options:nil][0];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
