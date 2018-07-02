//
//  AFIncrementalStore.swift
//
//
//  Created by Alessandro Ranaldi on 06/02/2018.
//

import Foundation
import CoreData
import AFNetworking

/**
 The `AFIncrementalStoreHTTPClient` protocol defines the methods used by the HTTP client to interract with the associated web services of an `AFIncrementalStore`.
 */
@objc
public protocol AFIncrementalStoreHttpClient {

    // MARK: - Required Methods

    /**
     Returns an `NSDictionary` or an `NSArray` of `NSDictionaries` containing the representations of the resources found in a response object.

     @discussion For example, if `GET /users` returned an `NSDictionary` with an array of users keyed on `"users"`, this method would return the keyed array. Conversely, if `GET /users/123` returned a dictionary with all of the atributes of the requested user, this method would simply return that dictionary.

     @param entity The entity represented
     @param responseObject The response object returned from the server.

     @return An `NSDictionary` with the representation or an `NSArray` of `NSDictionaries` containing the resource representations.
     */
    @objc func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any?

    /**
     Returns an `NSDictionary` containing the representations of associated objects found within the representation of a response object, keyed by their relationship name.

     @discussion For example, if `GET /albums/123` returned the representation of an album, including the tracks as sub-entities, keyed under `"tracks"`, this method would return a dictionary with an array of representations for those objects, keyed under the name of the relationship used in the model (which is likely also to be `"tracks"`). Likewise, if an album also contained a representation of its artist, that dictionary would contain a dictionary representation of that artist, keyed under the name of the relationship used in the model (which is likely also to be `"artist"`).

     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.

     @return An `NSDictionary` containing representations of relationships, keyed by relationship name.
     */
    @objc func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]

    /**
     Returns the resource identifier for the resource whose representation of an entity came from the specified HTTP response. A resource identifier is a string that uniquely identifies a particular resource among all resource types. If new attributes come back for an existing resource identifier, the managed object associated with that resource identifier will be updated, rather than a new object being created.

     @discussion For example, if `GET /posts` returns a collection of posts, the resource identifier for any particular one might be its URL-safe "slug" or parameter string, or perhaps its numeric id.  For example: `/posts/123` might be a resource identifier for a particular post.

     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.

     @return An `NSString` resource identifier for the resource.
     */
    @objc func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String?

    /**
     Returns the attributes for the managed object corresponding to the representation of an entity from the specified response. This method is used to get the attributes of the managed object from its representation returned in `-representationOrArrayOfRepresentationsFromResponseObject` or `representationsForRelationshipsFromRepresentation:ofEntity:fromResponse:`.

     @discussion For example, if the representation returned from `GET /products/123` had a `description` field that corresponded with the `productDescription` attribute in its Core Data model, this method would set the value of the `productDescription` key in the returned dictionary to the value of the `description` field in representation.

     @param representation The resource representation.
     @param entity The entity for the representation.
     @param response The HTTP response for the resource request.

     @return An `NSDictionary` containing the attributes for a managed object.
     */
    @objc func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]?

    /**
     Returns a URL request object for the specified fetch request within a particular managed object context.

     @discussion For example, if the fetch request specified the `User` entity, this method might return an `NSURLRequest` with `GET /users` if the web service was RESTful, `POST /endpoint?method=users.getAll` for an RPC-style system, or a request with an XML envelope body for a SOAP webservice.

     @param fetchRequest The fetch request to translate into a URL request.
     @param context The managed object context executing the fetch request.

     @return An `NSURLRequest` object corresponding to the specified fetch request.
     */
    @objc func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest?

    /**
     Returns a URL request object with a given HTTP method for a particular managed object. This method is used in `AFIncrementalStore -newValuesForObjectWithID:withContext:error`.

     @discussion For example, if a `User` managed object were to be refreshed, this method might return a `GET /users/123` request.

     @param method The HTTP method of the request.
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.

     @return An `NSURLRequest` object with the provided HTTP method for the resource corresponding to the managed object.
     */
    @objc func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest?

    /**
     Returns a URL request object with a given HTTP method for a particular relationship of a given managed object. This method is used in `AFIncrementalStore -newValueForRelationship:forObjectWithID:withContext:error:`.

     @discussion For example, if a `Department` managed object was attempting to fulfill a fault on the `employees` relationship, this method might return `GET /departments/sales/employees`.

     @param method The HTTP method of the request.
     @param relationship The relationship of the specifified managed object
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.

     @return An `NSURLRequest` object with the provided HTTP method for the resource or resoures corresponding to the relationship of the managed object.

     */
    @objc func request(withMethod method: String, pathForRelationship relationship: NSRelationshipDescription?, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest?

    // MARK: - Optional Methods

    /**
     Returns the attributes representation of an entity from the specified managed object. This method is used to get the attributes of the representation from its managed object.

     @discussion For example, if the representation sent to `POST /products` or `PUT /products/123` had a `description` field that corresponded with the `productDescription` attribute in its Core Data model, this method would set the value of the `productDescription` field to the value of the `description` key in representation/dictionary.

     @param attributes The resource representation.
     @param managedObject The `NSManagedObject` for the representation.

     @return An `NSDictionary` containing the attributes for a representation, based on the given managed object.
     */
    @objc optional func representation(ofAttributes attributes: [AnyHashable : Any]!, of managedObject: NSManagedObject!) -> [AnyHashable : Any]!

    /**

     */
    @objc optional func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest?

    /**

     */
    @objc optional func request(forUpdatedObject updatedObject: NSManagedObject!) -> URLRequest?

    /**

     */
    @objc optional func request(forDeletedObject deletedObject: NSManagedObject!) -> URLRequest?

    /**
     Returns whether the client should fetch remote attribute values for a particular managed object. This method is consulted when a managed object faults on an attribute, and will call `-requestWithMethod:pathForObjectWithID:withContext:` if `YES`.

     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.

     @return `YES` if an HTTP request should be made, otherwise `NO.
     */
    @objc optional func shouldFetchRemoteAttributeValues(forObjectWith objectID: NSManagedObjectID, in context: NSManagedObjectContext!) -> Bool

    /**
     Returns whether the client should fetch remote relationship values for a particular managed object. This method is consulted when a managed object faults on a particular relationship, and will call `-requestWithMethod:pathForRelationship:forObjectWithID:withContext:` if `YES`.

     @param relationship The relationship of the specifified managed object
     @param objectID The object ID for the specified managed object.
     @param context The managed object context for the managed object.

     @return `YES` if an HTTP request should be made, otherwise `NO.
     */
    @objc optional func shouldFetchRemoteValues(forRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool

}

// MARK: - Functions

/**
 There is a bug in Core Data wherein managed object IDs whose reference object is a string beginning with a digit will incorrectly strip any subsequent non-numeric characters from the reference object. This breaks any functionality related to URI representations of the managed object ID, and likely other methods as well. For example, an object ID with a reference object of @"123ABC" would generate one with a URI represenation `coredata://store-UUID/Entity/123`, rather than the expected `coredata://store-UUID/Entity/123ABC`. As a fix, rather than resource identifiers being used directly as reference objects, they are prepended with a non-numeric constant first.

 Thus, in order to get the resource identifier of a managed object's reference object, you must use the function `AFResourceIdentifierFromReferenceObject()`.

 See https://github.com/AFNetworking/AFIncrementalStore/issues/82 for more details.
 */
public func AFReferenceObject(from resourceIdentifier: String?) -> String? {
    guard let resourceIdentifier = resourceIdentifier else {
        return nil
    }
    return kAFReferenceObjectPrefix.appending(resourceIdentifier)
}

public func AFResourceIdentifier(from referenceObject: Any) -> String {
    let string = "\(referenceObject)"
    return string.hasPrefix(kAFReferenceObjectPrefix) ? "\(string[kAFReferenceObjectPrefix.endIndex...])" : string
}

// MARK: - Constants

public extension NSExceptionName {

    /**
     The name of the exception called when `AFIncrementalStore` or a subclass is attempted to be used, without implementing one of the required methods.
     */
    public static var AFIncrementalStoreUnimplementedMethodException: NSExceptionName {
        return .init("com.alamofire.incremental-store.exceptions.unimplemented-method")
    }

}

// MARK: - Notifications

@objc
public extension NSNotification {

    /**
     Posted before an HTTP request operation corresponding to a fetch request starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains the finished request operation, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextWillFetchRemoteValues: String {
        return "AFIncrementalStoreContextWillFetchRemoteValues"
    }

    /**
     Posted after an HTTP request operation corresponding to a fetch request finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains the finished request operation, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextDidFetchRemoteValues: String {
        return "AFIncrementalStoreContextDidFetchRemoteValues"
    }

    /**
     Posted before an HTTP request operation corresponding to a fetch request starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextWillSaveRemoteValues: String {
        return "AFIncrementalStoreContextWillSaveRemoteValues"
    }

    /**
     Posted after an HTTP request operation corresponding to a fetch request finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextDidSaveRemoteValues: String {
        return "AFIncrementalStoreContextDidSaveRemoteValues"
    }

    /**
     Posted before an HTTP request operation corresponding to an attribute fault starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextWillFetchNewValuesForObject: String {
        return "AFIncrementalStoreContextWillFetchNewValuesForObject"
    }

    /**
     Posted after an HTTP request operation corresponding to an attribute fault finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextDidFetchNewValuesForObject: String {
        return "AFIncrementalStoreContextDidFetchNewValuesForObject"
    }

    /**
     Posted before an HTTP request operation corresponding to an relationship fault starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `AFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.

     */
    public static var AFIncrementalStoreContextWillFetchNewValuesForRelationship: String {
        return "AFIncrementalStoreContextWillFetchNewValuesForRelationship"
    }

    /**
     Posted after an HTTP request operation corresponding to a relationship fault finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `AFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextDidFetchNewValuesForRelationship: String {
        return "AFIncrementalStoreContextDidFetchNewValuesForRelationship"
    }

}

public extension Notification.Name {

    /**
     Posted before an HTTP request operation corresponding to a fetch request starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains the finished request operation, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextWillFetchRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchRemoteValues")
    }

    /**
     Posted after an HTTP request operation corresponding to a fetch request finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains the finished request operation, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextDidFetchRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchRemoteValues")
    }

    /**
     Posted before an HTTP request operation corresponding to a fetch request starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextWillSaveRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextWillSaveRemoteValues")
    }

    /**
     Posted after an HTTP request operation corresponding to a fetch request finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `AFIncrementalStorePersistentStoreRequestKey`.
     */
    public static var AFIncrementalStoreContextDidSaveRemoteValues: Notification.Name {
        return .init("AFIncrementalStoreContextDidSaveRemoteValues")
    }

    /**
     Posted before an HTTP request operation corresponding to an attribute fault starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextWillFetchNewValuesForObject: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchNewValuesForObject")
    }

    /**
     Posted after an HTTP request operation corresponding to an attribute fault finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextDidFetchNewValuesForObject: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchNewValuesForObject")
    }

    /**
     Posted before an HTTP request operation corresponding to an relationship fault starts.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `AFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.

     */
    public static var AFIncrementalStoreContextWillFetchNewValuesForRelationship: Notification.Name {
        return .init("AFIncrementalStoreContextWillFetchNewValuesForRelationship")
    }

    /**
     Posted after an HTTP request operation corresponding to a relationship fault finishes.
     The object is the managed object context of the request.
     The notification `userInfo` contains an array of request operations, keyed at `AFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `AFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `AFIncrementalStoreFaultingObjectIDKey`.
     */
    public static var AFIncrementalStoreContextDidFetchNewValuesForRelationship: Notification.Name {
        return .init("AFIncrementalStoreContextDidFetchNewValuesForRelationship")
    }

}

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextWillFetchRemoteValues` or `AFIncrementalStoreContextDidFetchRemoteValues` as well as `AFIncrementalStoreContextWillSaveRemoteValues` or `AFIncrementalStoreContextDidSaveRemoteValues` notifications.
 The corresponding value is an `NSArray` of `AFHTTPRequestOperation` objects corresponding to the request operations triggered by the fetch or save changes request.
 */
public let AFIncrementalStoreRequestOperationsKey: String = "AFIncrementalStoreRequestOperations"

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextDidFetchRemoteValues` as well as `AFIncrementalStoreContextDidSaveRemoteValues` or `AFIncrementalStoreContextDidFetchNewValuesForObject` or `AFIncrementalStoreContextDidFetchNewValuesForRelationship` notification.
 The corresponding value is an `NSArray` of `NSError` containing 1 element if there was an error.
 For the `AFIncrementalStoreContextDidSaveRemoteValues` notification it is a dictionary with `NSManagedObjectID` as keys and `NSError` as elements, to contain any errors with the associated API requests.
 */
public let AFIncrementalStoreRequestErrorsKey: String = "AFIncrementalStoreRequestErrors"

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextWillFetchRemoteValues` or `AFIncrementalStoreContextDidFetchRemoteValues` notification.
 The corresponding value is an `NSArray` of `NSManagedObjectIDs` for the objects returned by the remote HTTP request for the associated fetch request.
 */
public let AFIncrementalStoreFetchedObjectIDsKey: String = "AFIncrementalStoreFetchedObjectIDs"

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextWillFetchNewValuesForObject` or `AFIncrementalStoreContextDidFetchNewValuesForObject` notification.
 The corresponding value is an `NSManagedObjectID` for the faulting managed object.
 */
public let AFIncrementalStoreFaultingObjectIDKey: String = "AFIncrementalStoreFaultingObjectID"

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextWillFetchNewValuesForRelationship` or `AFIncrementalStoreContextDidFetchNewValuesForRelationship` notification.
 The corresponding value is an `NSRelationshipDescription` for the faulting relationship.
 */
public let AFIncrementalStoreFaultingRelationshipKey: String = "AFIncrementalStoreFaultingRelationship"

/**
 A key in the `userInfo` dictionary in a `AFIncrementalStoreContextWillFetchRemoteValues` or `AFIncrementalStoreContextDidFetchRemoteValues` notification.
 The corresponding value is an `NSPersistentStoreRequest` object representing the associated fetch or save request. */
public let AFIncrementalStorePersistentStoreRequestKey: String = "AFIncrementalStorePersistentStoreRequest"

// MARK: -

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

private func AFSaveManagedObjectContextOrThrowInternalConsistencyException(_ context: NSManagedObjectContext) {
    guard context.hasChanges else {
        return
    }
    do {
        try context.save()
    } catch let error as NSError {
        NSException(name: .internalInconsistencyException, reason: error.localizedFailureReason, userInfo: [NSUnderlyingErrorKey: error]).raise()
    }
}

public extension NSManagedObject {

    var af_resourceIdentifier: String? {
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

/**
 `AFIncrementalStore` is an abstract subclass of `NSIncrementalStore`, designed to allow you to load and save data incrementally to and from a one or more web services.

 ## Subclassing Notes

 ### Methods to Override

 In a subclass of `AFIncrementalStore`, you _must_ override the following methods to provide behavior appropriate for your store:

 - `+type`
 - `+model`

 Additionally, all `NSPersistentStore` subclasses, and thus all `AFIncrementalStore` subclasses must do `NSPersistentStoreCoordinator +registerStoreClass:forStoreType:` in order to be created by `NSPersistentStoreCoordinator -addPersistentStoreWithType:configuration:URL:options:error:`. It is recommended that subclasses register themselves in their own `+initialize` method.

 Optionally, `AFIncrementalStore` subclasses can override the following methods:

 - `-executeFetchRequest:withContext:error:`
 - `-executeSaveChangesRequest:withContext:error:`

 ### Methods Not To Be Overridden

 Subclasses should not override `-executeRequest:withContext:error`. Instead, override `-executeFetchRequest:withContext:error:` or `-executeSaveChangesRequest:withContext:error:`, which are called by `-executeRequest:withContext:error` depending on the type of persistent store request.
 */
@objc
open class AFIncrementalStore: NSIncrementalStore {

    // MARK: - Accessing Incremental Store Properties

    /**
     The HTTP client used to manage requests and responses with the associated web services.
     */
    @objc open var httpClient: (AFHTTPSessionManager & AFIncrementalStoreHttpClient)?

    /**
     The persistent store coordinator used to persist data from the associated web serivices locally.

     @discussion Rather than persist values directly, `AFIncrementalStore` manages and proxies through a persistent store coordinator.
     */
    @objc open var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator?

    // MARK: -

    private var backingObjectIdByObjectId: NSCache<NSManagedObjectID, NSManagedObjectID>!

    private var registeredObjectIdsByEntityNameAndNestedResourceIdentifier: [String: [String: Any]] = [:]

    private var _backingManagedObjectContext: NSManagedObjectContext?

    // MARK: - Required Methods

    /**
     Returns the string used as the `NSStoreTypeKey` value by the application's persistent store coordinator.

     @return The string used to describe the type of the store.
     */
    @objc open class var type: String {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +type. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
        return ""
    }

    /**
     Returns the managed object model used by the store.

     @return The managed object model used by the store
     */
    @objc open class var model: NSManagedObjectModel {
        NSException(name: .AFIncrementalStoreUnimplementedMethodException, reason: NSLocalizedString("Unimplemented method: +model. Must be overridden in a subclass", comment: ""), userInfo: nil).raise()
        return NSManagedObjectModel()
    }

    @objc open func beforeInsertOrUpdateObjects(from representationOrArrayOfRepresentation: Any?,
                                                of fetchRequest: NSFetchRequest<NSFetchRequestResult>?,
                                                from response: HTTPURLResponse?,
                                                with childContext: NSManagedObjectContext,
                                                with backingContext: NSManagedObjectContext,
                                                with backingObjectIdByObjectId: NSCache<NSManagedObjectID, NSManagedObjectID>) {
        print("implemented in child")
    }

    @objc open func updateContextObjects(_ context: NSManagedObjectContext?) {
        guard let parentContext = context?.parent else { return }
        parentContext.performAndWait {
            let objects = context?.registeredObjects
            objects?.forEach({ (obj) in
                let parentObject = parentContext.object(with: obj.objectID)
                parentContext.refresh(parentObject, mergeChanges: false)
            })
        }
    }

    // MARK: - Optional Methods

    /**

     */
    open func executeFetchRequest(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) throws -> Any? {
        var error: NSError?
        let request = httpClient?.request(for: fetchRequest, with: context)
        if let _ = request?.url, let request = request {
            var operation: URLSessionTask?
            operation = httpClient?.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in

                guard error == nil else {
                    self.notify(context: context, about: operation, error: error as NSError?, for: fetchRequest, fetchedObjectIds: nil, didFetch: true)
                    return
                }

                context?.performAndWait {
                    let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: fetchRequest?.entity, fromResponseObject: responseObject)
                    let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    childContext.parent = context
                    if #available(iOS 10.0, *) {
                        childContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    } else {
                        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    }

                    guard let httpUrlResponse  = urlResponse as? HTTPURLResponse else { return }

                    self.beforeInsertOrUpdateObjects(from: representationOrArrayOfRepresentations,
                                                     of: fetchRequest,
                                                     from: httpUrlResponse,
                                                     with: childContext,
                                                     with: self.backingManagedObjectContext,
                                                     with: self.backingObjectIdByObjectId)

                    _ = try? self.insertOrUpdateObjects(from: representationOrArrayOfRepresentations, of: fetchRequest?.entity, from: httpUrlResponse, with: childContext) {
                        objects, backingObjects in
                        childContext.performAndWait {
                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                        }
                        let backingContext = self.backingManagedObjectContext
                        backingContext.performAndWait {
                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                        }

                        self.updateContextObjects(childContext)

                        self.notify(context: context, about: operation, error: nil, for: fetchRequest, fetchedObjectIds: objects.map{$0.objectID}, didFetch: true)
                    }
                }

            })
            notify(context: context, about: operation, error: nil, for: fetchRequest, fetchedObjectIds: nil, didFetch: false)
            operation?.resume()
        }
        let backingContext = backingManagedObjectContext
        let backingFetchRequest = fetchRequest?.copy() as? NSFetchRequest<NSFetchRequestResult>
        if let fetchRequest = fetchRequest,
            let fetchRequestEntity = fetchRequest.entity,
            let entityName = fetchRequest.entityName ?? fetchRequestEntity.name {
            backingFetchRequest?.entity = NSEntityDescription.entity(forEntityName: entityName, in: backingContext)
            switch fetchRequest.resultType {
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
                        let objectId = self.objectId(for: fetchRequestEntity, with: resourceIdentifier),
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
                                let objectId = self.objectId(for: fetchRequestEntity, with: resourceId) else {
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
            case .dictionaryResultType, .countResultType:
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
        if let error = error {
            throw error
        }
        return nil
    }

    /**

     */
    open func getResourceIdentifierInsertRequest(_ context: NSManagedObjectContext?,
                                                 insertedObject: NSManagedObject) -> String? {

        var UUID = CFUUIDCreate(kCFAllocatorDefault)
        let resourceIdentifier = CFUUIDCreateString(kCFAllocatorDefault, UUID)
        UUID = nil

        return resourceIdentifier as! String
    }

    private func assignPermanentID(context: NSManagedObjectContext?, insertedObject: NSManagedObject) {
        context?.performAndWait {
            insertedObject.willChangeValue(forKey: "objectID")
            _ = try? context?.obtainPermanentIDs(for: [insertedObject])
            insertedObject.didChangeValue(forKey: "objectID")
            context?.refresh(insertedObject, mergeChanges: false)
        }
    }

    open func executeSaveChangesRequest(_ saveChangesRequest: NSSaveChangesRequest?, with context: NSManagedObjectContext?) throws -> Any? {
        let operation_dispatch_group = DispatchGroup()
        var operations = [URLSessionTask]()
        var operationErrors = [NSManagedObjectID: NSError]()
        let backingContext = backingManagedObjectContext

        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = context
        if #available(iOS 10.0, *) {
            childContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        } else {
            childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }

        for insertedObject in saveChangesRequest?.insertedObjects ?? [] {

            if let entityName = insertedObject.entity.name {
                backingContext.performAndWait {
                    let resourceIdentifier = getResourceIdentifierInsertRequest(context,
                                                                                insertedObject: insertedObject)
                    let backingObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backingContext)
                    _ = try? backingObject.managedObjectContext?.obtainPermanentIDs(for: [backingObject])
                    backingObject.setValue(resourceIdentifier, forKey: kAFIncrementalStoreResourceIdentifierAttributeName)
                    update(backingObject, withAttributeAndRelationshipValuesFrom: insertedObject)
                    guard backingContext.hasChanges else {
                        return
                    }
                    do {
                        try backingContext.save()
                    }catch let e {
                        print("\(e)")
                    }
                }
            }

            guard let request = httpClient?.request?(forInsertedObject: insertedObject) else {
                assignPermanentID(context: context, insertedObject: insertedObject)
                continue
            }

            operation_dispatch_group.enter()
            let operation = httpClient?.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in

                guard error == nil else {

                    self.assignPermanentID(context: context, insertedObject: insertedObject)

                    operationErrors[insertedObject.objectID] = error! as NSError

                    // Reset destination objects to prevent dangling relationships
                    for relationship in insertedObject.entity.relationshipsByName.map({$1}) {
                        if relationship.inverseRelationship == nil {
                            continue
                        }
                        let destinationObjects: [NSManagedObject]
                        if relationship.isToMany {
                            destinationObjects = (insertedObject.value(forKey: relationship.name) as? [NSManagedObject]) ?? []
                        } else if let destinationObject = insertedObject.value(forKey: relationship.name) as? NSManagedObject {
                            destinationObjects = [destinationObject]
                        } else {
                            destinationObjects = []
                        }
                        for destinationObject in destinationObjects {
                            context?.performAndWait {
                                context?.refresh(destinationObject, mergeChanges: false)
                            }
                        }
                    }

                    operation_dispatch_group.leave()
                    return

                }

                let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: insertedObject.entity, fromResponseObject: responseObject)
                guard let representation = representationOrArrayOfRepresentations as? [String: Any],
                    let _ = insertedObject.entity.name else {
                        return
                }

                guard let httpUrlResponse  = urlResponse as? HTTPURLResponse else {
                    return
                }

                let resourceIdentifier = self.httpClient?.resourceIdentifier(forRepresentation: representation, ofEntity: insertedObject.entity, from: httpUrlResponse)
                insertedObject.af_resourceIdentifier = resourceIdentifier

                _ = try? self.insertOrUpdateObjects(from: representationOrArrayOfRepresentations, of: insertedObject.entity, from: httpUrlResponse, with: childContext) {
                    objects, backingObjects in

                    childContext.performAndWait {
                        AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                    }

                    let backingContext = self.backingManagedObjectContext
                    backingContext.performAndWait {
                        AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                    }

                    self.assignPermanentID(context: context, insertedObject: insertedObject)

                    operation_dispatch_group.leave()

                }
            })

            if let operation = operation {
                operations.append(operation)
            }
        }

        for updatedObject in saveChangesRequest?.updatedObjects ?? [] {
            let backingObjectId = objectIdForBackingObject(for: updatedObject.entity, with: AFResourceIdentifier(from: referenceObject(for: updatedObject.objectID)))

            backingContext.performAndWait {
                let backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!)
                self.update(backingObject, withAttributeAndRelationshipValuesFrom: updatedObject)
                guard backingContext.hasChanges else {
                    return
                }
                do {
                    try backingContext.save()
                }catch let e {
                    print("\(e)")
                }
            }

            guard let request = httpClient?.request?(forUpdatedObject: updatedObject) else { continue }

            operation_dispatch_group.enter()
            let operation = self.httpClient?.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in

                guard error == nil else {
                    operationErrors[updatedObject.objectID] = error! as NSError
                    context?.performAndWait {
                        context?.refresh(updatedObject, mergeChanges: false)
                    }
                    operation_dispatch_group.leave()
                    return

                }

                let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: updatedObject.entity, fromResponseObject: responseObject)
                if let representation = representationOrArrayOfRepresentations as? [String: Any] {

                    guard let httpUrlResponse  = urlResponse as? HTTPURLResponse else { return }

                    _ = try? self.insertOrUpdateObjects(from: representationOrArrayOfRepresentations, of: updatedObject.entity, from: httpUrlResponse, with: childContext) {
                        objects, backingObjects in

                        childContext.performAndWait {
                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                        }

                        let backingContext = self.backingManagedObjectContext
                        backingContext.performAndWait {
                            AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                        }

                        self.updateContextObjects(childContext)

                        operation_dispatch_group.leave()

                    }
                }
            })

            if let operation = operation {
                operations.append(operation)
            }

        }
        for deletedObject in saveChangesRequest?.deletedObjects ?? [] {
            let backingObjectId = self.objectIdForBackingObject(for: deletedObject.entity, with: AFResourceIdentifier(from: referenceObject(for: deletedObject.objectID)))

            backingContext.performAndWait {
                if let backingObjectId = backingObjectId,
                    let backingObject = try? backingContext.existingObject(with: backingObjectId) {
                    backingContext.delete(backingObject)
                    self.backingObjectIdByObjectId.removeObject(forKey: deletedObject.objectID)
                    guard backingContext.hasChanges else {
                        return
                    }
                    do {
                        try backingContext.save()
                    }catch let e {
                        print("\(e)")
                    }
                }
            }

            guard let request = self.httpClient?.request?(forDeletedObject: deletedObject) else { continue }

            operation_dispatch_group.enter()
            let operation = self.httpClient?.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in
                guard error == nil else {
                    operationErrors[deletedObject.objectID] = error! as NSError
                    operation_dispatch_group.leave()
                    return
                }

                backingContext.performAndWait {
                    if let backingObjectId = backingObjectId,
                        let backingObject = try? backingContext.existingObject(with: backingObjectId) {
                        backingContext.delete(backingObject)
                        self.backingObjectIdByObjectId.removeObject(forKey: deletedObject.objectID)
                        guard backingContext.hasChanges else {
                            return
                        }
                        do {
                            try backingContext.save()
                        }catch let e {
                            print("\(e)")
                        }
                    }
                }
                operation_dispatch_group.leave()
            })
            if let operation = operation {
                operations.append(operation)
            }
        }
        // NSManagedObjectContext removes object references from an NSSaveChangesRequest as each object is saved, so create a copy of the original in order to send useful information in AFIncrementalStoreContextDidSaveRemoteValues notification.
        let saveChangesRequestCopy = NSSaveChangesRequest(inserted: saveChangesRequest?.insertedObjects, updated: saveChangesRequest?.updatedObjects, deleted: saveChangesRequest?.deletedObjects, locked: saveChangesRequest?.lockedObjects)
        notify(context: context, about: operations, errors: nil, for: saveChangesRequestCopy, didSave: false)

        operations.forEach { (operation) in
            operation.resume()
        }

        operation_dispatch_group.notify(queue: .main) {
            self.notify(context: context, about: operations, errors: operationErrors, for: saveChangesRequestCopy, didSave: true)
        }
        return [Any]()
    }

    // MARK: -

    private func notify(context: NSManagedObjectContext?, about operation: URLSessionTask?, error: NSError?, for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, fetchedObjectIds: [NSManagedObjectID]?, didFetch: Bool) {
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
        if didFetch {
            if let fetchedObjectIds = fetchedObjectIds {
                userInfo[AFIncrementalStoreFetchedObjectIDsKey] = fetchedObjectIds
            }
            if let error = error {
                userInfo[AFIncrementalStoreRequestErrorsKey] = [error]
            }
        }
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext?, about operations: [URLSessionTask]?, errors: [NSManagedObjectID: NSError]?, for request: NSSaveChangesRequest?, didSave: Bool) {
        guard let context = context,
            let operations = operations,
            let request = request else {
                return
        }
        let name: Notification.Name = didSave ? .AFIncrementalStoreContextDidSaveRemoteValues : .AFIncrementalStoreContextWillSaveRemoteValues
        var userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: operations,
            AFIncrementalStorePersistentStoreRequestKey: request
        ]
        if didSave,
            let errors = errors {
            userInfo[AFIncrementalStoreRequestErrorsKey] = errors
        }
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext?, about operation: URLSessionTask?, error: NSError?, forNewValuesForObjectWithId objectId: NSManagedObjectID?, didFetch: Bool) {
        guard let context = context,
            let operation = operation,
            let objectId = objectId else {
                return
        }
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchNewValuesForObject : .AFIncrementalStoreContextWillFetchNewValuesForObject
        var userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStoreFaultingObjectIDKey: objectId
        ]
        if didFetch,
            let error = error {
            userInfo[AFIncrementalStoreRequestErrorsKey] = [error]

        }
        NotificationCenter.default.post(name: name, object: context, userInfo: userInfo)
    }

    private func notify(context: NSManagedObjectContext?, about operation: URLSessionTask?, error: NSError?, forNewValuesFor relationship: NSRelationshipDescription?, forObjectWithId objectId: NSManagedObjectID?, didFetch: Bool) {
        guard let context = context,
            let operation = operation,
            let relationship = relationship,
            let objectId = objectId else {
                return
        }
        let name: Notification.Name = didFetch ? .AFIncrementalStoreContextDidFetchNewValuesForRelationship : .AFIncrementalStoreContextWillFetchNewValuesForRelationship
        var userInfo: [AnyHashable: Any] = [
            AFIncrementalStoreRequestOperationsKey: [operation],
            AFIncrementalStoreFaultingObjectIDKey: objectId,
            AFIncrementalStoreFaultingRelationshipKey: relationship
        ]
        if didFetch,
            let error = error {
            userInfo[AFIncrementalStoreRequestErrorsKey] = [error]
        }
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

    public func objectId(for entity: NSEntityDescription, with resourceIdentifier: String?) -> NSManagedObjectID? {
        guard let entityName = entity.name,
            let resourceIdentifier = resourceIdentifier else {
                return nil
        }
        return registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName]?[resourceIdentifier] as? NSManagedObjectID ?? newObjectID(for: entity, referenceObject: resourceIdentifier)
    }

    public func objectIdForBackingObject(for entity: NSEntityDescription, with resourceIdentifier: String?) -> NSManagedObjectID? {
        guard let entityName = entity.name,
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
                            let destinationEntity = relationship.destinationEntity,
                            let backingRelationshipObjectId = objectIdForBackingObject(for: destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipManagedObject.objectID))),
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
                            let destinationEntity = relationship.destinationEntity,
                            let backingRelationshipObjectId = objectIdForBackingObject(for: destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipManagedObject.objectID))),
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
                    let destinationEntity = relationship.destinationEntity,
                    let backingRelationshipObjectId = objectIdForBackingObject(for: destinationEntity, with: AFResourceIdentifier(from: referenceObject(for: relationshipValue.objectID))),
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
        guard let entity = entity else {
            return false
        }
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
                let entityName = entity.name else {
                    continue
            }
            var object: NSManagedObject?
            context.performAndWait {
                object = try? context.existingObject(with: objectId)
                object?.setValuesForKeys(attributes)
            }
            var backingObject: NSManagedObject?
            var backingObjectId: NSManagedObjectID?
            backingContext.performAndWait {
                backingObjectId = objectIdForBackingObject(for: entity, with: resourceIdentifier)
                if let backingObjectId = backingObjectId {
                    backingObject = try? backingContext.existingObject(with: backingObjectId)
                } else {
                    backingObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backingContext)
                    _ = try? backingObject?.managedObjectContext?.obtainPermanentIDs(for: [backingObject!])
                }
                backingObject?.setValue(resourceIdentifier, forKey: kAFIncrementalStoreResourceIdentifierAttributeName)
                backingObject?.setValue(lastModified, forKey: kAFIncrementalStoreLastModifiedAttributeName)
                backingObject?.setValuesForKeys(attributes)
            }
            if let object = object,
                backingObjectId == nil {
                context.performAndWait {
                    context.insert(object)
                }
            }
            let relationshipRepresentations = httpClient?.representationsForRelationships(fromRepresentation: representation, ofEntity: entity, from: response)
            for relationshipRepresentationItem in relationshipRepresentations ?? [:] {
                let relationship: NSRelationshipDescription! = entity.relationshipsByName[relationshipRepresentationItem.key]
                if relationship == nil || (relationship!.isOptional && relationshipRepresentationItem.value is NSNull) {
                    continue
                }
                if relationshipRepresentationItem.value is NSNull || (relationshipRepresentationItem.value as? NSObject)?.value(forKey: "count") as? Int == 0 {
                    context.performAndWait {
                        object?.setValue(nil, forKey: relationshipRepresentationItem.key)
                    }
                    backingContext.performAndWait {
                        backingObject?.setValue(nil, forKey: relationshipRepresentationItem.key)
                    }
                    continue
                }
                do {
                    _ = try insertOrUpdateObjects(from: relationshipRepresentationItem.value, of: relationship.destinationEntity, from: response, with: context) {
                        managedObjects, backingObjects in
                        if relationship?.isToMany == true {
                            if relationship?.isOrdered == true {
                                context.performAndWait {
                                    object?.setValue(managedObjects, forKey: relationship!.name)
                                }
                                backingContext.performAndWait {
                                    backingObject?.setValue(backingObjects, forKey: relationship!.name)
                                }
                            } else {
                                context.performAndWait {
                                    object?.setValue(Set<NSManagedObject>(managedObjects), forKey: relationship!.name)
                                }
                                backingContext.performAndWait {
                                    backingObject?.setValue(Set<NSManagedObject>(backingObjects), forKey: relationship!.name)
                                }
                            }
                        } else {
                            context.performAndWait {
                                object?.setValue(managedObjects.last, forKey: relationship!.name)
                            }
                            backingContext.performAndWait {
                                backingObject?.setValue(backingObjects.last, forKey: relationship!.name)
                            }
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

    // MARK: - Overrides

    @objc open override func loadMetadata() throws {
        guard backingObjectIdByObjectId == nil else {
            throw NSError()
        }
        guard let model = persistentStoreCoordinator?.managedObjectModel.copy() as? NSManagedObjectModel else {
            return
        }
        self.metadata = [
            NSStoreUUIDKey: ProcessInfo.processInfo.globallyUniqueString,
            NSStoreTypeKey: NSStringFromClass(classForCoder)
        ]
        backingObjectIdByObjectId = NSCache()
        registeredObjectIdsByEntityNameAndNestedResourceIdentifier = [:]
        var mutatedEntities = [NSEntityDescription]()
        for entity in model.entities {
            // Don't add properties for sub-entities, as they already exist in the super-entity
            if let _ = entity.superentity {
                mutatedEntities.append(entity)
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
            mutatedEntities.append(entity)
        }
        model.entities = mutatedEntities
        backingPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    }

    @objc open override func obtainPermanentIDs(for array: [NSManagedObject]) throws -> [NSManagedObjectID] {
        var permanentIds = [NSManagedObjectID]()
        for object in array {
            let objectId = object.objectID
            guard objectId.isTemporaryID,
                let resourceIdentifier = object.af_resourceIdentifier else {
                    permanentIds.append(objectId)
                    continue
            }
            let permanentId = newObjectID(for: object.entity, referenceObject: resourceIdentifier)
            permanentIds.append(permanentId)
        }
        return permanentIds
    }

    @objc open override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        var toReturn: Any?
        switch request.requestType {
        case .fetchRequestType:
            do {
                toReturn = try executeFetchRequest(request as? NSFetchRequest<NSFetchRequestResult>, with: context)
            } catch let error as NSError {
                throw error
            }
            return toReturn ?? [Any]()
        case .saveRequestType:
            do {
                toReturn = try executeSaveChangesRequest(request as? NSSaveChangesRequest, with: context)
            } catch let error as NSError {
                throw error
            }
            return toReturn ?? [Any]()
        default:
            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: NSLocalizedString("Unsupported NSFetchRequestResultType, \(request.requestType)", comment: "")]
            throw NSError(domain: "AFNetworkingErrorDomain", code: 0, userInfo: userInfo)
        }
    }

    @objc open override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        var error: NSError?
        let entityName = objectID.entity.name ?? ""
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        let attributes = objectID.entity.attributesByName.map({$1})
        let intransientAttributes = attributes.filter{!$0.isTransient}
        fetchRequest.propertiesToFetch = intransientAttributes.map{$0.name}
        fetchRequest.propertiesToFetch!.append(kAFIncrementalStoreLastModifiedAttributeName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", kAFIncrementalStoreResourceIdentifierAttributeName, AFResourceIdentifier(from: referenceObject(for: objectID)))
        var results = [[String: Any]]()
        let backingContext = backingManagedObjectContext
        backingContext.performAndWait {
            do {
                results = try backingContext.fetch(fetchRequest).map{$0 as! [String: Any]}
            } catch let e as NSError {
                error = e
            }
        }
        var attributeValues = results.last ?? [:]
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: attributeValues, version: 1)
        guard httpClient?.shouldFetchRemoteAttributeValues?(forObjectWith: objectID, in: context) == true,
            !attributeValues.isEmpty,
            var request = httpClient?.request(withMethod: "GET", pathForObjectWith: objectID, with: context) else {
                if let error = error {
                    throw error
                }
                return node
        }
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = context
        if #available(iOS 10.0, *) {
            childContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        } else {
            childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        if let lastModified = attributeValues[kAFIncrementalStoreLastModifiedAttributeName] as? String {
            request.setValue(lastModified, forHTTPHeaderField: "Last-Modified")
        }
        var operation: URLSessionTask?
        operation = httpClient?.dataTask(with: request, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in
            guard error == nil else {

                self.notify(context: context, about: operation, error: error as NSError?, forNewValuesForObjectWithId: objectID, didFetch: true)

                return
            }

            if let representation = responseObject as? [AnyHashable: Any] {

                guard let httpUrlResponse  = urlResponse as? HTTPURLResponse else { return }

                childContext.performAndWait {
                    let object = try? childContext.existingObject(with: objectID)

                    if let attributes = self.httpClient?.attributes(forRepresentation: representation, ofEntity: object?.entity, from: httpUrlResponse) {
                        attributeValues.merge(attributes){$1}
                    }
                    _ = attributeValues.removeValue(forKey: kAFIncrementalStoreLastModifiedAttributeName)
                    object?.setValuesForKeys(attributeValues)
                }
                let backingContext = self.backingManagedObjectContext
                backingContext.performAndWait {
                    if let backingObjectId = self.objectIdForBackingObject(for: objectID.entity, with: AFResourceIdentifier(from: self.referenceObject(for: objectID))) {
                        let backingObject = try? backingContext.existingObject(with: backingObjectId)
                        backingObject?.setValuesForKeys(attributeValues)
                        if let lastModified = httpUrlResponse.allHeaderFields["Last-Modified"] {
                            backingObject?.setValue(lastModified, forKey: kAFIncrementalStoreLastModifiedAttributeName)
                        }
                    }
                }
                childContext.performAndWait {
                    AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                }
                backingContext.performAndWait {
                    AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                }
            }
            self.notify(context: context, about: operation, error: nil, forNewValuesForObjectWithId: objectID, didFetch: true)
        })

        notify(context: context, about: operation, error: nil, forNewValuesForObjectWithId: objectID, didFetch: false)
        operation?.resume()

        if let error = error {
            throw error
        }
        return node
    }

    @objc open override func newValue(forRelationship relationship: NSRelationshipDescription, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext?) throws -> Any {
        var objectExists = false
        var existingObjectHasChanges = false
        context?.performAndWait {
            let object = try? context?.existingObject(with: objectID)
            objectExists = object != nil
            existingObjectHasChanges = object??.hasChanges == true
        }
        let backingContext = self.backingManagedObjectContext
        if objectExists,
            !existingObjectHasChanges,
            let context = context,
            httpClient?.shouldFetchRemoteValues?(forRelationship: relationship, forObjectWith: objectID, in: context) == true {
            let request = httpClient?.request(withMethod: "GET", pathForRelationship: relationship, forObjectWith: objectID, with: context)
            let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            childContext.parent = context
            if #available(iOS 10.0, *) {
                childContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
            } else {
                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
            var operation: URLSessionTask?
            operation = httpClient?.dataTask(with: request!, uploadProgress: nil, downloadProgress: nil, completionHandler: { (urlResponse, responseObject, error) in
                guard error == nil else {
                    self.notify(context: context, about: operation, error: error as NSError?, forNewValuesFor: relationship, forObjectWithId: objectID, didFetch: true)
                    return
                }

                let representationOrArrayOfRepresentations = self.httpClient?.representationOrArrayOfRepresentations(ofEntity: relationship.destinationEntity, fromResponseObject: responseObject)

                guard let httpUrlResponse  = urlResponse as? HTTPURLResponse else { return }

                _ = try? self.insertOrUpdateObjects(from: representationOrArrayOfRepresentations, of: relationship.destinationEntity, from: httpUrlResponse, with: childContext) {
                    objects, backingObjects in
                    var object: NSManagedObject?
                    childContext.performAndWait {
                        object = childContext.object(with: objectID)
                    }
                    var backingObject: NSManagedObject?
                    backingContext.performAndWait {
                        let backingObjectId = self.objectIdForBackingObject(for: objectID.entity, with: AFResourceIdentifier(from: self.referenceObject(for: objectID)))
                        backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!)
                    }
                    if relationship.isToMany {
                        if relationship.isOrdered {
                            childContext.performAndWait {
                                object?.setValue(objects, forKey: relationship.name)
                            }
                            backingContext.performAndWait {
                                backingObject?.setValue(backingObjects, forKey: relationship.name)
                            }
                        } else {
                            childContext.performAndWait {
                                object?.setValue(Set<NSManagedObject>(objects), forKey: relationship.name)
                            }
                            backingContext.performAndWait {
                                backingObject?.setValue(Set<NSManagedObject>(backingObjects), forKey: relationship.name)
                            }
                        }
                    } else {
                        childContext.performAndWait {
                            object?.setValue(objects.last, forKey: relationship.name)
                        }
                        backingContext.performAndWait {
                            backingObject?.setValue(backingObjects.last, forKey: relationship.name)
                        }
                    }
                    childContext.performAndWait {
                        AFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext)
                    }
                    backingContext.performAndWait {
                        AFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext)
                    }
                }

                self.notify(context: context, about: operation, error: nil, forNewValuesFor: relationship, forObjectWithId: objectID, didFetch: true)
            })

            notify(context: context, about: operation, error: nil, forNewValuesFor: relationship, forObjectWithId: objectID, didFetch: false)
            operation?.resume()
        }
        var toReturn: Any!
        backingContext.performAndWait {
            let backingObjectId = self.objectIdForBackingObject(for: objectID.entity, with: AFResourceIdentifier(from: self.referenceObject(for: objectID)))
            if let destinationEntity = relationship.destinationEntity {
                if let backingObject = backingObjectId == nil ? nil : try? backingContext.existingObject(with: backingObjectId!) {
                    let backingRelationshipObject = backingObject.value(forKey: relationship.name)
                    if relationship.isToMany {
                        var objectIds = [NSManagedObjectID]()
                        for destinationObject in backingRelationshipObject as? [NSManagedObject] ?? [NSManagedObject](backingRelationshipObject as! Set<NSManagedObject>) {
                            guard let resourceIdentifier = destinationObject.value(forKey: kAFIncrementalStoreResourceIdentifierAttributeName) as? String,
                                let objectId = self.objectId(for: destinationEntity, with: resourceIdentifier) else {
                                    continue
                            }
                            objectIds.append(objectId)
                        }
                        toReturn = objectIds
                    } else {
                        let resourceIdentifier = (backingRelationshipObject as? NSManagedObject)?.value(forKey: kAFIncrementalStoreResourceIdentifierAttributeName) as? String
                        let objectId = self.objectIdForBackingObject(for: destinationEntity, with: resourceIdentifier)
                        toReturn = objectId ?? NSNull()
                    }
                } else {
                    toReturn = relationship.isToMany ? [Any]() : NSNull()
                }
            }
        }
        return toReturn
    }

    @objc open override func managedObjectContextDidRegisterObjects(with objectIDs: [NSManagedObjectID]) {
        super.managedObjectContextDidRegisterObjects(with: objectIDs)
        for objectId in objectIDs {
            guard let entityName = objectId.entity.name else {
                continue
            }
            var objectIdsByResourceIdentifier = registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName] ?? [String: Any]()
            let referenceObject = self.referenceObject(for: objectId)
            objectIdsByResourceIdentifier[AFResourceIdentifier(from: referenceObject)] = objectId
            registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName] = objectIdsByResourceIdentifier
        }
    }

    @objc open override func managedObjectContextDidUnregisterObjects(with objectIDs: [NSManagedObjectID]) {
        super.managedObjectContextDidUnregisterObjects(with: objectIDs)
        for objectId in objectIDs {
            guard let entityName = objectId.entity.name,
                var nestedDictionary = registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName] else {
                    continue
            }
            nestedDictionary.removeValue(forKey: AFResourceIdentifier(from: objectId))
            registeredObjectIdsByEntityNameAndNestedResourceIdentifier[entityName] = nestedDictionary
        }
    }

}
