//
//  CoreDataStack.swift
//  com.github.kautenja.ExtensionUbiquitySampleProject.ExtensionUbiquitySampleProject
//
//  Created by James Kauten on 8/19/17.
//  Copyright © 2017 Christian Kauten. All rights reserved.
//

import CoreData
import NotificationCenter

/// the id of the shared group for the applications
let appGroupID = "group.com.mentrena.todayextensiontest"

/// the id for the CloudKit container
let cloudKitContainerID = "iCloud.com.mentrena.todayextensiontest"

/// extensions to make accessing notification names global to the application
/// easier with the shorthand . notation
extension NSNotification.Name {
    
    /// the data update notification name, this notification is sent when new
    /// data is synchronized from CloudKit so that view controllers can draw
    /// the new data
    static var cloudKitSync: NSNotification.Name {
        return NSNotification.Name(rawValue: "notification.com.github.kautenja.EUSP.cloudKitSync")
    }
    
}

/// A custom NSPersistentContainer for accessing the shared group. This enables
/// external processes to access the same core data stack and access objects.
/// This is utilized by today extensions, notification extensions, and the watch
/// app
class GroupPersistentContainer: NSPersistentContainer {

    /// Return the default directory for the group
    /// - returns: the URL to the group for the apps
    override class func defaultDirectoryURL() -> URL{
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
    }
    
}

/// The central core data stack for the application, extensions, and apple watch
/// application
class CoreDataStack: NSObject {
    
    // MARK: Singleton pattern
    
    /// The private constructor for the singleton instance
    private override init() {
        super.init()
        // load the view context to avoid some weird startup problems
        _ = persistentContainer.viewContext
    }
    
    /// the private shared instack of the stack
    private static var singleton: CoreDataStack?
    
    /// the public accessor for the shared instance
    public static var shared: CoreDataStack {
        guard let _shared = singleton else {
            singleton = CoreDataStack()
            return singleton!
        }
        return _shared
    }
    
    // MARK: CoreData Support
    
    /// The persistent container for the application. This implementation
    /// creates and returns a container, having loaded the store for the
    /// application to it. This property is optional since there are legitimate
    /// error conditions that could cause the creation of the store to fail.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = GroupPersistentContainer(name: "com_github_kautenja_ExtensionUbiquitySampleProject_ExtensionUbiquitySampleProject")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                NSLog(error.localizedDescription)
            }
        })
        return container
    }()
    
    /// Fetch all of the objects in the core store of the given type
    /// - parameters:
    ///   - of: the type of the core data entity to fetch all of
    ///   - callback: the callback function for the fetch operation
    func fetchAll(of type: NSManagedObject.Type = NSManagedObject.self) -> [NSManagedObject]? {
        let request = NSFetchRequest<NSManagedObject>(entityName: String(describing: type))
        do {
            let objects = try persistentContainer.viewContext.fetch(request)
            return objects
        } catch {
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    /// Save the core data context
    func saveContext () {
        if persistentContainer.viewContext.hasChanges {
            do {
                NSLog("Saving and syncing")
                try persistentContainer.viewContext.save()
                // make sure sync is enabled before trying to sync
                guard let sync = sync else {
                    NSLog("not syncing, disabled")
                    return
                }
                // if sync in progress, cancel it
                if sync.isSyncing {
                    sync.cancelSynchronization()
                }
                // sync the data
                sync.synchronize(completion: { (error) in
                    if let error = error {
                        NSLog("\(error.localizedDescription.debugDescription)")
                    }
                    NSLog("sync complete")
                })
            } catch {
                NSLog("\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Sync

    /// Verify that an iCloud account exists with a callback if it does
    private func verifyICloud(didFindValidAccount: @escaping () -> Void) {
        CKContainer.default().accountStatus { (accountStatus, error) in
            switch accountStatus {
            case .available:
                NSLog("iCloud Available")
                didFindValidAccount()
            case .noAccount:
                NSLog("No iCloud account")
            case .restricted:
                NSLog("iCloud restricted")
            case .couldNotDetermine:
                NSLog("Unable to determine iCloud status")
            }
        }
    }
    
    /// the synchronization manager for sending the CoreData store to CloudKit
    public var sync: QSCloudKitSynchronizer?
    
    /// An enumeration outlining the kinds of sync contexts available
    enum SyncType {
        case application
        case extensions
    }
    
    /// Setup sync for the given context
    /// - parameters:
    ///   - context: the context to setup for. i.e. app, extension, etc.
    func setup(context: SyncType) {
        verifyICloud {
            self.sync = QSCloudKitSynchronizer(containerName: cloudKitContainerID,
                                               managedObjectContext: self.persistentContainer.viewContext,
                                               changeManagerDelegate: self as! QSCoreDataChangeManagerDelegate,
                                               suiteName: appGroupID)
            self.syncToICloud()
            if context == .application {
                self.registerForCloudKitUpdates()
            }
        }
    }
    
    /// Synchronize data with CloutKit
    func syncToICloud() {
        sync?.synchronize { (error) in
            guard error == nil else {
                NSLog(error!.localizedDescription)
                return
            }
            // post a notification so whatever view controller can update
            NotificationCenter.default.post(name: .cloudKitSync, object: self, userInfo: nil)
        }
    }
    
    /// Register the current process for CloudKit updates
    func registerForCloudKitUpdates() {
        sync?.subscribeForUpdateNotifications { (error) in
            guard error == nil else {
                NSLog(error!.localizedDescription)
                return
            }
            NSLog("CloudKit Silent Notifications live")
        }
    }
    
}



// MARK: Core Data Change Manager Delegate functions, these enable interraction
//       with sync machinery
extension CoreDataStack: QSCoreDataChangeManagerDelegate {
    
    /// Change manager requests you save your managed object context
    func changeManagerRequestsContextSave(_ changeManager: QSCoreDataChangeManager!,
                                          completion: ((Error?) -> Void)!) {
        NSLog("context save requested")
        do {
            try persistentContainer.viewContext.save()
        } catch let error {
            completion(error)
        }
        completion(nil)
    }
    
    /// Change manager provides a child context of your local managed object
    /// context, containing changes downloaded from CloudKit. Save the import
    /// context, then your local context to persist these changes.
    func changeManager(_ changeManager: QSCoreDataChangeManager!,
                       didImportChanges importContext: NSManagedObjectContext!,
                       completion: ((Error?) -> Void)!) {
        NSLog("changes imported from iCloud")
        guard let _ = importContext else {
            NSLog("didImportChanges passed nil importContext")
            completion(nil)
            return
        }
        do {
            try importContext.save()
            try persistentContainer.viewContext.save()
        } catch let error {
            completion(error)
        }
        completion(nil)
    }

}
