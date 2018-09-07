//
//  EMContentExpandableMaterial.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/29/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

public class EMContentExpandableMaterial: UIView {

    var isExpanded = false {
        didSet {
            if isExpanded != oldValue {
                if isExpanded {
                    if let content = expandedViewContent {
                        
                        initExpandedViewIfNeeded()
                        titleLabelLeftConstraint?.isActive = false
                        titleLabelRightConstraint?.isActive = false
                        
                        if !_leftButtonItems.isEmpty {
                            addSubview(leftButtonsStackView)
                        
                            leftButtonsStackView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 8.0).isActive = true
                            leftButtonsStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
                            
                            titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: leftButtonsStackView.rightAnchor, constant: titleToButtonsSpacing)
                            titleLabelLeftConstraint?.isActive = true
                        }
                        else {
                            titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leftAnchor)
                            titleLabelLeftConstraint?.isActive = true
                        }
                        
                        if !_rightButtonItems.isEmpty {
                            addSubview(rightButtonsStackView)
                            
                            rightButtonsStackView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -8.0).isActive = true
                            rightButtonsStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
                            
                            titleLabelRightConstraint = titleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightButtonsStackView.leftAnchor, constant: -titleToButtonsSpacing)
                            titleLabelRightConstraint?.isActive = true
                        }
                        else {
                            titleLabelRightConstraint = titleLabel.rightAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.rightAnchor)
                            titleLabelRightConstraint?.isActive = true
                        }
                        
                        //content.layer.opacity = 0.0
                        print(content.layer.opacity)
                        addSubview(content)
                        
                        titleLabelTopConstraint?.constant = 8.0
                        titleLabelCenterXConstraint = titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
                        titleLabelCenterXConstraint?.isActive = true
                        titleLabelBottomConstraint?.isActive = false
                        content.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                        content.leftAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leftAnchor).isActive = true
                        content.rightAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.rightAnchor).isActive = true
                        content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
                        titleLabelBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: content.topAnchor, constant: -titleToContentSpacing)
                        titleLabelBottomConstraint?.isActive = true
                    }
                }
                else {
                    if let content = expandedViewContent {
                        titleLabelBottomConstraint?.isActive = false
                        titleLabelLeftConstraint?.isActive = false
                        titleLabelRightConstraint?.isActive = false
                        titleLabelCenterXConstraint?.isActive = false
                        
                        content.removeFromSuperview()
                        leftButtonsStackView.removeFromSuperview()
                        rightButtonsStackView.removeFromSuperview()
                        
                        titleLabelTopConstraint?.constant = 0.0
                        titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor)
                        titleLabelLeftConstraint?.isActive = true
                        titleLabelRightConstraint =  titleLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor)
                        titleLabelRightConstraint?.isActive = true
                        titleLabelBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
                        titleLabelBottomConstraint?.isActive = true
                    }
                }
            }
        }
    }
    
    var delegate: EMContentExpandableMaterialDelegate?
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var titleFont: UIFont? {didSet {titleLabel.font = titleFont}}
    var titleColor: UIColor? {didSet {titleLabel.textColor = titleColor}}
    fileprivate var titleLabel = UILabel()
    
    var colapseButton: UIButton {return _colapseButton}
    fileprivate lazy var _colapseButton = UIButton()
    var showColapseButton = true
    
    fileprivate lazy var leftButtonsStackView = UIStackView()
    fileprivate lazy var rightButtonsStackView = UIStackView()
    
    var rightButtonItems: [UIButton] {return _rightButtonItems}
    fileprivate var _rightButtonItems = [UIButton]()
    var leftButtonItems: [UIButton] {return _leftButtonItems}
    fileprivate var _leftButtonItems = [UIButton]()
    
    fileprivate func commonButtonInit(_ button: UIButton) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }
    
    func addRightButtonItem(_ button: UIButton) {
        commonButtonInit(button)
        _rightButtonItems.append(button)
        rightButtonsStackView.addArrangedSubview(button)
    }
    
    func addLeftButtonItem(_ button: UIButton) {
        commonButtonInit(button)
        _leftButtonItems.append(button)
        leftButtonsStackView.addArrangedSubview(button)
    }
    
    var expandedViewContent: UIView? {
        didSet {
            expandedViewContent?.layer.opacity = 0.0
            expandedViewContent?.translatesAutoresizingMaskIntoConstraints = false
            expandedViewContent?.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
            expandedViewContent?.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .vertical)
            //delegate?.contentViewChanged(forMaterial: self)
        }
    }
    
    fileprivate let titleToContentSpacing: CGFloat = 20.0
    fileprivate let titleToButtonsSpacing: CGFloat = 8.0
    
    fileprivate var titleLabelCenterXConstraint: NSLayoutConstraint?
    fileprivate var titleLabelTopConstraint: NSLayoutConstraint?
    fileprivate var titleLabelLeftConstraint: NSLayoutConstraint?
    fileprivate var titleLabelRightConstraint: NSLayoutConstraint?
    fileprivate var titleLabelBottomConstraint: NSLayoutConstraint?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        _colapseButton.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        _colapseButton.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .vertical)
        
        addSubview(titleLabel)
        
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)
        titleLabelTopConstraint?.isActive = true
        titleLabelLeftConstraint = titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor)
        titleLabelLeftConstraint?.isActive = true
        titleLabelRightConstraint =  titleLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor)
        titleLabelRightConstraint?.isActive = true
        titleLabelBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        titleLabelBottomConstraint?.isActive = true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.center.x = self.bounds.width / 2
    }
    
    @objc fileprivate func colapseButtonTapped() {delegate?.colapseButtonTapped(forMaterial: self)}
    
    fileprivate var expandedViewInitialized = false
    fileprivate func initExpandedViewIfNeeded() {
        if !expandedViewInitialized {
            
            commonButtonInit(_colapseButton)
            _colapseButton.addTarget(self, action: #selector(colapseButtonTapped), for: .touchUpInside)
            _leftButtonItems.insert(_colapseButton, at: 0)
            
            leftButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
            leftButtonsStackView.axis = .horizontal
            leftButtonsStackView.spacing = 10.0
            leftButtonsStackView.alignment = .center
            leftButtonsStackView.insertArrangedSubview(_colapseButton, at: 0)
            
            rightButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
            rightButtonsStackView.axis = .horizontal
            rightButtonsStackView.spacing = 10.0
            rightButtonsStackView.alignment = .center
            
            expandedViewInitialized = true
        }
    }
}

extension EMContentExpandableMaterial: Formattable {
    func commonFormatting() {
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = GlobalCornerRadii.material
        self.directionalLayoutMargins = standardDirectionalLayoutMargins
    }
    
    func largeHeadingFormat() {
        commonFormatting()
    }
    
    func regularHeadingFormat() {
        commonFormatting()
    }
    
    func offFormat() {
        commonFormatting()
        self.layer.borderColor = GlobalColors.gray.cgColor
        self.titleColor = GlobalColors.orangeRegular
        self.titleFont = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
    }
    func onFormat() {
        commonFormatting()
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
        self.titleColor = GlobalColors.orangeRegular
        self.titleFont = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
    }
    
    func regularFormat() {
        commonFormatting()
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
        self.titleColor = GlobalColors.orangeRegular
        self.titleFont = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
    }
    func emphasisedFormat() {
        commonFormatting()
        self.layer.borderColor = GlobalColors.orangeDark.cgColor
        self.titleColor = GlobalColors.orangeDark
        self.titleFont = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
    }
}
