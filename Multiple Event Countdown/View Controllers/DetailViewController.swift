//
//  DetailViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    //
    // MARK: - GUI
    //
    
    var detailViewCell: EventTableViewCell!
    
    
    //
    // MARK: - Data Model
    //
    
    var specialEvent: SpecialEvent?
    
    
    //
    // MARK: - Timer
    //
    
    fileprivate var eventTimer: Timer?
    
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if eventTimer == nil {
            detailViewCell.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.detailViewCell.update()}
            }
        }
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    override func viewWillDisappear(_ animated: Bool) {eventTimer?.invalidate(); eventTimer = nil}
    
    @objc fileprivate func applicationDidBecomeActive(notification: NSNotification) {
        if eventTimer == nil {
            detailViewCell.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.detailViewCell.update()}
            }
        }
    }
    
    @objc fileprivate func applicationWillResignActive(notification: NSNotification) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    deinit {eventTimer?.invalidate(); eventTimer = nil}
    
    
    //
    // MARK: - View Cofiguration
    //
    
    func configureView() {
        if let specialEventNib = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let cell = specialEventNib[0] as? EventTableViewCell {
                detailViewCell = cell
                detailViewCell.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(detailViewCell!)
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: detailViewCell!.topAnchor).isActive = true
                view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: detailViewCell!.rightAnchor).isActive = true
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: detailViewCell!.bottomAnchor).isActive = true
                view.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: detailViewCell!.leftAnchor).isActive = true
                detailViewCell.configuration = .detailView
                detailViewCell.useMask = false
                
                let bottomAnchorConstraint = detailViewCell.constraints.first {$0.secondAnchor == detailViewCell.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                detailViewCell.bottomAnchor.constraint(equalTo: detailViewCell.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
            }
        }
        if let event = specialEvent {
            detailViewCell.eventTitle = event.title
            if let tagline = event.tagline {detailViewCell.eventTagline = tagline}
            if let date = event.date {detailViewCell.eventDate = EventDate(date: date.date, dateOnly: date.dateOnly)}
            detailViewCell.creationDate = specialEvent!.creationDate
            detailViewCell.abridgedDisplayMode = specialEvent!.abridgedDisplayMode
            detailViewCell.useMask = specialEvent!.useMask
            
            if let imageInfo = event.image {
                if imageInfo.isAppImage {
                    if let appImage = AppEventImage(fromEventImageInfo: imageInfo) {
                        detailViewCell.setSelectedImage(image: appImage, locationForCellView: nil)
                    }
                }
                else {
                    if let userImage = UserEventImage(fromEventImageInfo: imageInfo) {
                        detailViewCell.setSelectedImage(image: userImage, locationForCellView: nil)
                    }
                }
            }
            //detailViewCell.update()
        }
        configureNavBar()
    }
    
    fileprivate func configureNavBar() {
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont(name: Fonts.headingsFontName, size: 18.0) as Any,
            .foregroundColor: Colors.orangeRegular
        ]
    }
    
    
    //
    // MARK: - Action Methods
    //
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        /*if let button = sender as? UIBarButtonItem {
            
        }*/
    }

}

