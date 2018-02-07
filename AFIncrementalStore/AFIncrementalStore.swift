//
//  AFIncrementalStore.swift
//  
//
//  Created by Alessandro Ranaldi on 06/02/2018.
//

import Foundation
import CoreData

fileprivate extension NSExceptionName {

    fileprivate static var AFIncrementalStoreUnimplementedMethodException: NSExceptionName {
        return .init("com.alamofire.incremental-store.exceptions.unimplemented-method")
    }

}

private let AFIncrementalStoreRequestOperationsKey: String = "AFIncrementalStoreRequestOperations"

private let AFIncrementalStoreFetchedObjectIDsKey: String = "AFIncrementalStoreFetchedObjectIDs"

private let AFIncrementalStoreFaultingObjectIDKey: String = "AFIncrementalStoreFaultingObjectID"

private let AFIncrementalStoreFaultingRelationshipKey: String = "AFIncrementalStoreFaultingRelationship"

private let AFIncrementalStorePersistentStoreRequestKey: String = "AFIncrementalStorePersistentStoreRequest"

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

private var kAFResourceIdentifierObjectKey = UInt8(0)

private var kAFIncrementalStoreResourceIdentifierAttributeName: String {
    return "__af_resourceIdentifier"
}

private var kAFIncrementalStoreLastModifiedAttributeName: String {
    return "__af_lastModified"
}

private var kAFReferenceObjectPrefix: String {
    return "__af_"
}

private func AFReferenceObject(from resourceIdentifier: String?) -> String? {
    guard let resourceIdentifier = resourceIdentifier else {
        return nil
    }
    return kAFReferenceObjectPrefix.appending(resourceIdentifier)
}

fileprivate func AFResourceIdentifier(from referenceObject: String?) -> String? {
    guard let string = referenceObject else {
        return nil
    }
    return string.hasPrefix(kAFReferenceObjectPrefix) ? "\(string[kAFReferenceObjectPrefix.endIndex...])" : string
}

private func AFSaveManagedObjectContextOrThrowInternalConsistencyException(_ context: NSManagedObjectContext) {
    do {
        try context.save()
    } catch let error as NSError {
        NSException(name: .internalInconsistencyException, reason: error.localizedFailureReason, userInfo: [NSUnderlyingErrorKey: error]).raise()
    }
}

private extension NSManagedObject {

    private var af_resourceIdentifier: String? {
        get {
            let identifier = objc_getAssociatedObject(self, &kAFResourceIdentifierObjectKey) as? String
            if identifier == nil {
                guard let referenceObject = (objectID.persistentStore as? AFIncrementalStore)?.referenceObject(for: objectID) else {
                    return nil
                }
                return AFResourceIdentifier(from: referenceObject)
            }
            return identifier
        }
        set {
            objc_setAssociatedObject(self, &kAFResourceIdentifierObjectKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

}

// MARK: -

private class AFIncrementalStore: NSPersistentStore {

    private var backingObjectIdByObjectId = NSCache<NSManagedObjectID, NSManagedObjectID>()

    private var registeredObjectIdsByEntityNameAndNestedResourceIdentifier: [String: [String: NSManagedObjectID]] = [:]

    private var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator?

    private var _backingManagedObjectContext: NSManagedObjectContext?

    private var httpClient: AFHTTPClient?

    private static var type: String {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +type. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
    }

    private static var model: NSManagedObjectModel {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +model. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
    }

    // MARK: -

    private func notify(context: NSManagedObjectContext, about operation: AFHTTPRequestOperation, for fetchRequest: NSFetchRequest<NSFetchRequestResult>, fetchedObjectIds: [NSManagedObjectID]?, didFetch: Bool) {
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchRemoteValues : .AFIncrementalStoreContextWillFetchRemoteValues
        var userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStorePersistentStoreRequestKey: fetchRequest
        ]
        if didFetch,
            let fetchedObjectIds = fetchedObjectIds {
            userInfo[AFIncrementalStoreFetchedObjectIDsKey] = fetchedObjectIds
        }
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext, about operations: [AFHTTPRequestOperation], for request: NSSaveChangesRequest, didSave: Bool) {
        let name: Notification.Name = didSave ? .AFIncrementalStoreContextDidSaveRemoteValues : .AFIncrementalStoreContextWillSaveRemoteValues
        let userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: operations,
            AFIncrementalStorePersistentStoreRequestKey: request
        ]
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext, about operation: AFHTTPRequestOperation, forNewValuesForObjectWithId objectId: NSManagedObjectID, didFetch: Bool) {
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchNewValuesForObject : .AFIncrementalStoreContextWillFetchNewValuesForObject
        let userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStoreFaultingObjectIDKey: objectId
        ]
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext, about operation: AFHTTPRequestOperation, forNewValuesFor relationship: NSRelationshipDescription, forObjectWithId objectId: NSManagedObjectID, didFetch: Bool) {
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchNewValuesForRelationship : .AFIncrementalStoreContextWillFetchNewValuesForRelationship
        let userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStoreFaultingObjectIDKey: objectId,
            AFIncrementalStoreFaultingRelationshipKey: relationship
        ]
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    // MARK: -

    private var backingManagedObjectContext: NSManagedObjectContext {
        if _backingManagedObjectContext == nil {
            let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            newContext.persistentStoreCoordinator = backingPersistentStoreCoordinator
            newContext.retainsRegisteredObjects = true
            _backingManagedObjectContext = newContext
        }
        return _backingManagedObjectContext!
    }

    private func objectId(for entity: NSEntityDescription?, with resourceIdentifier: String?) -> NSManagedObjectID? {
        guard let entityName = entity?.name,
            let resourceIdentifier = resourceIdentifier else {
                return nil
        }
        return registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName]?[resourceIdentifier] ?? newObjectId(for: entity, referenceObject: resourceIdentifier)
    }

    private func objectIdForBackingObject(for entity: NSEntityDescription?, with resourceIdentifier: String?) -> NSManagedObjectID? {
        guard let entityName = entity?.name,
            let resourceIdentifier = resourceIdentifier,
            let objectId = self.objectId(for: entity, with: resourceIdentifier) else {
            return nil
        }
        var backingObjectId = backingObjectIdByObjectId.object(forKey: objectId)
        if backingObjectId == nil {
            let context = backingManagedObjectContext
            context.performAndWait {
                let request = NSFetchRequest<NSManagedObjectID>()
                request.resultType = .managedObjectIDResultType
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "%K = %@", kAFIncrementalStoreResourceIdentifierAttributeName, resourceIdentifier)
                request.entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
                do {
                    backingObjectId = try context.fetch(request).last
                } catch let error as NSError {
                    print("Error:", error)
                }
            }
        }
        if let backingObjectId = backingObjectId {
            backingObjectIdByObjectId.setObject(backingObjectId, forKey: objectId)
        }
        return backingObjectId
    }

    private func update(_ backingObject: NSManagedObject?, withAttributeAndRelationshipValuesFrom managedObject: NSManagedObject?) {
        guard let backingObject = backingObject,
            let managedObject = managedObject else {
                return
        }
        var relationshipValues = [String: Any]()
        for relationship in managedObject.entity.relationshipsByName.map({$1}) {
            guard !managedObject.hasFault(forRelationshipNamed: relationship.name) else {
                continue
            }
            if relationship.isToMany {
                if relationship.isOrdered {
                    guard let relationshipValue = managedObject.value(forKey: relationship.name) as? [NSManagedObject] else {
                        continue
                    }
                    var backingRelationshipValue = [NSManagedObject]()
                    for relationshipManagedObject in relationshipValue {
                        guard !relationshipManagedObject.objectID.isTemporaryID,
                            let backingRelationshipObjectId = objectIdForBackingObject(for: relationship.destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipManagedObject.objectID))),
                            let context = backingObject.managedObjectContext,
                            let backingRelationshipObject = try? context.existingObject(with: backingRelationshipObjectId) else {
                                continue
                        }
                        backingRelationshipValue.append(backingRelationshipObject)
                    }
                    relationshipValues[relationship.name] = backingRelationshipValue
                } else {
                    guard let relationshipValue = managedObject.value(forKey: relationship.name) as? Set<NSManagedObject> else {
                        continue
                    }
                    var backingRelationshipValue = Set<NSManagedObject>()
                    for relationshipManagedObject in relationshipValue {
                        guard !relationshipManagedObject.objectID.isTemporaryID,
                            let backingRelationshipObjectId = objectIdForBackingObject(for: relationship.destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipManagedObject.objectID))),
                            let context = backingObject.managedObjectContext,
                            let backingRelationshipObject = try? context.existingObject(with: backingRelationshipObjectId) else {
                                continue
                        }
                        backingRelationshipValue.insert(backingRelationshipObject)
                    }
                    relationshipValues[relationship.name] = backingRelationshipValue
                }
            } else {
                guard let relationshipValue = managedObject.value(forKey: relationship.name) as? NSManagedObject,
                    !relationshipValue.objectID.isTemporaryID,
                    let backingRelationshipObjectId = objectIdForBackingObject(for: relationship.destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipValue.objectID))),
                    let context = backingObject.managedObjectContext,
                    let backingRelationshipObject = try? context.existingObject(with: backingRelationshipObjectId) else {
                        continue
                }
                relationshipValues[relationship.name] = backingRelationshipObject
            }
        }
        backingObject.setValuesForKeys(relationshipValues)
        backingObject.setValuesForKeys(managedObject.dictionaryWithValues(forKeys: managedObject.entity.attributesByName.map({ (key, _) -> String in
            return key
        })))
    }

    // MARK: -

    fileprivate func referenceObject(for objectId: NSManagedObjectID?) -> String? {return nil}

    private func newObjectId(for entity: NSEntityDescription?, referenceObject: String) -> NSManagedObjectID? {return NSManagedObjectID()}

}
