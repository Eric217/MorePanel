//
//  ViewController.swift
//  iOS-FastTest
//
//  Created by Eric on 2019/6/16.
//  Copyright © 2019 Eric. All rights reserved.
//

import UIKit
import SnapKit
  
/// 加号面板布局：水平方向滑动，item 折行排列
///
/// 内部会自动处理 safeAreaInsets、contentInsets
/// 暂不支持多个 section、补充视图等
class MyLayout: UICollectionViewLayout {
    /// will be accounted in contentSize
    var layoutInset: UIEdgeInsets = .zero
 
    var minimumInteritemSpacing: CGFloat = 25
    var maximumInteritemSpacing: CGFloat = 38
    var itemSize = CGSize(width: 60, height: 80)
    var lineSpacing: CGFloat = 25
    /// 这个属性的作用：如果外部想加一个 UIPageControl，然而屏幕旋转时每行展示的个数发生变化，会导致页数变化，
    /// 通过这个回调去改变 numberOfPages
    var layoutPrepareCompletion: ((_ pageCount: Int, _ currentPage: Int) -> Void)?
      
    private var arr = [UICollectionViewLayoutAttributes]()
    override func prepare() {
        arr.removeAll()
        guard let cv = collectionView else { return }
        let total = cv.numberOfItems(inSection: 0)
        // inset 修正：content inset 导致翻页不准确
        var inset = add(layoutInset, cv.contentInset)
        inset = add(inset, cv.safeAreaInsets)
        cv.contentInset = .zero
        cv.contentInsetAdjustmentBehavior = .never
        cv.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: cv.safeAreaInsets.bottom, right: 0)
        if #available(iOS 13.0, *) {
            cv.automaticallyAdjustsScrollIndicatorInsets = false
        }
        let w = cv.bounds.width - inset.left - inset.right
        let h = cv.bounds.height - inset.top - inset.bottom
        let itemW = itemSize.width, itemH = itemSize.height
        guard w >= itemW, h >= itemH, cv.numberOfSections == 1, total > 0 else {
            return
        }
        // will >= 1, e.g. Int(3.8) -> 3
        let maxCountPerLine = Int((minimumInteritemSpacing + w)
                                / (minimumInteritemSpacing + itemW))
        let minCountPerLine = Int((maximumInteritemSpacing + w)
                                    / (maximumInteritemSpacing + itemW))
        var countPerLine = (maxCountPerLine + minCountPerLine) / 2
        if countPerLine < maxCountPerLine { // e.g. 3.7 vs 4.1, use 4
            countPerLine += 1
        }
        var fixedX: CGFloat = -1
        var interItemSpacing: CGFloat = 0
        // 1 item per line, use fixed X
        if countPerLine == 1 {
            fixedX = (w - itemW) / 2
        } else { // use same interItemSpacing
            interItemSpacing = (w - CGFloat(countPerLine) * itemW)
                / CGFloat(countPerLine - 1)
        }
        let linesPerPage = Int((h + lineSpacing) / (itemH + lineSpacing))
        let expectedLines = ceil(CGFloat(total) / CGFloat(countPerLine))
        var pageCount: CGFloat = 1
        // only one line, make compact
        if total <= countPerLine {
            interItemSpacing = min(interItemSpacing, maximumInteritemSpacing)
        } else {
            pageCount = ceil(expectedLines / CGFloat(linesPerPage))
        }
         
        let useItemSpacing = fixedX < 0
        var currentLine = 0
        var pageStart: CGFloat = inset.left
        var lineStart: CGFloat = inset.top
        for i in 0 ..< total {
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            if useItemSpacing {
                attr.frame = CGRect(x: CGFloat(i % countPerLine) * (itemW + interItemSpacing) + pageStart,
                                    y: lineStart, width: itemW, height: itemH)
            } else {
                attr.frame = CGRect(x: fixedX + pageStart, y: lineStart,
                                    width: itemW, height: itemH)
            }
            arr.append(attr)
            
            if (i + 1) % countPerLine == 0 {
                currentLine += 1
                lineStart += itemH + lineSpacing
                if currentLine % linesPerPage == 0 {
                    currentLine = 0
                    lineStart = inset.top
                    pageStart += cv.bounds.width
                }
            }
        }
        
        var page = 0
        // 转屏后 修正 offset
        if let cell = cv.visibleCells.first, let item = cv.indexPath(for: cell) {
            page = item.item / (countPerLine * linesPerPage)
            let offset = CGPoint(x: page * Int(cv.bounds.width), y: 0)
           
            DispatchQueue.main.async {
                cv.setContentOffset(offset, animated: true)
            }
        }
     
        _contentSize = CGSize(width: cv.bounds.width * pageCount,
                              height: cv.bounds.height)
        DispatchQueue.main.async {
            self.layoutPrepareCompletion?(Int(pageCount), page)
        }
    }
     
    private var _contentSize = CGSize.zero
    override var collectionViewContentSize: CGSize {
        _contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        arr.filter { rect.intersects($0.frame) }
    }
    
    private func add(_ inset1: UIEdgeInsets, _ inset2: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(top: inset1.top + inset2.top,
                     left: inset1.left + inset2.left,
                     bottom: inset1.bottom + inset2.bottom,
                     right: inset1.right + inset2.right)
    }
    
}

class Cell: UICollectionViewCell {
    let i = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(i)
        i.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        i.textAlignment = .center
        i.tintColor = UIColor.red
        contentView.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UICollectionViewDataSource {
     
    var v1: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
      
        let layout = MyLayout()
        v1 = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v1.dataSource = self
        v1.backgroundColor = .groupTableViewBackground
         
        view.addSubview(v1)
        v1.register(Cell.self, forCellWithReuseIdentifier: "cell")
        v1.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(268)
        }
        
        v1.isPagingEnabled = true
        // 通过设置这个属性调整页间距
        layout.layoutInset = UIEdgeInsets(top: 32, left: 28, bottom: 10, right: 28)
    }
      
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
        cell.i.text = "\(indexPath)"
        return cell
    }
}
 

 
//        self.view.layoutIfNeeded()
//        self.view.setNeedsLayout()
//        super .viewWillLayoutSubviews() ;
//        self.view.layoutSubviews()
//
//        self.view.autoresizingMask
//        self.view.autoresizesSubviews
//        self.view.translatesAutoresizingMaskIntoConstraints
//        self.view.layoutMarginsGuide
//        self.view.safeAreaLayoutGuide
//        self.view.preservesSuperviewLayoutMargins
//        self.view.insetsLayoutMarginsFromSafeArea
//        self.view.directionalLayoutMargins // between this an subviews
//        self.view.safeAreaInsets
////  real layoutMargins = safeAreaInset + assigned layoutMargin, if insets = true
//        self.additionalSafeAreaInsets
