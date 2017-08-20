//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by James Kauten on 8/19/17.
//  Copyright © 2017 Christian Kauten. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    /// the label displaying the number of objects counted in the data
    /// store
    @IBOutlet weak var countLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("today extension: viewDidLoad")
        countLabel.text = CoreDataStack.shared.fetchAll(of: ArbObject.self)?.count.description ?? 0.description
        
        NotificationCenter.default.addObserver(forName: .cloudKitSync, object: self, queue: OperationQueue.main) { (notification) in
            self.countLabel.text = CoreDataStack.shared.fetchAll(of: ArbObject.self)?.count.description ?? 0.description
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        NSLog("today extension: widgetPerformUpdate")
        CoreDataStack.shared.setup(context: .application)
        completionHandler(NCUpdateResult.newData)
    }
    
}
