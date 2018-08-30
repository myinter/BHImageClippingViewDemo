//
//  FixedSizeFlowLayout.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/18.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BHWaterFlowLayout.h"
#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#define printf(...) printf(__VA_ARGS__)
#else
#define NSLog(...)
#define printf(...)
#endif

@implementation BHWaterFlowLayout

-(BHWaterFlowLayout *)init
{
    self = [super init];
    if (self) {
        layoutInit(self);
    }
    return self;
}

-(void)refresh
{
    [self.layoutAttributes removeAllObjects];
    _numberOfItems = 0;
    _contentHeight = 0;
    for (int i = 0; i != _columnNumber; i++) {
        _perColumnHeights[i] = 0;
    }
}

inline void layoutInit(BHWaterFlowLayout *layout)
{
    layout->_rectForItemsContainerSize = 4096;
    layout->_rectsForItems = (CGRect *)malloc(sizeof(CGRect) * 4096);
    layout->_heightWidthRatio = 1.0;
    layout->_columnHeightSize = 256;
    layout->_perColumnHeights = (CGFloat *)malloc(sizeof(CGFloat) * 256);
    layout->_contentHeight = 0.0;
    layout.sectionInset = UIEdgeInsetsZero;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    layoutInit(self);
}

-(void)setColumnNumber:(NSInteger)columnNumber
{
    if (_columnHeightSize < columnNumber) {
        if (_perColumnHeights) {
            free(_perColumnHeights);
        }
        _columnHeightSize = columnNumber / 256 + 1;
        _perColumnHeights = (CGFloat *)malloc(sizeof(CGFloat) * _columnHeightSize);
    }
    _columnNumber = columnNumber;
}
//设置新的单元格数量，会将老的单元格对应的布局信息填写到新的空间中..未超过，则不复制。。
-(void)setNumberOfItems:(NSInteger)numberOfItems
{
    if (numberOfItems > _rectForItemsContainerSize) {
        BOOL needExtend = NO;
        if (_rectsForItems) {
            needExtend = YES;
        }
        CGRect *newRectsSpace = (CGRect *)malloc(sizeof(CGRect) * (numberOfItems + _rectForItemsContainerSize));
        memcpy(newRectsSpace, _rectsForItems, _numberOfItems * sizeof(CGRect));
        free(_rectsForItems);
        _rectsForItems = newRectsSpace;
        _rectForItemsContainerSize += numberOfItems;
    }
    _numberOfItems = numberOfItems;
}

-(NSMutableArray *)layoutAttributes
{
    if (_layoutAttributes == nil) {
        _layoutAttributes = [NSMutableArray new];
    }
    return _layoutAttributes;
}

-(void)prepareLayout
{
    if (self.layoutAttributes.count == 0 && _numberOfItems) {
        printf("\n prepareLayout %f",self.collectionView.frame.size.width);
        [self calculateLayoutFromIndex:0];
    }
}

/*此方法在当前线程计算布局*/
-(NSMutableArray *)calculateLayoutFromIndex:(NSInteger)startIndex
{
    printf("\n开始计算布局 %f",CFAbsoluteTimeGetCurrent());
    if (startIndex == 0) {
        for (int i = 0; i != _columnNumber; i++) {
            _perColumnHeights[i] = self.sectionInset.top;
            printf("\n startIndex == 0 i %d %f",i,_perColumnHeights[i]);
        }
        [_layoutAttributes removeAllObjects];
    }
    _collectionViewWidth = self.collectionView.frame.size.width;
    NSMutableArray *array = nil;
    _contentHeight = 0.0;
    if (startIndex < _numberOfItems && _columnNumber > 0) {
        CGFloat width = (_collectionViewWidth - self.sectionInset.left - self.sectionInset.right - _horizontalMargin * (_columnNumber - 1)) / _columnNumber;
        CGFloat height = 0.0;
        for (NSInteger i = startIndex;  i!= _numberOfItems; i++) {
            if ([_delegate respondsToSelector:@selector(heightWidthRatioForItemAtIndex:)]) {
                height = width * [_delegate heightWidthRatioForItemAtIndex:i];
            }
            else{
                height = width * _heightWidthRatio;
            }
            //计算当前cell的布局位置。
            NSInteger currentColumn = 0;
            CGFloat currentTop = _perColumnHeights[0];
            //获取当前最小高度
            for (int a = 0; a != _columnNumber; a++) {
                if (currentTop > _perColumnHeights[a]) {
                    currentTop = _perColumnHeights[a];
                    currentColumn = a;
                }
            }
            _rectsForItems[i] = CGRectMake(self.sectionInset.left + (_horizontalMargin + width) * currentColumn , currentTop,width,height);
            //刷新当前列的高度
            _perColumnHeights[currentColumn] = currentTop + height  + _verticalMargin;
            printf("\n i %ld %f",(long)i,_perColumnHeights[currentColumn]);
        }
        for (int i = 0; i != _columnNumber; i++) {
            if (_perColumnHeights[i] > _contentHeight) {
                _contentHeight = _perColumnHeights[i];
            }
            printf("\n i %d %f",i,_perColumnHeights[i]);
        }
        printf("\n _contentHeight %f",_contentHeight);
        //将对应的布局信息填写到 UICollectionViewLayoutAttributes 对象当中。
        array = [NSMutableArray arrayWithArray:self.layoutAttributes];
        for (NSInteger i = startIndex; i != _numberOfItems; i++) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            attributes.frame = _rectsForItems[i];
            [array insertObject:attributes atIndex:i];
        }
    }
    printf("\n结束计算布局 %f",CFAbsoluteTimeGetCurrent());
    return array;
}

-(void)dealloc
{
    if (_rectsForItems) {
        free(_rectsForItems);
    }
    if (_perColumnHeights) {
        free(_perColumnHeights);
    }
}

/*此方法在子线程计算布局*/
-(void)calculateLayoutFromIndex:(NSInteger)index reloadAfterCalculated:(BOOL)needReload
{
    _collectionViewWidth = self.collectionView.frame.size.width;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (needReload) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray *array = [self calculateLayoutFromIndex:index];
                self.layoutAttributes = array;
                [self reloadData];
            });
        }
    });
}

-(void)calculateLayoutFromIndex:(NSInteger)index calculateFinishedBlock:(void (^)(BHWaterFlowLayout *layout))block{
    _collectionViewWidth = self.collectionView.frame.size.width;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableArray *array = [self calculateLayoutFromIndex:index];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.layoutAttributes = array;
                if (block) {
                    block(self);
                }
            });
    });
}

-(CGSize)collectionViewContentSize
{
    CGSize size = CGSizeMake(self.collectionView.frame.size.width, MAX(_contentHeight + self.sectionInset.top + self.sectionInset.bottom, self.collectionView.frame.size.height));
    return size;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _layoutAttributes[indexPath.row];
}

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)Rect
{
    //过滤出处于rect当中的attributes
    return _layoutAttributes;
}

-(void)addItemsAtIndex:(NSInteger)insertIndex addedItemsCount:(NSInteger)addedItemsCount{
    BOOL addedAtEnd = (insertIndex >= self.numberOfItems);
    NSInteger oldMaxIndex = self.numberOfItems;
    self.numberOfItems += addedItemsCount;
    if (addedItemsCount) {
        [self calculateLayoutFromIndex:addedAtEnd ? oldMaxIndex : 0  reloadAfterCalculated:YES];
    }
}

-(void)reloadData
{
    [self.collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

@end
