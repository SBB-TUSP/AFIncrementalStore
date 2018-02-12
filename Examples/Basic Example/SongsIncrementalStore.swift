//
//  SongsIncrementalStore.swift
//  Songs
//
//  Created by Alessandro Ranaldi on 12/02/2018.
//

import Foundation
import CoreData.NSPersistentStoreCoordinator
import CoreData.NSManagedObjectModel

@objc
class SongsIncrementalStore: AFIncrementalStore {

    @objc override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator?, configurationName name: String?, at url: URL, options: [AnyHashable : Any]? = nil) {
        NSPersistentStoreCoordinator.registerStoreClass(SongsIncrementalStore.self, forStoreType: SongsIncrementalStore.type)
        super.init(persistentStoreCoordinator: root, configurationName: name, at: url, options: options)
    }

    @objc override class var type: String {
        return NSStringFromClass(self) as String
    }

    @objc override class var model: NSManagedObjectModel {
        return NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "IncrementalStoreExample", withExtension: "xcdatamodeld")!)!
    }

    @objc override var httpClient: (AFHTTPClient & AFIncrementalStoreHttpClient)? {
        get {
            return SongAPIClient.sharedInstance
        }
        set {}
    }

}
