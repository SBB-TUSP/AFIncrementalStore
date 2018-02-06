//
//  SongAPIClient.swift
//  Songs
//
//  Created by Ignazio Altomare on 01/02/2018.
//

import UIKit

var songAPIClient: SongAPIClient {
    return .sharedInstance
}

@objc
class SongAPIClient: AFRESTClient {

    // MARK: - Singleton

    @objc
    static let sharedInstance = SongAPIClient(baseURL: URL(string:"http://afincrementalstore-example-api.herokuapp.com"))!

    override init!(baseURL url: URL!) {
        super.init(baseURL: url)

        self.registerHTTPOperationClass(AFJSONRequestOperation.self)
        self.setDefaultHeader("application/json", value: "Accept")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Methods

    override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [AnyHashable : Any]? {
        guard let superAttributes = super.attributes(forRepresentation: representation, ofEntity: entity, from: response) else { return nil }
        let mutablePropertyValues = NSMutableDictionary(dictionary: superAttributes)
        if entity?.name == "Artist" {
            let description = representation?["description"]
            mutablePropertyValues.setValue(description, forKey: "artistDescription")
        }
        return mutablePropertyValues as? [AnyHashable : Any]
    }

    func shouldFetchRemoteAttributeValuesForObject(with objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
        return objectID.entity.name == "Artist"
    }

    override func shouldFetchRemoteValues(forRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
        return objectID.entity.name == "Artist"
    }

}
