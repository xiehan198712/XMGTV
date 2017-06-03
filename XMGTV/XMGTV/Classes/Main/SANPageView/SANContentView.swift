//
//  SANContentView.swift
//  XMGTV
//
//  Created by 唐三彩 on 2017/6/1.
//  Copyright © 2017年 唐三彩. All rights reserved.
//

import UIKit

private let kContentCellID = "kContentCellID"

protocol SANContentViewDelegate : class {
    func contentView(_ contentView : SANContentView, targetIndex : Int)
    func contentView(_ contentView : SANContentView, targetIndex : Int, progress :CGFloat)
}
class SANContentView: UIView {

    weak var delegate : SANContentViewDelegate?
    
    fileprivate var childVcs : [UIViewController]
    fileprivate var parentVc : UIViewController
    
    fileprivate var startOffsetX : CGFloat = 0
    //是否禁滚动
    fileprivate var isForbidScroll : Bool = false
    
    fileprivate lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: kContentCellID)
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.scrollsToTop = false
         collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    init(frame: CGRect, childVcs : [UIViewController], parentVc : UIViewController) {
        self.childVcs = childVcs
        self.parentVc = parentVc
        
        super.init(frame: frame)
        
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

//MARK: - UI
extension SANContentView {
    fileprivate func setupUI() {
        
        //将子控制器添加到父控制器中
        for childVc in childVcs {
            parentVc.addChildViewController(childVc)
        }
       
        addSubview(collectionView)
    }
}

//MARK: - UICollectionViewDataSource
extension SANContentView : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childVcs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kContentCellID, for: indexPath)
        
        //先将cell子控件清空,防止多次add
        for subView in cell.contentView.subviews {
            subView.removeFromSuperview()
        }
        
        let childVc = childVcs[indexPath.item]
        childVc.view.frame = cell.contentView.bounds
        cell.contentView.addSubview(childVc.view)
        
        return cell
        
    }
}

//MARK: - UICollectionViewDelegate
extension SANContentView : UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        contentEndScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            contentEndScroll()
        }
    }
    
    private func contentEndScroll() {
        
        guard !isForbidScroll else {
            return
        }
        //计算当前位置
        let currentIndex = Int(collectionView.contentOffset.x / collectionView.bounds.width)
        
        //通知title调整
        delegate?.contentView(self, targetIndex: currentIndex)
        
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
         isForbidScroll = false
        startOffsetX = scrollView.contentOffset.x
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //判断偏移量是否和开始时一样
        guard startOffsetX != scrollView.contentOffset.x, !isForbidScroll else {
            return
        }
        
        //定义targetIndex/progress
        var targetIndex = 0
        var progress : CGFloat = 0.0
        
        //赋值
        let currentIndex = Int(startOffsetX / scrollView.bounds.width)
        if startOffsetX < scrollView.contentOffset.x {  //左滑
            targetIndex = currentIndex + 1
            if targetIndex > childVcs.count - 1 {
                targetIndex = childVcs.count - 1
            }
            
            progress = (scrollView.contentOffset.x - startOffsetX) / scrollView.bounds.width
        } else {    //右滑动
            targetIndex = currentIndex - 1
            if targetIndex < 0 {
                targetIndex = 0
            }
            
            progress = (startOffsetX - scrollView.contentOffset.x) / scrollView.bounds.width 
        }
        //通知代理
        delegate?.contentView(self, targetIndex: targetIndex, progress: progress)
    }
}


//MARK: - SANTitleViewDelegate
extension SANContentView : SANTitleViewDelegate {
    func titleView(_ titleView: SANTitleView, targetIndex: Int) {
        
        isForbidScroll = true
        
        let indexPath = IndexPath(item: targetIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        
    }
}

