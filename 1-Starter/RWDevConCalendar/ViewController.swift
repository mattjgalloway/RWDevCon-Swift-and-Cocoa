//
//  ViewController.swift
//  RWDevConCalendar
//
//  Created by Matt Galloway on 30/11/2014.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController {

  private let CELL_IDENTIFIER = "Cell"
  private let DAY_COLUMN_IDENTIFIER = "DayColumn"
  private let TIME_ROW_IDENTIFIER = "TimeRow"

  private let PRESENT_SESSION_SEGUE_IDENTIFIER = "PresentSession"

  private var days = [NSDate]()
  private var sessions = [[Session]]()

  private lazy var timeRowDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "h a"
    return formatter
  }()

  private lazy var dayColumnDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "EEE MMM d"
    return formatter
    }()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.loadData()

    self.edgesForExtendedLayout = .None
    self.title = "RWDevCon"
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)

    self.collectionView?.backgroundColor = UIColor(white: 0.922, alpha: 1.0)
  }

  private func loadData() {
  }

  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return self.days.count;
  }

  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.sessions[section].count
  }

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CELL_IDENTIFIER, forIndexPath: indexPath) as SessionCell
    return cell
  }

}
