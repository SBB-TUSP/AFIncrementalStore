//
//  AFRESTClientTests.swift
//  AFIncrementalStoreTests
//
//  Created by Ignazio Altomare on 26/01/2018.
//

import XCTest

fileprivate class FakeClientSubclass: FakeClient {

    func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
        return nil
    }

    func request(forDeletedObject deletedObject: NSManagedObject!) -> NSMutableURLRequest! {
        return nil
    }

    func request(forUpdatedObject updatedObject: NSManagedObject!) -> NSMutableURLRequest! {
        return nil
    }

}

class AFRESTClientTests: XCTestCase {

    private var baseURL: URL!

    private var modelUrl: URL!

    private var model: NSManagedObjectModel!

    private var coordinator: NSPersistentStoreCoordinator!

    private var store: AFIncrementalStore!

    private var errorCreatingBackingStore: Error!

    private var moc: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()

        baseURL = URL(string: "https://localhost")
        // Put setup code here. This method is called before the invocation of each test method in the class.

        guard let modelUrl = Bundle(for: AFIncrementalStoreTests.self).url(forResource: "IncrementalStoreExample", withExtension: "momd") else {
            return
        }
        self.modelUrl = modelUrl
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            return
        }
        self.model = model
        NSPersistentStoreCoordinator.registerStoreClass(AFIncrementalStore.self, forStoreType: "AFIncrementalStore")
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        do {
            store = try coordinator.addPersistentStore(ofType: "AFIncrementalStore", configurationName: nil, at: nil, options: nil) as? AFIncrementalStore

             try store?.backingPersistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        } catch let e {
            self.errorCreatingBackingStore = e
        }

        moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    fileprivate func createFakeClientHTTPandSaveContext(moc: NSManagedObjectContext){
        let fakeClient = FakeClientSubclass(baseURL: baseURL)
        store.httpClient = fakeClient
        moc.performAndWait {
            do{
                try moc.save()
            }catch let e {
                print(e)
            }
        }
    }
    
    func test_ShouldBeAbleToCreateRestClient() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")
    }

    func test_ShouldBeAbleToPathForEntity() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescription = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let result = instanceRestClient?.path(forEntity: entityDescription)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertEqual(result, "artists", "should not be equals")
    }

    func test_ShouldBeAbleToPathForObject_whenObjectIsNotStored() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)
        let result = instanceRestClient?.path(for: artist)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertEqual(result, "artists", "should not be equals")

    }

    func test_ShouldBeAbleToPathForObject_whenObjectIsStored() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)

        createFakeClientHTTPandSaveContext(moc: moc)

        let result = instanceRestClient?.path(for: artist)
        XCTAssertNotNil(result, "should not be nil")
        let resultComponents = result?.components(separatedBy: "/")
        XCTAssertEqual(resultComponents?.count, 2, "should not be equals")
        XCTAssertEqual(resultComponents![0], "artists", "should be artists")

    }


    func test_ShouldBeAbleToPathForRelationship_whenObjectIsStored() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let entityDescriptionSong = NSEntityDescription.entity(forEntityName: "Song", in: moc)
        let entityRelationshipDescription = entityDescriptionArtist?.relationships(forDestination: entityDescriptionSong!)[0]

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)

        createFakeClientHTTPandSaveContext(moc: moc)

        let result = instanceRestClient?.path(forRelationship: entityRelationshipDescription, for: artist)

        XCTAssertNotNil(result, "should not be nil")

        let resultComponents = result?.components(separatedBy: "/")
        XCTAssertEqual(resultComponents?.count, 3, "should not be equals")
        XCTAssertEqual(resultComponents![0], "artists", "should be artists")
        XCTAssertEqual(resultComponents![2], "songs", "should be songs")

    }

    func test_ShouldBeAbleToPathForRelationship_whenObjectIsNotStored() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let entityDescriptionSong = NSEntityDescription.entity(forEntityName: "Song", in: moc)
        let entityRelationshipDescription = entityDescriptionArtist?.relationships(forDestination: entityDescriptionSong!)[0]

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)

        let result = instanceRestClient?.path(forRelationship: entityRelationshipDescription, for: artist)

        XCTAssertNotNil(result, "should not be nil")

        let resultComponents = result?.components(separatedBy: "/")
        XCTAssertEqual(resultComponents?.count, 2, "should not be equals")
        XCTAssertEqual(resultComponents![0], "artists", "should be artists")
        XCTAssertEqual(resultComponents![1], "songs", "should be songs")

    }

    func test_ShouldBeAbleToRepresentationOrArrayOfRepresentationsOfEntity_whenResponseObjectIsAnArray() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            ["name": "test",
             "artistDescription":"test"
            ],
            ["name": "test2",
             "artistDescription":"test2"
            ]
        ]

        let result = instanceRestClient?.representationOrArrayOfRepresentations(ofEntity: entityDescriptionArtist, fromResponseObject:responseObject)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultArray = result as? [Any] else { XCTFail(); return }
        XCTAssertTrue(resultArray.count == 2, "should be an Array with 2 elements")
    }


    func test_ShouldBeAbleToRepresentationOrArrayOfRepresentationsOfEntity_whenResponseObjectIsADictionary() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            "name": "test",
            "artistDescription":"test"
        ]

        let result = instanceRestClient?.representationOrArrayOfRepresentations(ofEntity: entityDescriptionArtist, fromResponseObject:responseObject)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultDictionary = result as? [String: String] else { XCTFail(); return }
        XCTAssertTrue(resultDictionary["name"] == "test", "should be test")
        XCTAssertTrue(resultDictionary["artistDescription"] == "test", "should be test")
    }

    func test_ShouldBeAbleToRepresentationOrArrayOfRepresentationsOfEntity_whenResponseObjectIsADictionaryWithASubEntity() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            "artist":
            [
                "name": "test",
                "artistDescription":"test"
            ]
        ]

        let result = instanceRestClient?.representationOrArrayOfRepresentations(ofEntity: entityDescriptionArtist, fromResponseObject:responseObject)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultDictionary = result as? [String: String] else { XCTFail(); return }
        XCTAssertTrue(resultDictionary["name"] == "test", "should be test")
        XCTAssertTrue(resultDictionary["artistDescription"] == "test", "should be test")
    }

    func test_ShouldBeAbleToRepresentationOrArrayOfRepresentationsOfEntity_whenResponseObjectIsADictionaryWithASubArrayEntity() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            "artists":[
                    [
                        "name": "test",
                        "artistDescription":"test"
                    ],
                    [
                        "name": "test",
                        "artistDescription":"test"
                    ]
                ]
        ]

        let result = instanceRestClient?.representationOrArrayOfRepresentations(ofEntity: entityDescriptionArtist, fromResponseObject:responseObject)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultArray = result as? [Any] else { XCTFail(); return }
        XCTAssertTrue(resultArray.count == 2, "should be an array with 2 elements")
    }


    func test_ShouldBeAbleToRepresentationsForRelationshipsFromRepresentation_whenRepresentationRelationIsAnArray (){

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            "artists":[
                [
                    "name": "test",
                    "artistDescription":"test"
                ],
                [
                    "name": "test",
                    "artistDescription":"test"
                ]
            ],
            "songs": [
                [
                    "title": "test1"
                ],
                [
                    "title": "test2"
                ]
            ]
            ] as [String : Any]

        let result = instanceRestClient?.representationsForRelationships(fromRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultDictionary = result as? [String: Any] else { XCTFail(); return }
        XCTAssertNotNil(resultDictionary["songs"], "should not be nil")
        guard let subResultArray = resultDictionary["songs"] as? [Any] else { XCTFail(); return }
        XCTAssertTrue(subResultArray.count == 2, "should contains 2 elements")
    }


    func test_ShouldBeAbleToRepresentationsForRelationshipsFromRepresentation_whenRepresentationRelationIsADictionary (){

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let responseObject = [
            "artists":[
                [
                    "name": "test",
                    "artistDescription":"test"
                ],
                [
                    "name": "test",
                    "artistDescription":"test"
                ]
            ],
            "songs": [
                    "title": "test1"
                ]
            ] as [String : Any]

        let result = instanceRestClient?.representationsForRelationships(fromRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNotNil(result, "should not be nil")
        guard let resultDictionary = result as? [String: Any] else { XCTFail(); return }
        XCTAssertNotNil(resultDictionary["songs"], "should not be nil")
        guard let subResultArray = resultDictionary["songs"] as? [Any] else { XCTFail(); return }
        XCTAssertTrue(subResultArray.count == 1, "should contains 1 elements")
    }


    func test_ShouldBeAbleToGetResourceIdentifierForRepresentation_whenThereAreNotCandidatekey() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)

        let responseObject = [
                    "name": "test",
                    "artistDescription":"test"
            ] as [String : String]

        let result = instanceRestClient?.resourceIdentifier(forRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNil(result, "should be nil")

    }


    func test_ShouldBeAbleToGetResourceIdentifierForRepresentation_whenThereIsACandidatekey() {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)

        let responseObject = [
            "id":"idTest",
            "name": "test",
            "artistDescription":"test"
            ] as [String : String]

        let result = instanceRestClient?.resourceIdentifier(forRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNotNil(result, "should not be nil")

        XCTAssertTrue(result == "idTest", "should be equal to idTest")

    }


    func test_ShouldBeAbleToGetAttributesForRepresentation_whenRepresentationisNil () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)

        let result = instanceRestClient?.attributes(forRepresentation: nil, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNil(result, "should be nil")
    }

    func test_ShouldBeAbleToGetAttributesForRepresentation_whenRepresentationHaveMoreDataThenModel () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)


        let responseObject = [
            "id":"idTest",
            "name": "test",
            "artistDescription":"test"
            ] as [String : String]

        let result = instanceRestClient?.attributes(forRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNotNil(result, "should be nil")
        XCTAssertTrue(result?.keys.count == 2, "should be equals to 2")
        XCTAssertTrue((result?.keys.contains("name"))!, "should contains name")
        XCTAssertTrue((result?.keys.contains("artistDescription"))!, "should contains artistDescription")
    }

    func test_ShouldBeAbleToGetAttributesForRepresentation_whenRepresentationHaveMoreDataThenModelAndThereIsADateWithFormatISO8601 () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)


        let responseObject = [
            "id":"idTest",
            "name": "test",
            "artistDescription":"test",
            "birthDate": "2013-09-29T18:46:19Z" //YYYY-MM-dd'T'HH:mm:ssZ
            ] as [String : String]

        let result = instanceRestClient?.attributes(forRepresentation: responseObject, ofEntity: entityDescriptionArtist, from: nil)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue(result?.keys.count == 3, "should be equals to 3")
        XCTAssertTrue((result?.keys.contains("name"))!, "should contains name")
        XCTAssertTrue((result?.keys.contains("artistDescription"))!, "should contains artistDescription")
        XCTAssertTrue((result?.keys.contains("birthDate"))!, "should contains birthDate")
    }


    func test_ShouldBeAbleToCreateAFetchRequest_whenThereIsNotAPaginator () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
        fetchRequest.entity = entityDescriptionArtist

        let result = instanceRestClient?.request(for: fetchRequest, with: moc)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue(result?.url?.absoluteString == "https://localhost/artists", "should be equals to https://localhost/artists")

    }

    func test_ShouldBeAbleToCreateARequestPathForObjectWithID () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)

        createFakeClientHTTPandSaveContext(moc: moc)

        let result = instanceRestClient?.request(withMethod: "GET", pathForObjectWith: artist.objectID, with: moc)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))! , "should contains to https://localhost/artists")
        let countString = result?.url?.absoluteString.replacingOccurrences(of: "https://localhost/artists/", with: "").count
        XCTAssertTrue(countString! > 0 , "should be greater then zero")

    }


}
