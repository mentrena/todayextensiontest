//
//  ArbObject+CoreDataProperties.swift
//  com.github.kautenja.ExtensionUbiquitySampleProject.ExtensionUbiquitySampleProject
//
//  Created by Manuel Entrena on 20/08/2017.
//  Copyright © 2017 Christian Kauten. All rights reserved.
//

import Foundation
import CoreData

extension ArbObject: QSPrimaryKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArbObject> {
        return NSFetchRequest<ArbObject>(entityName: "ArbObject")
    }

    @NSManaged public var created: NSDate?
    @NSManaged public var name: String?

    public class func primaryKey() -> String {
        
        return "name"
    }
}
