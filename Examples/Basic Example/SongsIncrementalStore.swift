//
//  SongsIncrementalStore.swift
//  Songs
//
//  Created by Alessandro Ranaldi on 12/02/2018.
//

import Foundation
import CoreData.NSPersistentStoreCoordinator
import CoreData.NSManagedObjectModel
import AFNetworking

@objc
class SongsIncrementalStore: AFIncrementalStore {

    @objc override class var type: String {
        return NSStringFromClass(self)
    }

    @objc override class var model: NSManagedObjectModel {
        return NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "IncrementalStoreExample", withExtension: "xcdatamodeld")!)!
    }

    @objc override var httpClient: (AFHTTPSessionManager & AFIncrementalStoreHttpClient)? {
        get {
            return SongAPIClient.sharedInstance
        }
        set {}
    }

}
