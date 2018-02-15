//
//  AFRESTClientSwift.swift
//  
//
//  Created by Ignazio Altomare on 31/01/2018.
//

import CoreData
import Foundation
import TransformerKit
import AFNetworking
import InflectorKit

@objc
class AFRESTClient: AFHTTPSessionManager {

    var paginator: AFPaginator?

    public var inflector: TTTStringInflector{
        return TTTStringInflector.default()
    }

    override init(baseURL url: URL?, sessionConfiguration configuration: URLSessionConfiguration?) {
        super.init(baseURL: url, sessionConfiguration: configuration)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - path

    func path(forEntity entity: NSEntityDescription?) -> String {
        return inflector.pluralize(entity?.name?.lowercased())
    }

    func path(for object: NSManagedObject) -> String {
        let rootPath = path(forEntity: object.entity)
        guard let persistentStore = object.objectID.persistentStore as? NSIncrementalStore else {
            return rootPath
        }
        let resourceIdentifier = AFResourceIdentifier(from: persistentStore.referenceObject(for: object.objectID))
        return (rootPath as NSString).appendingPathComponent(resourceIdentifier)
    }

    func path(forRelationship relationship: NSRelationshipDescription?, for object:NSManagedObject) -> String {
        let pathForObject = path(for: object)
        guard let name = relationship?.name else { return pathForObject }
        return (pathForObject as NSString).appendingPathComponent(name)
    }

}

//MARK: -

extension AFRESTClient: AFIncrementalStoreHttpClient {

    func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {

        if let responseArray = responseObject as? Array<Any> {
            return responseArray
        }

        else if let responseDictionary = responseObject as? Dictionary<AnyHashable, Any> {
            guard let name = entity?.name else { return responseObject }
            var nameFixed = ""
            if #available(iOS 9.0, *) {
                nameFixed = name.localizedLowercase
            } else {
                nameFixed = name.lowercased(with: Locale.current)
            }
            if let value = responseDictionary[nameFixed] as? Dictionary<AnyHashable, Any> {
                return value
            }

            if let value = responseDictionary[inflector.pluralize(nameFixed)] as? Array<Any> {
                return value
            }

            return responseDictionary

        }

        return responseObject
    }

    func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any] {
        var mutableRelationshipRepresentations: [String : Any] = [:]

        guard let relationshipsByName = entity?.relationshipsByName else { return mutableRelationshipRepresentations }

        for name in relationshipsByName.keys {
            if let value = representation[name] {
                if relationshipsByName[name]!.isToMany {

                    var arrayOfRelationshipRepresentations: Array<Any>

                    if let valueArray = value as? Array<Any> {
                        arrayOfRelationshipRepresentations = valueArray
                    }else {
                        arrayOfRelationshipRepresentations = [value]
                    }

                    mutableRelationshipRepresentations[name] = arrayOfRelationshipRepresentations

                } else {
                    mutableRelationshipRepresentations[name] = value
                }
            }
        }

        return mutableRelationshipRepresentations
    }

    func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
        let candidateKeys = ["id", "_id", "identifier", "url", "URL"]

        if let key = representation.keys.filter(
            { (keyRepresentation) -> Bool in

                return candidateKeys.contains(keyRepresentation as! String)

        }).first {
            guard let value = representation[key] as? NSObject else {return nil }
            return value.description
        }
        return nil
    }

    func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {

        guard let tempRepresentation = representation else { return nil }

        let mutableAttributes = NSMutableDictionary(dictionary: tempRepresentation)
        let mutableKeys = NSMutableSet(array: Array(tempRepresentation.keys))
        guard let attributesByName = entity?.attributesByName else { return nil }
        mutableKeys.minus(Set(attributesByName.keys))
        mutableAttributes.removeObjects(forKeys: mutableKeys.allObjects)

        var keysWithNestedValue: [Any] = []
        for key in mutableAttributes.allKeys {
            let obj = mutableAttributes[key]

            if (obj is Array<Any> || obj is Dictionary<AnyHashable,Any>) {
                keysWithNestedValue.append(key)
            }
        }

        for key in attributesByName.keys {
            let obj = attributesByName[key]
            if obj?.attributeType == .dateAttributeType {
                if let value = mutableAttributes.value(forKey: key), value is String {
                    mutableAttributes.setValue(ValueTransformer(forName: NSValueTransformerName(rawValue: TTTISO8601DateTransformerName))?.reverseTransformedValue(value), forKey: key)
                }
            }
        }

        return mutableAttributes as? [String : Any]
    }

    private func URLStringWithBase(endpoint: String) -> String? {
        return URL(string: endpoint, relativeTo: baseURL)?.absoluteString
    }
    

    func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
        guard let fetchRequest = fetchRequest,
            let _ = context else {
                return nil
        }
        let mutableParameters = NSMutableDictionary()
        if paginator != nil {
            mutableParameters.addEntries(from: (paginator?.parameters(for: fetchRequest))!)
        }
        guard let entity = fetchRequest.entity else { return nil }
        guard let urlString = URLStringWithBase(endpoint: path(forEntity: entity)) else { return nil }
        return  requestSerializer.request(withMethod: "GET", urlString: urlString, parameters: mutableParameters.count == 0 ? nil : mutableParameters as? [AnyHashable : Any], error: nil) as URLRequest
    }

    func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest? {
        let object = context.object(with: objectID)
        guard let urlString = URLStringWithBase(endpoint: path(for: object)) else { return nil }
        return requestSerializer.request(withMethod: method, urlString: urlString, parameters: nil, error: nil) as URLRequest
    }

    func request(withMethod method: String, pathForRelationship relationship: NSRelationshipDescription?, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest? {
        let object = context.object(with: objectID)
        guard let urlString = URLStringWithBase(endpoint: path(forRelationship: relationship, for: object)) else { return nil }
        return requestSerializer.request(withMethod: method, urlString: urlString, parameters: nil, error: nil) as URLRequest
    }

    func shouldFetchRemoteValues(forRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
        return relationship.isToMany || relationship.inverseRelationship == nil
    }

    //MARK: - write methods


    func representation(ofAttributes attributes: [AnyHashable : Any]! = [:], of managedObject: NSManagedObject!) -> [AnyHashable : Any]! {
        let mutableAttributes: NSMutableDictionary = NSMutableDictionary(dictionary: attributes)

        for key in attributes.keys {
            let obj = attributes[key]

            if let date = obj as? Date {
                mutableAttributes.setObject(date.description , forKey: key as! NSCopying)
            }
        }

        return mutableAttributes as! [AnyHashable : Any]
    }

    func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
        let parameters = representation(ofAttributes: insertedObject.dictionaryWithValues(forKeys: Array(insertedObject.entity.attributesByName.keys)), of: insertedObject)
        guard let urlString = URLStringWithBase(endpoint: path(forEntity: insertedObject.entity)) else { return nil }
        return requestSerializer.request(withMethod: "POST", urlString: urlString, parameters: parameters, error: nil) as URLRequest
    }

    func request(forUpdatedObject updatedObject: NSManagedObject!) -> URLRequest? {
        
        var mutableChangedAttributeKeys = Set(updatedObject.changedValues().keys)
        mutableChangedAttributeKeys = mutableChangedAttributeKeys.intersection(Set(updatedObject.entity.attributesByName.keys))

        guard  mutableChangedAttributeKeys.count != 0 else { return nil }

        let updatedObjectDictionary = updatedObject.changedValues().filter { mutableChangedAttributeKeys.contains($0.key) }

        let parameters = representation(ofAttributes: updatedObjectDictionary, of: updatedObject)
        guard let urlString = URLStringWithBase(endpoint: path(for: updatedObject)) else { return nil }
        return requestSerializer.request(withMethod: "PUT", urlString: urlString, parameters: parameters, error: nil) as URLRequest
    }

    func request(forDeletedObject deletedObject: NSManagedObject!) -> URLRequest? {
        guard let urlString = URLStringWithBase(endpoint: path(for: deletedObject)) else { return nil }
        return requestSerializer.request(withMethod: "DELETE", urlString: urlString, parameters: nil, error: nil) as URLRequest
    }
}


//MARK: -


protocol AFPaginator {
    func parameters(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any]
}

//MARK: -

class AFLimitAndOffsetPaginator: AFPaginator{

    var limitParameter: String?
    var offsetParameter: String?

    init?(limitParameter: String?, offsetParameter: String?) {
        guard limitParameter != nil else { return nil }
        guard offsetParameter != nil else { return nil }

        self.limitParameter = limitParameter
        self.offsetParameter = offsetParameter
    }

    func parameters(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any] {

        let mutableParameters = NSMutableDictionary()

        if fetchRequest.fetchOffset > 0 {
            mutableParameters.setValue(String(format: "%u", fetchRequest.fetchOffset), forKey: offsetParameter!)
        }

        if fetchRequest.fetchLimit > 0 {
            mutableParameters.setValue(String(format: "%u", fetchRequest.fetchLimit), forKey: limitParameter!)
        }

        return mutableParameters as! [AnyHashable : Any]
    }


}

//MARK: -

class AFPageAndPerPagePaginator: AFPaginator{

    private let kAFPaginationDefaultPage = 1
    private let kAFPaginationDefaultPerPage = 20

    var pageParameter: String?
    var perPageParameter: String?

    init?(pageParameter: String?, perPageParameter: String?) {
        guard pageParameter != nil else { return nil }
        guard perPageParameter != nil else { return nil }

        self.pageParameter = pageParameter
        self.perPageParameter = perPageParameter
    }

    func parameters(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any] {
        let perPage = fetchRequest.fetchLimit == 0 ? kAFPaginationDefaultPerPage : fetchRequest.fetchLimit
        let page = fetchRequest.fetchOffset == 0 ? kAFPaginationDefaultPage : Int(floorf(Float(fetchRequest.fetchOffset) / Float(perPage)) + 1)

        let mutableParameters = NSMutableDictionary()
        mutableParameters.setValue(String(format: "%u", page), forKey: self.pageParameter!)
        mutableParameters.setValue(String(format: "%u", perPage), forKey: self.perPageParameter!)

        return mutableParameters as! [AnyHashable : Any]
    }

}

//MARK: -

class AFBlockPaginator: AFPaginator{

    var paginationParameters: ((NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any])?

    init?(_ paginationParameters:((NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any])?) {
        guard paginationParameters != nil else { return nil }

        self.paginationParameters = paginationParameters!
    }

    func parameters(for fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [AnyHashable:Any] {
        return paginationParameters!(fetchRequest)
    }

}
