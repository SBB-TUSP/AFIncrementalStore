//
//  FakeClient.swift
//  AFIncrementalStoreTests
//
//  Created by Ignazio Altomare on 29/01/2018.
//

import UIKit
import AFNetworking

class FakeClient: AFHTTPSessionManager, AFIncrementalStoreHTTPClient {
    

    init() {
        super.init(baseURL: URL(string: "http://lochalhost"), sessionConfiguration: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(baseURL url: URL?, sessionConfiguration configuration: URLSessionConfiguration?) {
        super.init(baseURL: url, sessionConfiguration: configuration)
    }

    func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
        return nil
    }

    func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String? {
        return nil
    }

    func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]? {
        return nil
    }

    func request(withMethod method: String!, pathForObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest? {
        return nil
    }

    func request(withMethod method: String!, pathForRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest? {
        return nil
    }

    func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest? {
        return nil
    }

    func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
        return nil
    }


}
