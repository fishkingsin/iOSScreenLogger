//
//  DragButtonView.swift
//  NMG News
//
//  Created by Joey Sun on 2024/8/26.
//

import Foundation
import UIKit

extension UIDevice {
    func isiPhoneXMore() -> Bool {
        var isMore = false
        if #available(iOS 11.0, *) {
            if let keyWindow = UIApplication.shared.keyWindow {
                isMore = keyWindow.safeAreaInsets.bottom > 0.0
            }
        }
        return isMore
    }

    var isAppleLoginAvailable: Bool {
        if #available(iOS 13.0, *) {
            return true
        } else {
            return false
        }
    }
}


public enum DragDirection: Int {
    case any = 0
    case horizontal
    case vertical
}

let kScreenH = UIScreen.main.bounds.height
let isIphoneX: Bool = UIDevice.current.isiPhoneXMore()
let kStatusBarH: CGFloat = isIphoneX == true ? 44 : 20
let kSafeBottomH: CGFloat = isIphoneX == true ? 34 : 0
let kNavBarH: CGFloat = isIphoneX ? 88 : 64

class DragButtonView: UIButton {
    public var dragEnable: Bool = true

    public var freeRect = CGRect.zero

     public var dragDirection = DragDirection.any

     
    public var isKeepBounds: Bool = false

    public var forbidenOutFree: Bool = true

    public var hasNavagation: Bool = true
      
    public var forbidenEnterStatusBar: Bool = false

    public var fatherIsController: Bool = false

    /**
     contentView 内部懒加载的一个 UIImageView
     开发者也可以自定义控件添加到本 view 中
     注意：最好不要同时使用内部的 iconView 和 button
     */
    public lazy var iconView: UIImageView = {
        let imageV = UIImageView()
        imageV.isUserInteractionEnabled = true
        imageV.clipsToBounds = true
        contentViewForDrag.addSubview(imageV)
        return imageV
    }()

    /**
     contentView 内部懒加载的一个 UIButton
     开发者也可以自定义控件添加到本 view 中
     注意：最好不要同时使用内部的 iconView 和 button
     */
    @objc lazy var button: UIButton = {
        let btn = UIButton()
        btn.clipsToBounds = true
        contentViewForDrag.addSubview(btn)
        return btn
    }()

    @objc lazy var contentViewForDrag: UIView = {
        let contentV = UIView()
        contentV.clipsToBounds = true
        self.addSubview(contentV)
        return contentV
    }()

    ///  点击的回调  block
    public var clickDragViewBlock: ((DragButtonView) -> Void)?
    ///  开始拖动的回调  block
    public var beginDragBlock: ((DragButtonView) -> Void)?
    ///  拖动中的回调  block
    public var duringDragBlock: ((DragButtonView) -> Void)?
    ///  结束拖动的回调  block
    public var endDragBlock: ((DragButtonView) -> Void)?

    private var leftMove: String = "leftMove"
    private var rightMove: String = "rightMove"

    ///  动画时长
     private var animationTime: TimeInterval = 0.5
    private var startPoint = CGPoint.zero
    private var panGestureRecognizer: UIPanGestureRecognizer!

    ///  禁止拖出父控件动画时长
     private var endaAimationTime: TimeInterval = 0.2

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let superview = self.superview {
            freeRect = CGRect(origin: CGPoint.zero, size: superview.bounds.size)
        }
        contentViewForDrag.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        button.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        iconView.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
    }

    func setup() {
        //  默认为父视图的  frame  范围内
        if let superview = self.superview {
            freeRect = CGRect(origin: CGPoint.zero, size: superview.bounds.size)
        }
        clipsToBounds = true
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(clickDragView))
        addGestureRecognizer(singleTap)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragAction(pan:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        addGestureRecognizer(panGestureRecognizer)
    }

    //  点击事件
     @objc func clickDragView() {
        clickDragViewBlock?(self)
    }

    ///  拖动事件
     @objc func dragAction(pan: UIPanGestureRecognizer) {
        if dragEnable == false {
            return
        }

        switch pan.state {
        case .began:

            beginDragBlock?(self)

            //  注意完成移动后，将  translation  重置为  0  十分重要。否则  translation  每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)
            //  保存触摸起始点位置
            startPoint = pan.translation(in: self)
        case .changed:

            duringDragBlock?(self)
            //  计算位移  =  当前位置  -  起始位置

             //  禁止拖动到父类之外区域
            if forbidenOutFree == true, frame.origin.x < 0 || frame.origin.x > freeRect.size.width - frame.size.width || frame.origin.y < 0 || frame.origin.y > freeRect.size.height - frame.size.height {
                var newframe: CGRect = frame
                if frame.origin.x < 0 {
                    newframe.origin.x = 0
                } else if frame.origin.x > freeRect.size.width - frame.size.width {
                    newframe.origin.x = freeRect.size.width - frame.size.width
                }
                if frame.origin.y < 0 {
                    newframe.origin.y = 0
                } else if frame.origin.y > freeRect.size.height - frame.size.height {
                    newframe.origin.y = freeRect.size.height - frame.size.height
                }

                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }

            //  如果父类是控制器  View
            if fatherIsController, frame.origin.y > freeRect.size.height - frame.size.height - kSafeBottomH {
                var newframe: CGRect = frame
                newframe.origin.y = freeRect.size.height - frame.size.height - kSafeBottomH
                frame = newframe
                UIView.animate(withDuration: endaAimationTime) {}
            }

            //  如果父类是控制器  View  禁止进入导航栏
            if fatherIsController, hasNavagation, frame.minY < kNavBarH {
                var newframe: CGRect = frame
                newframe.origin.y = kNavBarH
                frame = newframe
                UIView.animate(withDuration: endaAimationTime) {}
                return
            }

            //  如果父类是控制器  View  禁止进入状态栏
            if fatherIsController, forbidenEnterStatusBar, frame.minY < kStatusBarH {
                var newframe: CGRect = frame
                newframe.origin.y = kStatusBarH
                frame = newframe
                UIView.animate(withDuration: endaAimationTime) {}
                return
            }

            let point: CGPoint = pan.translation(in: self)
            var dx: CGFloat = 0.0
            var dy: CGFloat = 0.0
            switch dragDirection {
            case .any:
                dx = point.x - startPoint.x
                dy = point.y - startPoint.y
            case .horizontal:
                dx = point.x - startPoint.x
                dy = 0
            case .vertical:
                dx = 0
                dy = point.y - startPoint.y
            }

            //  计算移动后的  view  中心点
             let newCenter = CGPoint(x: center.x + dx, y: center.y + dy)
            //  移动  view
            center = newCenter
            //  注意完成上述移动后，将  translation  重置为  0  十分重要。否则  translation  每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)

        case .ended:
            keepBounds()
            endDragBlock?(self)
        default:
            break
        }
    }

    ///  黏贴边界效果
     private func keepBounds() {
        //  中心点判断
         let centerX: CGFloat = freeRect.origin.x + (freeRect.size.width - frame.size.width) * 0.5
        var rect: CGRect = frame
        if isKeepBounds == false { //  没有黏贴边界的效果
            if frame.origin.x < freeRect.origin.x {
                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                frame = rect
                UIView.commitAnimations()
            } else if freeRect.origin.x + freeRect.size.width < frame.origin.x + frame.size.width {
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                frame = rect
                UIView.commitAnimations()
            }

        } else if isKeepBounds == true { //  自动粘边
            if frame.origin.x < centerX {
                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                frame = rect
                UIView.commitAnimations()
            } else {
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                frame = rect
                UIView.commitAnimations()
            }
        }

        if frame.origin.y < freeRect.origin.y {
            UIView.beginAnimations("topMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y
            frame = rect
            UIView.commitAnimations()
        } else if freeRect.origin.y + freeRect.size.height < frame.origin.y + frame.size.height {
            UIView.beginAnimations("bottomMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y + freeRect.size.height - frame.size.height
            frame = rect
            UIView.commitAnimations()
        }
    }
}
