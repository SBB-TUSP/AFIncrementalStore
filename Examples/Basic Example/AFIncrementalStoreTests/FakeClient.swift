//
//  FakeClient.swift
//  AFIncrementalStoreTests
//
//  Created by Ignazio Altomare on 29/01/2018.
//

import UIKit

class FakeClient: AFHTTPClient, AFIncrementalStoreHttpClient {

    /// a simple value of URLRequest type
    var urlRequest = URLRequest(url: URL(string: "http://localhost")!)

    override init() {
        super.init(baseURL: URL(string: "http://lochalhost")!)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init!(baseURL url: URL!) {
        super.init(baseURL: url)
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

    func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest {
        return urlRequest
    }

    func request(withMethod method: String, pathForRelationship relationship: NSRelationshipDescription?, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest {
        return urlRequest
    }


}
