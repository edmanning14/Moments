//
//  EMContentExpandableMaterialManagerView.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/30/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

@IBDesignable
class EMContentExpandableMaterialManagerView: UIView, EMContentExpandableMaterialDelegate {

    var managedMaterialViews: [EMContentExpandableMaterial] {return _managedMaterialViews}
    fileprivate var _managedMaterialViews = [EMContentExpandableMaterial]()
    fileprivate var materialSetSizes = [CGSize]()
    fileprivate var allMaterialHeight: CGFloat?
    fileprivate var allMaterialWidth: CGFloat?
    
    func addManagedMaterialView(_ material: EMContentExpandableMaterial) {
        material.translatesAutoresizingMaskIntoConstraints = false
        material.delegate = self
        _managedMaterialViews.append(material)
        materialSetSizes.append(CGSize(width: allMaterialWidth ?? UIViewNoIntrinsicMetric, height: allMaterialHeight ?? UIViewNoIntrinsicMetric))
        addSubview(material)
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func removeManagedMaterial(_ material: EMContentExpandableMaterial) {
        if let i = _managedMaterialViews.index(of: material) {
            material.removeFromSuperview()
            _managedMaterialViews.remove(at: i)
            materialSetSizes.remove(at: i)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    func constrainHeight(ofMaterial _material: EMContentExpandableMaterial?, to height: CGFloat) {
        if let material = _material {
            if let i = _managedMaterialViews.index(of: material) {materialSetSizes[i].height = height}
        }
        else {
            allMaterialHeight = height
            for i in 0 ..< materialSetSizes.count {materialSetSizes[i].height = height}
        }
    }
    
    func constrainWidth(ofMaterial _material: EMContentExpandableMaterial?, to width: CGFloat) {
        if let material = _material {
            if let i = _managedMaterialViews.index(of: material) {materialSetSizes[i].width = width}
        }
        else {
            allMaterialWidth = width
            for i in 0 ..< materialSetSizes.count {materialSetSizes[i].width = width}
        }
    }
    
    var currentlyExpandedMaterial: EMContentExpandableMaterial? {return _currentlyExpandedMaterial}
    fileprivate var _currentlyExpandedMaterial: EMContentExpandableMaterial?
    
    enum Alignments {case leading, center, trailing}
    enum Axes {case horizontal, vertical}
    enum Distributions {case leading, center, trailing}
    
    @IBInspectable var materialSpacing: CGFloat = 10.0
    var alignment: Alignments = .center
    var axis: Axes = .vertical
    var distribution: Distributions = .center
    
    var delegate: EMContentExpandableMaterialManagerDelegate?

    override var intrinsicContentSize: CGSize {
        guard managedMaterialViews.count > 0 else {return CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)}
        let smallestMaterialSizes = _managedMaterialViews.map { (material) -> CGSize in material.systemLayoutSizeFitting(UILayoutFittingCompressedSize)}
        
        var minX: CGFloat = 0.0
        var minY: CGFloat = 0.0
        switch axis {
        case .horizontal:
            
            minX = materialSpacing * CGFloat(_managedMaterialViews.count - 1)
            
            for size in smallestMaterialSizes {
                minX += size.width
                if size.height > minY {minY = size.height}
            }
            
        case .vertical:
            minY = materialSpacing * CGFloat(_managedMaterialViews.count - 1)
            
            for size in smallestMaterialSizes {
                minY += size.height
                if size.width > minX {minX = size.width}
            }
        }
        
        return CGSize(width: minX, height: minY)
    }
    
    override func layoutSubviews() {
        guard !_managedMaterialViews.isEmpty else {return}
        super.layoutSubviews()
        var materialFrames = materialSetSizes.map { (size) -> CGRect in CGRect(origin: CGPoint.zero, size: size)}
        for (i, frame) in materialFrames.enumerated() {
            let compressedSize = _managedMaterialViews[i].systemLayoutSizeFitting(UILayoutFittingCompressedSize)
            if _managedMaterialViews[i] == currentlyExpandedMaterial {materialFrames[i].size = compressedSize}
            if frame.size.width == UIViewNoIntrinsicMetric {materialFrames[i].size.width = compressedSize.width}
            if frame.size.height == UIViewNoIntrinsicMetric {materialFrames[i].size.height = compressedSize.height}
        }
        
        //
        // Adjust sizes as neccesary
        var sumAlongAxis: CGFloat = materialSpacing * CGFloat(_managedMaterialViews.count - 1)
        switch axis {
        case .horizontal:
            for (i, size) in materialFrames.enumerated() {
                sumAlongAxis += size.width
                if size.height > bounds.size.height {materialFrames[i].size.height = bounds.size.height}
            }
            if sumAlongAxis > bounds.size.width {
                if let expandedMaterialIndex = _managedMaterialViews.index(where: {$0 == _currentlyExpandedMaterial}) {
                    let contractedViewDesiredWidths = _managedMaterialViews.filter { (material) -> Bool in
                        if material != _managedMaterialViews[expandedMaterialIndex] {return true} else {return false}
                    }.map { (material) -> CGFloat in material.systemLayoutSizeFitting(UILayoutFittingCompressedSize).width}
                    var immutableSumAlongAxis = materialSpacing * CGFloat(_managedMaterialViews.count - 1)
                    for width in contractedViewDesiredWidths {immutableSumAlongAxis += width}
                    materialFrames[expandedMaterialIndex].size.width = bounds.size.width - immutableSumAlongAxis
                }
                else {
                    // Do nothing, it should push off??
                }
            }
        case .vertical:
            for (i, size) in materialFrames.enumerated() {
                sumAlongAxis += size.height
                if size.width > bounds.size.width {materialFrames[i].size.width = bounds.size.width}
            }
            if sumAlongAxis > bounds.size.height {
                if let expandedMaterialIndex = _managedMaterialViews.index(where: {$0 == _currentlyExpandedMaterial}) {
                    let contractedViewDesiredHeights = _managedMaterialViews.filter { (material) -> Bool in
                        if material != _managedMaterialViews[expandedMaterialIndex] {return true} else {return false}
                        }.map { (material) -> CGFloat in material.systemLayoutSizeFitting(UILayoutFittingCompressedSize).width}
                    var immutableSumAlongAxis = materialSpacing * CGFloat(_managedMaterialViews.count - 1)
                    for height in contractedViewDesiredHeights {immutableSumAlongAxis += height}
                    materialFrames[expandedMaterialIndex].size.height = bounds.size.height - immutableSumAlongAxis
                }
                else {
                    // Do nothing, it should push off??
                }
            }
        }
        
        //
        // Set material locations
        switch axis {
        case .horizontal:
            
            //
            // Set x
            switch distribution {
            case .leading:
                var rollingX: CGFloat = 0.0
                for (i, frame) in materialFrames.enumerated() {
                    materialFrames[i].origin.x = rollingX
                    rollingX += frame.width + materialSpacing
                }
            case .center:
                var rollingX: CGFloat = (bounds.width / 2) - (sumAlongAxis / 2)
                for (i, frame) in materialFrames.enumerated() {
                    materialFrames[i].origin.x = rollingX
                    rollingX += frame.width + materialSpacing
                }
            case .trailing:
                let reversedMaterialFrames = materialFrames.reversed()
                var rollingX: CGFloat = bounds.width
                for (i, frame) in reversedMaterialFrames.enumerated() {
                    rollingX -= frame.width
                    materialFrames[i].origin.x = rollingX
                    rollingX -= materialSpacing
                }
            }
            
            //
            // Set y
            switch alignment {
            case .leading: for (i, _) in materialFrames.enumerated() {materialFrames[i].origin.y = 0.0}
            case .center: for (i, frame) in materialFrames.enumerated() {materialFrames[i].origin.y = (bounds.height / 2) - (frame.height / 2)}
            case .trailing: for (i, frame) in materialFrames.enumerated() {materialFrames[i].origin.y = bounds.height - frame.height}
            }
        case .vertical:
            
            //
            // Set y
            switch distribution {
            case .leading:
                var rollingY: CGFloat = 0.0
                for (i, frame) in materialFrames.enumerated() {
                    materialFrames[i].origin.y = rollingY
                    rollingY += frame.height + materialSpacing
                }
            case .center:
                var rollingY: CGFloat = (bounds.height / 2) - (sumAlongAxis / 2)
                for (i, frame) in materialFrames.enumerated() {
                    materialFrames[i].origin.y = rollingY
                    rollingY += frame.height + materialSpacing
                }
            case .trailing:
                var rollingY: CGFloat = bounds.height
                for (i, frame) in materialFrames.reversed().enumerated() {
                    rollingY -= frame.height
                    materialFrames[materialFrames.count - 1 - i].origin.y = rollingY
                    rollingY -= materialSpacing
                }
            }
            
            //
            // Set x
            switch alignment {
            case .leading: for (i, _) in materialFrames.enumerated() {materialFrames[i].origin.x = 0.0}
            case .center: for (i, frame) in materialFrames.enumerated() {materialFrames[i].origin.x = (bounds.width / 2) - (frame.width / 2)}
            case .trailing: for (i, frame) in materialFrames.enumerated() {materialFrames[i].origin.x = bounds.width - frame.width}
            }
        }
        
        //
        // Make changes
        for (i, newLoc) in materialFrames.enumerated() {self._managedMaterialViews[i].frame = newLoc}
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let endPoints = touches.map { (touch) -> CGPoint in touch.location(in: self)}
        for point in endPoints {
            for material in _managedMaterialViews {
                if material.frame.contains(point) {
                    if !material.isExpanded {
                        if delegate?.shouldSelectMaterial?(material) ?? true {select(material: material, animated: true)}
                    }
                    else {super.touchesEnded(touches, with: event)}
                }
            }
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {}
    
    //
    // Delegate
    func colapseButtonTapped(forMaterial material: EMContentExpandableMaterial) {
        if delegate?.shouldColapseMaterial?(material) ?? true {deselectSelectedMaterial(animated: true)}
    }
    
    func contentViewChanged(forMaterial material: EMContentExpandableMaterial) {if material == currentlyExpandedMaterial {invalidateIntrinsicContentSize()}}
    
    func select(material: EMContentExpandableMaterial, animated: Bool) {
        guard _managedMaterialViews.contains(material) else {return}
        _currentlyExpandedMaterial?.isExpanded = false
        _currentlyExpandedMaterial?.regularFormat()
        _currentlyExpandedMaterial = material
        material.isExpanded = true
        material.onFormat()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        
        if animated {
            let moveViewsAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {self.layoutIfNeeded()}
            let fadeInExpandedContentAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {material.expandedViewContent?.layer.opacity = 1.0}
            
            moveViewsAnim.addCompletion { (position) in fadeInExpandedContentAnim.startAnimation()}
            
            moveViewsAnim.startAnimation()
        }
    }
    
    func deselectSelectedMaterial(animated: Bool) {
        if let currentlyExpandedMaterial = _currentlyExpandedMaterial {
            currentlyExpandedMaterial.isExpanded = false
            currentlyExpandedMaterial.regularFormat()
            _currentlyExpandedMaterial = nil
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            
            if animated {
                let moveViewsAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {self.layoutIfNeeded()}
                moveViewsAnim.startAnimation()
            }
        }
    }
    
    func setContentView(_ view: UIView, for material: EMContentExpandableMaterial, animated: Bool) {
        guard _managedMaterialViews.contains(material) else {return}
        if _currentlyExpandedMaterial == material {
            let fadeOutAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {material.expandedViewContent?.layer.opacity = 0.0}
            let resizeAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {self.layoutIfNeeded()}
            let fadeInExpandedContentAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {material.expandedViewContent?.layer.opacity = 1.0}
            
            fadeOutAnim.addCompletion { (position) in
                material.expandedViewContent = view
                self.invalidateIntrinsicContentSize()
                self.setNeedsLayout()
                resizeAnim.startAnimation()
            }
            resizeAnim.addCompletion { (position) in fadeInExpandedContentAnim.startAnimation()}
            
            fadeOutAnim.startAnimation()
        }
        else {material.expandedViewContent = view}
    }
}
