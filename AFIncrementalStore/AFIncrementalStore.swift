//
//  AFIncrementalStore.swift
//  
//
//  Created by Alessandro Ranaldi on 06/02/2018.
//

import Foundation
import CoreData

fileprivate let AFIncrementalStoreUnimplementedMethodException: String = "com.alamofire.incremental-store.exceptions.unimplemented-method"

fileprivate let AFIncrementalStoreRequestOperationsKey: String = "AFIncrementalStoreRequestOperations"

fileprivate let AFIncrementalStoreFetchedObjectIDsKey: String = "AFIncrementalStoreFetchedObjectIDs"

fileprivate let AFIncrementalStoreFaultingObjectIDKey: String = "AFIncrementalStoreFaultingObjectID"

fileprivate let AFIncrementalStoreFaultingRelationshipKey: String = "AFIncrementalStoreFaultingRelationship"

fileprivate let AFIncrementalStorePersistentStoreRequestKey: String = "AFIncrementalStorePersistentStoreRequest"

fileprivate extension Notification.Name {

    fileprivate static var AFIncrementalStoreContextWillFetchRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchRemoteValues")
    }

    fileprivate static var AFIncrementalStoreContextDidFetchRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchRemoteValues")
    }

    fileprivate static var AFIncrementalStoreContextWillSaveRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextWillSaveRemoteValues")
    }

    fileprivate static var AFIncrementalStoreContextDidSaveRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextDidSaveRemoteValues")
    }

    fileprivate static var AFIncrementalStoreContextWillFetchNewValuesForObject: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchNewValuesForObject")
    }

    fileprivate static var AFIncrementalStoreContextDidFetchNewValuesForObject: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchNewValuesForObject")
    }

    fileprivate static var AFIncrementalStoreContextWillFetchNewValuesForRelationship: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchNewValuesForRelationship")
    }

    fileprivate static var AFIncrementalStoreContextDidFetchNewValuesForRelationship: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchNewValuesForRelationship")
    }

}

fileprivate var kAFResourceIdentifierObjectKey: UnsafeRawPointer?

fileprivate var kAFIncrementalStoreResourceIdentifierAttributeName: String {
    return "__af_resourceIdentifier"
}

fileprivate var kAFIncrementalStoreLastModifiedAttributeName: String {
    return "__af_lastModified"
}

fileprivate var kAFReferenceObjectPrefix: String {
    return "__af_"
}

fileprivate func AFReferenceObject(from resourceIdentifier: String?) -> String? {
    guard let resourceIdentifier = resourceIdentifier else {
        return nil
    }
    return kAFReferenceObjectPrefix.appending(resourceIdentifier)
}

fileprivate func AFResourceIdentifier(from referenceObject: NSObjectProtocol?) -> String? {
    guard let referenceObject = referenceObject else {
        return nil
    }
    let string = referenceObject.description
    return string.hasPrefix(kAFReferenceObjectPrefix) ? "\(string[kAFReferenceObjectPrefix.endIndex...])" : string
}

fileprivate func AFSaveManagedObjectContextOrThrowInternalConsistencyException(_ context: NSManagedObjectContext) {
    do {
        try context.save()
    } catch let error as NSError {
        NSException(name: .internalInconsistencyException, reason: error.localizedFailureReason, userInfo: [NSUnderlyingErrorKey: error]).raise()
    }
}

fileprivate extension NSManagedObject {

    fileprivate var af_resourceIdentifier: String? {
        get {
            let identifier = objc_getAssociatedObject(self, kAFResourceIdentifierObjectKey) as? String
            if identifier == nil {
                let referenceObject = (objectID.persistentStore as? AFIncrementalStore).referenceObject(for: objectID)
                if referenceObject?.isKind(of: String.self) {
                    return AFResourceIdentifier(from: referenceObject)
                }

            }
            return identifier
        }
        set {
            objc_setAssociatedObject(self, kAFResourceIdentifierObjectKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

}

class AFIncrementalStore {}
