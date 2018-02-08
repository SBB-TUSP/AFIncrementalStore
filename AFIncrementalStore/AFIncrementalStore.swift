//
//  AFIncrementalStore.swift
//  
//
//  Created by Alessandro Ranaldi on 06/02/2018.
//

import Foundation
import CoreData

@objc
protocol AFIncrementalStoreHttpClient {
    // TODO: add methods
}

// MARK: -

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

func AFResourceIdentifier(from referenceObject: Any?) -> String? {
    guard let referenceObject = referenceObject as? AnyClass else {
        return nil
    }
    let string = "\(referenceObject)"
    return string.hasPrefix(kAFReferenceObjectPrefix) ? "\(string[kAFReferenceObjectPrefix.endIndex...])" : string
}

private func AFSaveManagedObjectContextOrThrowInternalConsistencyException(_ context: NSManagedObjectContext) {
    do {
        try context.save()
    } catch let error as NSError {
        NSException(name: .internalInconsistencyException, reason: error.localizedFailureReason, userInfo: [NSUnderlyingErrorKey: error]).raise()
    }
}

fileprivate extension NSManagedObject {

    fileprivate var af_resourceIdentifier: String? {
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

@objc
private class AFIncrementalStore: NSPersistentStore {

    private var backingObjectIdByObjectId: NSCache<NSManagedObjectID, NSManagedObjectID>!

    private var registeredObjectIdsByEntityNameAndNestedResourceIdentifier: [String: [String: NSManagedObjectID]] = [:]

    private var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator?

    private var _backingManagedObjectContext: NSManagedObjectContext?

    private var httpClient: AFRESTClient? // TODO: change type

    private static var type: String {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +type. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
    }

    private static var model: NSManagedObjectModel {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +model. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
    }

    // MARK: -

    private func notify(context: NSManagedObjectContext?, about operation: AFHTTPRequestOperation?, for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, fetchedObjectIds: [NSManagedObjectID]?, didFetch: Bool) {
        guard let context = context,
            let operation = operation,
            let fetchRequest = fetchRequest else {
                return
        }
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

    private func notify(context: NSManagedObjectContext?, about operations: [AFHTTPRequestOperation]?, for request: NSSaveChangesRequest?, didSave: Bool) {
        guard let context = context,
            let operations = operations,
            let request = request else {
                return
        }
        let name: Notification.Name = didSave ? .AFIncrementalStoreContextDidSaveRemoteValues : .AFIncrementalStoreContextWillSaveRemoteValues
        let userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: operations,
            AFIncrementalStorePersistentStoreRequestKey: request
        ]
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext?, about operation: AFHTTPRequestOperation?, forNewValuesForObjectWithId objectId: NSManagedObjectID?, didFetch: Bool) {
        guard let context = context,
            let operation = operation,
            let objectId = objectId else {
                return
        }
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchNewValuesForObject : .AFIncrementalStoreContextWillFetchNewValuesForObject
        let userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStoreFaultingObjectIDKey: objectId
        ]
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext?, about operation: AFHTTPRequestOperation?, forNewValuesFor relationship: NSRelationshipDescription?, forObjectWithId objectId: NSManagedObjectID?, didFetch: Bool) {
        guard let context = context,
            let operation = operation,
            let relationship = relationship,
            let objectId = objectId else {
                return
        }
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

    private func insertOrUpdateObjects(from representationOrArrayOfRepresentation: Any?, of entity: NSEntityDescription?, from response: HTTPURLResponse?, with context: NSManagedObjectContext, completion: (([NSManagedObject], [NSManagedObject]) -> Void)?) throws -> Bool {
        var error: NSError?
        guard let representationOrArrayOfRepresentation = representationOrArrayOfRepresentation else {
            return false
        }
        if (representationOrArrayOfRepresentation as? [String: Any])?.count == 0 || (representationOrArrayOfRepresentation as? [[String: Any]])?.count == 0 {
            completion?([], [])
            return false
        }
        let backingContext = self.backingManagedObjectContext
        let lastModified = response?.allHeaderFields["Last-Modified"] as? String
        var representations: [[String: Any]] = []
        if let representationOrArrayOfRepresentation = representationOrArrayOfRepresentation as? [[String: Any]] {
            representations = representationOrArrayOfRepresentation
        } else if let representationOrArrayOfRepresentation = representationOrArrayOfRepresentation as? [String: Any] {
            representations = [representationOrArrayOfRepresentation]
        }
        var managedObjects = [NSManagedObject]()
        var backingObjects = [NSManagedObject]()
        for representation in representations {
            let resourceIdentifier = httpClient?.resourceIdentifier(forRepresentation: representation, ofEntity: entity, from: response)
            guard let attributes = httpClient?.attributes(forRepresentation: representation, ofEntity: entity, from: response),
                let objectId = self.objectId(for: entity, with: resourceIdentifier),
                let entityName = entity?.name else {
                    continue
            }
            var object: NSManagedObject?
            context.performAndWait {
                object = try? context.existingObject(with: objectId)
            }
            object?.setValuesForKeys(attributes)
            let backingObjectId = objectIdForBackingObject(for: entity, with: resourceIdentifier)
            var backingObject: NSManagedObject?
            backingContext.performAndWait {
                if let backingObjectId = backingObjectId {
                    backingObject = try? backingContext.existingObject(with: backingObjectId)
                } else {
                    backingObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backingContext)
                    _ = try? backingObject?.managedObjectContext?.obtainPermanentIDs(for: [backingObject!])
                }
            }
            backingObject?.setValue(resourceIdentifier, forKey: kAFIncrementalStoreResourceIdentifierAttributeName)
            backingObject?.setValue(lastModified, forKey: kAFIncrementalStoreLastModifiedAttributeName)
            backingObject?.setValuesForKeys(attributes)
            if let object = object,
                backingObjectId == nil {
                context.insert(object)
            }
            let relationshipRepresentations = httpClient?.representationsForRelationships(fromRepresentation: representation, ofEntity: entity, from: response)
            for relationshipRepresentationItem in relationshipRepresentations ?? [:] {
                let relationship = entity?.relationshipsByName[relationshipRepresentationItem.key]
                if relationship == nil || (relationship!.isOptional && relationshipRepresentationItem.value is NSNull) {
                    continue
                }
                if relationshipRepresentationItem.value is NSNull || (relationshipRepresentationItem.value as? NSObject)?.value(forKey: "count") as? Int == 0 {
                    object?.setValue(nil, forKey: relationshipRepresentationItem.key)
                    backingObject?.setValue(nil, forKey: relationshipRepresentationItem.key)
                    continue
                }
                do {
                    _ = try insertOrUpdateObjects(from: relationshipRepresentationItem.value, of: relationship?.destinationEntity, from: response, with: context) {
                        objects, managedObjects in
                        if relationship?.isToMany == true {
                            if relationship?.isOrdered == true {
                                object?.setValue(managedObjects, forKey: relationship!.name)
                                backingObject?.setValue(backingObjects, forKey: relationship!.name)
                            } else {
                                object?.setValue(Set<NSManagedObject>(managedObjects), forKey: relationship!.name)
                                backingObject?.setValue(Set<NSManagedObject>(backingObjects), forKey: relationship!.name)
                            }
                        } else {
                            object?.setValue(managedObjects.last, forKey: relationship!.name)
                            backingObject?.setValue(backingObjects.last, forKey: relationship!.name)
                        }
                    }
                } catch let e as NSError {
                    error = e
                }
            }
            if let object = object {
                managedObjects.append(object)
            }
            if let backingObject = backingObject {
                backingObjects.append(backingObject)
            }
        }
        completion?(managedObjects, backingObjects)
        if let error = error {
            throw error
        }
        return true
    }

    private func execute(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) throws -> Any? {
        var error: NSError?
        let request = httpClient?.request(for: fetchRequest, with: context)
        if let _ = request?.url {
            var operation: AFHTTPRequestOperation?
            operation = httpClient?.httpRequestOperation(with: request, success: {
                operation, responseObject in
                context?.performAndWait {
                    let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: fetchRequest?.entity, fromResponseObject: responseObject)
                    let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    childContext.parent = context
                    if #available(iOS 10.0, *) {
                        childContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    } else {
                        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    }
                    childContext.performAndWait {
                        _ = try? self.insertOrUpdateObjects(from: representationOrArrayOfRepresentations, of: fetchRequest?.entity, from: operation?.response, with: childContext) {
                            objects, backingObjects in
                            let childObjects = childContext.registeredObjects
                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                            let backingContext = self.backingManagedObjectContext
                            backingContext.performAndWait {
                                AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                            }
                            context?.performAndWait {
                                for childObject in childObjects {
                                    guard let parentObject = context?.object(with: childObject.objectID) else {
                                        continue
                                    }
                                    context?.refresh(parentObject, mergeChanges: true)
                                }
                            }
                            self.notify(context: context, about: operation, for: fetchRequest, fetchedObjectIds: objects.map{$0.objectID}, didFetch: true)
                        }
                    }
                }
            }) {
                operation, error in
                if let error = error {
                    print("Error:", error)
                }
                self.notify(context: context, about: operation, for: fetchRequest, fetchedObjectIds: nil, didFetch: true)
            }
            notify(context: context, about: operation, for: fetchRequest, fetchedObjectIds: nil, didFetch: false)
        }
        let backingContext = backingManagedObjectContext
        let backingFetchRequest = fetchRequest?.copy() as? NSFetchRequest<NSFetchRequestResult>
        if let entityName = fetchRequest?.entityName ?? fetchRequest?.entity?.name {
            backingFetchRequest?.entity = NSEntityDescription.entity(forEntityName: entityName, in: backingContext)
            switch fetchRequest!.resultType {
            case .managedObjectResultType:
                backingFetchRequest?.resultType = .dictionaryResultType
                backingFetchRequest?.propertiesToFetch = [kAFIncrementalStoreResourceIdentifierAttributeName]
                var results = [[String: Any]]()
                backingContext.performAndWait {
                    do {
                        let optionalResults = try backingContext.fetch(backingFetchRequest!) as? [[String: Any]]
                        if let optionalResults = optionalResults {
                            results = optionalResults
                        }
                    } catch let e as NSError {
                        error = e
                    }
                }
                var objects = [NSManagedObject]()
                for resourceIdentifier in results.map({$0[kAFIncrementalStoreResourceIdentifierAttributeName] as? String}) {
                    guard let resourceIdentifier = resourceIdentifier,
                        let objectId = self.objectId(for: fetchRequest?.entity, with: resourceIdentifier),
                        let object = context?.object(with: objectId) else {
                            continue
                    }
                    object.af_resourceIdentifier = resourceIdentifier
                    objects.append(object)
                }
                if let error = error {
                    throw error
                }
                return objects
            case .managedObjectIDResultType:
                var objectIds = [NSManagedObjectID]()
                backingContext.performAndWait {
                    do {
                        let backingObjectIds = try backingContext.fetch(backingFetchRequest!) as? [NSManagedObjectID]
                        for backingObjectId in backingObjectIds ?? [] {
                            let backingObject = backingContext.object(with: backingObjectId)
                            guard let resourceId = backingObject.value(forKey: kAFIncrementalStoreResourceIdentifierAttributeName) as? String,
                                let objectId = self.objectId(for: fetchRequest?.entity, with: resourceId) else {
                                    continue
                            }
                            objectIds.append(objectId)
                        }
                    } catch let e as NSError {
                        error = e
                    }
                }
                if let error = error {
                    throw error
                }
                return objectIds
            case .dictionaryResultType: fallthrough
            case .countResultType:
                var result: [Any]?
                backingContext.performAndWait {
                    do {
                        result = try backingContext.fetch(backingFetchRequest!)
                    } catch let e as NSError {
                        error = e
                    }
                }
                if let error = error {
                    throw error
                }
                return result
            default:
                if let error = error {
                    throw error
                }
                return nil
            }
        }
    }

    private func execute(_ saveChangesRequest: NSSaveChangesRequest?, with context: NSManagedObjectContext?) throws -> Any? {
        var operations = [AFHTTPRequestOperation]()
        let backingContext = backingManagedObjectContext
        if httpClient?.responds(to: #selector(AFHTTPClient.request(forInsertedObject:))) == true { // TODO: Use the Protocol, Luke!
            for insertedObject in saveChangesRequest?.insertedObjects ?? [] {
                let request = httpClient?.request(forInsertedObject: insertedObject)
                if request == nil,
                    let entityName = insertedObject.entity.name {
                    backingContext.performAndWait {
                        var UUID = CFUUIDCreate(kCFAllocatorDefault)
                        let resourceIdentifier = CFUUIDCreateString(kCFAllocatorDefault, UUID)
                        UUID = nil
                        let backingObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backingContext)
                        _ = try? backingObject.managedObjectContext?.obtainPermanentIDs(for: [backingObject])
                        backingObject.setValue(resourceIdentifier, forKey: kAFIncrementalStoreResourceIdentifierAttributeName)
                        update(backingObject, withAttributeAndRelationshipValuesFrom: insertedObject)
                        _ = try? backingContext.save()
                    }
                    context?.performAndWait {
                        insertedObject.willChangeValue(forKey: "objectID")
                        _ = try? context?.obtainPermanentIDs(for: [insertedObject])
                        insertedObject.didChangeValue(forKey: "objectID")
                    }
                    continue
                }
                let operation = httpClient?.httpRequestOperation(with: request, success: {
                    operation, responseObject in
                    let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: insertedObject.entity, fromResponseObject: responseObject)
                    guard let representation = representationOrArrayOfRepresentations as? [String: Any],
                        let entityName = insertedObject.entity.name else {
                        // TODO: notify
                        return
                    }
                    let resourceIdentifier = self.httpClient?.resourceIdentifier(forRepresentation: representation, ofEntity: insertedObject.entity, from: operation?.response)
                    let backingObjectId = self.objectIdForBackingObject(for: insertedObject.entity, with: resourceIdentifier)
                    insertedObject.af_resourceIdentifier = resourceIdentifier
                    if let dictionary = self.httpClient?.attributes(forRepresentation: representation, ofEntity: insertedObject.entity, from: operation?.response) {
                        insertedObject.managedObjectContext?.performAndWait {
                            insertedObject.setValuesForKeys(dictionary)
                        }
                    }
                    var backingObject: NSManagedObject?
                    backingContext.performAndWait {
                        if let backingObjectId = backingObjectId {
                            backingObject = try? backingContext.existingObject(with: backingObjectId)
                        }
                        if backingObject == nil {
                            backingObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backingContext)
                            _ = try? backingObject!.managedObjectContext?.obtainPermanentIDs(for: [backingObject!])
                        }
                        backingObject?.setValue(resourceIdentifier, forKey: kAFIncrementalStoreResourceIdentifierAttributeName)
                        self.update(backingObject, withAttributeAndRelationshipValuesFrom: insertedObject)
                        _ = try? backingContext.save()
                    }
                    context?.performAndWait {
                        insertedObject.willChangeValue(forKey: "objectID")
                        _ = try? context?.obtainPermanentIDs(for: [insertedObject])
                        insertedObject.didChangeValue(forKey: "objectID")
                        context?.refresh(insertedObject, mergeChanges: false)
                    }
                }) {
                    operation, error in
                    if let error = error {
                        print("Insert Error:", error)
                    }
                    // Reset destination objects to prevent dangling relationships
                    for relationship in insertedObject.entity.relationshipsByName.map({$1}) {
                        if relationship.inverseRelationship == nil {
                            continue
                        }
                        var destinationObjects: NSFastEnumeration? = nil
                        if relationship.isToMany {
                            destinationObjects = insertedObject.value(forKey: relationship.name) as? NSFastEnumeration
                        } else if let destinationObject = insertedObject.value(forKey: relationship.name) as? NSManagedObject {
                            destinationObjects = Array<NSManagedObject>([destinationObject]) as NSFastEnumeration
                        }
                        for destinationObject in destinationObjects {
                            context?.performAndWait {
                                context?.refresh(destinationObject, mergeChanges: false)
                            }
                        }
                    }
                }
                if let operation = operation {
                    operations.append(operation)
                }
            }
        }
        // TODO: change selector
        if httpClient?.responds(to: #selector(AFRESTClient.request(forUpdatedObject:))) == true {
            for updatedObject in saveChangesRequest?.updatedObjects ?? [] {
                let backingObjectId = objectIdForBackingObject(for: updatedObject.entity, with: AFResourceIdentifier(from: referenceObject(for: updatedObject.objectID)))
                let request = httpClient?.request(forUpdatedObject: updatedObject)
                if request == nil {
                    backingContext.performAndWait {
                        let backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!)
                        self.update(backingObject, withAttributeAndRelationshipValuesFrom: updatedObject)
                        _ = try? backingContext.save()
                    }
                    continue
                }
                let operation = self.httpClient?.httpRequestOperation(with: request, success: {
                    operation, responseObject in
                    let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: updatedObject.entity, fromResponseObject: responseObject)
                    if let representation = representationOrArrayOfRepresentations as? [String: Any] {
                        if let dictionary = self.httpClient?.attributes(forRepresentation: representation, ofEntity: updatedObject.entity, from: operation?.response) {
                            updatedObject.managedObjectContext?.performAndWait {
                                updatedObject.setValuesForKeys(dictionary)
                            }
                            if let backingObjectId = backingObjectId {
                                backingContext.performAndWait {
                                    if let backingObject = try? backingContext.existingObject(with: backingObjectId) {
                                        self.update(backingObject, withAttributeAndRelationshipValuesFrom: updatedObject)
                                        _ = try? backingContext.save()
                                    }
                                }
                            }
                        }
                        context?.performAndWait {
                            context?.refresh(updatedObject, mergeChanges: true)
                        }
                    }
                }) {
                    operation, error in
                    if let error = error {
                        print("Update Error:", error)
                    }
                    context?.performAndWait {
                        context?.refresh(updatedObject, mergeChanges: true)
                    }
                }
            }
        }
        // TODO: change selector
        if self.httpClient?.responds(to: #selector(AFRESTClient.request(forDeletedObject:))) {
            for deletedObject in saveChangesRequest?.deletedObjects ?? [] {
                let backingObjectId = self.objectIdForBackingObject(for: deletedObject.entity, with: AFResourceIdentifier(from: referenceObject(for: deletedObject.objectID)))
                let request = self.httpClient?.request(forDeletedObject: deletedObject)
                if request == nil {
                    backingContext.performAndWait {
                        if let backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!) {
                            backingContext.delete(backingObject)
                            _ = try? backingContext.save()
                        }
                    }
                    continue
                }
                let operation = self.httpClient?.httpRequestOperation(with: request, success: {
                    operation, responseObject in
                    backingContext.performAndWait {
                        if let backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!) {
                            backingContext.delete(backingObject)
                            _ = try? backingContext.save()
                        }
                    }
                }, failure: {
                    operation, error in
                    if let error = error {
                        print("Delete Error:", error)
                    }
                })
                if let operation = operation {
                    operations.append(operation)
                }
            }
        }
        // NSManagedObjectContext removes object references from an NSSaveChangesRequest as each object is saved, so create a copy of the original in order to send useful information in AFIncrementalStoreContextDidSaveRemoteValues notification.
        let saveChangesRequestCopy = NSSaveChangesRequest(inserted: saveChangesRequest?.insertedObjects, updated: saveChangesRequest?.updatedObjects, deleted: saveChangesRequest?.deletedObjects, locked: saveChangesRequest?.lockedObjects)
        notify(context: context, about: operations, for: saveChangesRequestCopy, didSave: false)
        httpClient?.enqueueBatch(ofHTTPRequestOperations: operations, progressBlock: nil, completionBlock: {
            operations in
            self.notify(context: context, about: operations, for: saveChangesRequest, didSave: true)
        })
        return [Any]()
    }

    // MARK: -

    override func loadMetadata() throws {
        guard backingObjectIdByObjectId == nil,
            let model = persistentStoreCoordinator?.managedObjectModel.copy() as? NSManagedObjectModel else {
                return
        }
        self.metadata = [
            NSStoreUUIDKey: ProcessInfo.processInfo,
            NSStoreTypeKey: NSStringFromClass(classForCoder)
        ]
        backingObjectIdByObjectId = NSCache()

        for entity in model.entities {
            // Don't add properties for sub-entities, as they already exist in the super-entity
            if let _ = entity.superentity {
                continue
            }
            let resourceIdentifierProperty = NSAttributeDescription()
            resourceIdentifierProperty.name = kAFIncrementalStoreResourceIdentifierAttributeName
            resourceIdentifierProperty.attributeType = .stringAttributeType
            resourceIdentifierProperty.isIndexed = true
            let lastModifiedProperty = NSAttributeDescription()
            lastModifiedProperty.name = kAFIncrementalStoreLastModifiedAttributeName
            lastModifiedProperty.attributeType = .stringAttributeType
            lastModifiedProperty.isIndexed = false
            entity.properties.append(contentsOf: [resourceIdentifierProperty, lastModifiedProperty])
        }
        backingPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    }

    fileprivate func referenceObject(for objectId: NSManagedObjectID?) -> String? {return nil}

    private func newObjectId(for entity: NSEntityDescription?, referenceObject: String) -> NSManagedObjectID? {return nil}

}
