//
//  ViewController.swift
//  com.github.kautenja.ExtensionUbiquitySampleProject.ExtensionUbiquitySampleProject
//
//  Created by James Kauten on 8/19/17.
//  Copyright © 2017 Christian Kauten. All rights reserved.
//

import UIKit

/// A protocol for interracting with actions from ObjectCell instances
protocol ObjectCellDelegate {
    
    /// Respond to the delete button being pressed
    /// - parameters:
    ///   - object: the object to delete
    func didPressDelete(_ object: ArbObject?)
    
}

/// a cell containing some info about objects
class ObjectCell: UITableViewCell {
    
    /// the object being displayed on the cell
    var object: ArbObject? {
        didSet {
            nameLabel.text = object?.name ?? "nil"
            createdLabel.text = object?.created?.description ?? "nil"
            objectIDLabel.text = object?.objectID.description ?? "nil"
        }
    }
    
    /// the delegate to pass actions to
    var delegate: ObjectCellDelegate?
    
    /// the name of the object (from core data store)
    @IBOutlet weak var nameLabel: UILabel!
    
    /// the date the object was created
    @IBOutlet weak var createdLabel: UILabel!
    
    /// the object id for the object
    @IBOutlet weak var objectIDLabel: UILabel!
    
    @IBAction func didPressDelete() {
        delegate?.didPressDelete(object)
    }
    
}

/// the main view controller where all the magic happens
class ViewController: UIViewController {

    /// the table view displaying objects
    @IBOutlet weak var tableView: UITableView!
    
    /// the list of objects to display in the view controller
    var objects: [ArbObject] = []
    
    // MARK: View Hierarchy
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        tableView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refetchData), name: .cloudKitSync, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refetchData), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    func refetchData() {
        self.fetchData()
        self.tableView.reloadData()
    }
    
    // MARK: Actions

    /// Fetch data from the core data store
    func fetchData() {
        objects = CoreDataStack.shared.fetchAll(of: ArbObject.self) as? [ArbObject] ?? []
    }
    
    /// Respond to the create object button being pressed
    @IBAction func didPressCreateObject() {
        NSLog("creating new object")
        let object = ArbObject(context: CoreDataStack.shared.persistentContainer.viewContext)
        object.name = "Object: \(objects.count)"
        object.created = NSDate()
        objects.append(object)
        tableView.reloadData()
        CoreDataStack.shared.saveContext()
    }
    
    @IBAction func synchronize() {
        
        CoreDataStack.shared.syncToICloud()
    }

    @IBAction func erase() {
        
        CoreDataStack.shared.sync?.eraseRemoteAndLocalData(completion: { (error) in
            if let error = error {
                print("Got error: \(error)")
            } else {
                print("Deleted all data on iCloud")
                let alertController = UIAlertController(title: "Erased", message: "Deleted all content in iCloud. Please reinstall app to re-create CoreData stack for testing", preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
}



// MARK: Table View Functions
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    /// the global height accessor for cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    /// the number of cells in the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    /// fetch and decorate a cell for the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ObjectCell
        cell.object = objects[indexPath.row]
        cell.delegate = self
        return cell
    }
    
}



// MARK Custom Cell Delegate functions
extension ViewController: ObjectCellDelegate {
    
    /// Respond to the delete button being pressed
    /// - parameters:
    ///   - object: the object to delete
    func didPressDelete(_ object: ArbObject?) {
        // make sure the object exists first
        guard let object = object else {
            NSLog("tried to delete nil object")
            return
        }
        // if it's in the list remove it and reload the table view
        if let index = objects.index(of: object) {
            objects.remove(at: index)
            tableView.reloadData()
        }
        // delete the object from the data store
        CoreDataStack.shared.persistentContainer.viewContext.delete(object)
        CoreDataStack.shared.saveContext()
    }
    
}
