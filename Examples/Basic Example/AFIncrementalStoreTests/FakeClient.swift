//
//  FakeClient.swift
//  AFIncrementalStoreTests
//
//  Created by Ignazio Altomare on 29/01/2018.
//

import UIKit
import AFNetworking
import CoreData

class FakeClient: AFHTTPSessionManager, AFIncrementalStoreHttpClient {
    
    var urlRequest = URLRequest(url: URL(string: "http://localhost")!)

    init() {
        super.init(baseURL: URL(string: "http://localhost"), sessionConfiguration: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(baseURL url: URL?, sessionConfiguration configuration: URLSessionConfiguration?) {
        super.init(baseURL: url, sessionConfiguration: configuration)
    }
    
    func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
        return nil
    }
    
    func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any] {
        return [:]
    }
    
    func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
        return nil
    }
    
    func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
        return nil
    }
    
    func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
        return nil
    }
    
    func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest? {
        return urlRequest
    }
    
    func request(withMethod method: String, pathForRelationship relationship: NSRelationshipDescription?, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest? {
        return urlRequest
    }
    
    
}
