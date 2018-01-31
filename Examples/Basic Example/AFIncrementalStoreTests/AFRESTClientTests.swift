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
        XCTAssertTrue(resultDictionary["name"] == "test", "should be equals to test")
        XCTAssertTrue(resultDictionary["artistDescription"] == "test", "should be equals to test")
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
        XCTAssertTrue(resultDictionary["name"] == "test", "should be equals to test")
        XCTAssertTrue(resultDictionary["artistDescription"] == "test", "should be equals test")
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

        XCTAssertTrue(result == "idTest", "should be equals to idTest")

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

        XCTAssertNotNil(result, "should not be nil")
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


    func test_ShouldBeAbleToCreateARequestPathForRelationship () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let entityDescriptionSong = NSEntityDescription.entity(forEntityName: "Song", in: moc)
        let entityRelationshipDescription = entityDescriptionArtist?.relationships(forDestination: entityDescriptionSong!)[0]

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc)

        createFakeClientHTTPandSaveContext(moc: moc)

        let result = instanceRestClient?.request(withMethod: "GET", pathForRelationship: entityRelationshipDescription, forObjectWith: artist.objectID, with: moc)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))! , "should contains to https://localhost/artists")
        let countString = result?.url?.absoluteString.replacingOccurrences(of: "https://localhost/artists/", with: "").count
        XCTAssertTrue(countString! > 0 , "should be greater then zero")

        let resultComponent = result?.url?.absoluteString.replacingOccurrences(of: "https://localhost/artists/", with: "").components(separatedBy: "/")

        XCTAssertTrue(resultComponent?.count == 2, "should be equals to 2")
        XCTAssertTrue(resultComponent![1] == "songs", "should be equals to songs")
        XCTAssertTrue(resultComponent![0].count > 0, "should be greater then zero")

    }

    func test_ShouldFetchRemoteValuesForRelationship () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let entityDescriptionArtist = NSEntityDescription.entity(forEntityName: "Artist", in: moc)
        let entityDescriptionSong = NSEntityDescription.entity(forEntityName: "Song", in: moc)
        let entityRelationshipDescription = entityDescriptionArtist?.relationships(forDestination: entityDescriptionSong!)[0]

        let result = instanceRestClient?.shouldFetchRemoteValues(forRelationship: entityRelationshipDescription, forObjectWith: nil, in: nil)

        XCTAssertTrue(result!, "should be true")
    }


    func test_ShouldBeAbleToGetRepresentationOfAttributes () {

        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc) as? Artist
        artist?.name = "test"
        artist?.artistDescription = "test"
        artist?.birthDate = Date()

        let lazyMapCollection = artist?.entity.attributesByName.keys
        let componentArray = Array(lazyMapCollection!)
        let dictionary = artist?.dictionaryWithValues(forKeys: componentArray)
        let result = instanceRestClient?.representation(ofAttributes: dictionary, of: artist)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue(result?.keys.count == 3, "should be equals to 3")
        XCTAssertNotNil(result?["name"] , "should not be nil")
        XCTAssertNotNil(result?["artistDescription"] , "should not be nil")
        XCTAssertNotNil(result?["birthDate"] , "should not be nil")

    }


    func test_ShoulBeCreateARequestForInsertedObject() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc) as? Artist
        artist?.name = "test"
        artist?.artistDescription = "test"
        artist?.birthDate = Date.distantPast

        createFakeClientHTTPandSaveContext(moc: moc)

        var result = instanceRestClient?.request(forInsertedObject: artist)

        //encoding AFFormURLParameterEncoding
        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue(result?.httpMethod == "POST", "should be equals to POST")
        XCTAssertTrue(result?.url?.absoluteString == "https://localhost/artists" , "should be equals to https://localhost/artists")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        var httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "artistDescription=test&birthDate=0000-12-30%2000%3A00%3A00%20%2B0000&name=test", "should be equals to artistDescription=test&birthDate=0000-12-30%2000%3A00%3A00%20%2B0000&name=test")

        var httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/x-www-form-urlencoded; charset=utf-8", "shoul be equals to application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

        //encoding AFJSONParameterEncoding

        instanceRestClient?.parameterEncoding = AFJSONParameterEncoding
        result = instanceRestClient?.request(forInsertedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue(result?.url?.absoluteString == "https://localhost/artists" , "should be equals to https://localhost/artists")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "{\"artistDescription\":\"test\",\"name\":\"test\",\"birthDate\":\"0000-12-30 00:00:00 +0000\"}", "should be equals to {\"artistDescription\":\"test\",\"name\":\"test\",\"birthDate\":\"0000-12-30 00:00:00 +0000\"}")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/json; charset=utf-8", "shoul be equals to application/json; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")


        //encoding AFPropertyListParameterEncoding

        instanceRestClient?.parameterEncoding = AFPropertyListParameterEncoding
        result = instanceRestClient?.request(forInsertedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue(result?.url?.absoluteString == "https://localhost/artists" , "should be equals to https://localhost/artists")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>artistDescription</key>\n\t<string>test</string>\n\t<key>birthDate</key>\n\t<string>0000-12-30 00:00:00 +0000</string>\n\t<key>name</key>\n\t<string>test</string>\n</dict>\n</plist>\n",
                      "should be equals to <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>artistDescription</key>\n\t<string>test</string>\n\t<key>birthDate</key>\n\t<string>0000-12-30 00:00:00 +0000</string>\n\t<key>name</key>\n\t<string>test</string>\n</dict>\n</plist>\n")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/x-plist; charset=utf-8", "shoul be equals to application/x-plist; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

    }




    func test_ShoulBeCreateARequestForUpdateObject() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc) as? Artist
        artist?.name = "test"
        artist?.artistDescription = "test"
        artist?.birthDate = Date.distantPast

        createFakeClientHTTPandSaveContext(moc: moc)

        var result = instanceRestClient?.request(forUpdatedObject: artist)

        XCTAssertNil(result , "should be nil")

        artist?.birthDate = Date.distantFuture

        result = instanceRestClient?.request(forUpdatedObject: artist)

        //encoding AFFormURLParameterEncoding
        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue(result?.httpMethod == "PUT", "should be equals to PUT")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        var httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "birthDate=4001-01-01%2000%3A00%3A00%20%2B0000", "should be equals to birthDate=4001-01-01%2000%3A00%3A00%20%2B0000")

        var httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/x-www-form-urlencoded; charset=utf-8", "shoul be equals to application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

        //encoding AFJSONParameterEncoding

        instanceRestClient?.parameterEncoding = AFJSONParameterEncoding
        result = instanceRestClient?.request(forUpdatedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "{\"birthDate\":\"4001-01-01 00:00:00 +0000\"}", "should be equals to {\"birthDate\":\"4001-01-01 00:00:00 +0000\"}")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/json; charset=utf-8", "shoul be equals to application/json; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")


        //encoding AFPropertyListParameterEncoding

        instanceRestClient?.parameterEncoding = AFPropertyListParameterEncoding
        result = instanceRestClient?.request(forUpdatedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")
        XCTAssertNotNil(result?.httpBody, "should not be nil")

        httpBodyString = String(bytes: result!.httpBody!, encoding: .utf8)
        XCTAssertTrue(httpBodyString == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>birthDate</key>\n\t<string>4001-01-01 00:00:00 +0000</string>\n</dict>\n</plist>\n",
                      "should be equals to <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>birthDate</key>\n\t<string>4001-01-01 00:00:00 +0000</string>\n</dict>\n</plist>\n")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertTrue(httpHeader?["Content-Type"] == "application/x-plist; charset=utf-8", "shoul be equals to application/x-plist; charset=utf-8")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

    }


    func test_ShoulBeCreateARequestForDeleteObject() {
        let instanceRestClient = AFRESTClient(baseURL: baseURL as URL!)

        XCTAssertNotNil(instanceRestClient, "should be able to create an instance of AFRESTClient")
        XCTAssertEqual(instanceRestClient?.baseURL, baseURL , "should be able to create an instance of AFRESTClient")

        let artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: moc) as? Artist
        artist?.name = "test"
        artist?.artistDescription = "test"
        artist?.birthDate = Date.distantPast

        createFakeClientHTTPandSaveContext(moc: moc)

        var result = instanceRestClient?.request(forDeletedObject: artist)

        //encoding AFFormURLParameterEncoding
        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue(result?.httpMethod == "DELETE", "should be equals to DELETE")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")

        var httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

        //encoding AFJSONParameterEncoding

        instanceRestClient?.parameterEncoding = AFJSONParameterEncoding
        result = instanceRestClient?.request(forDeletedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")


        //encoding AFPropertyListParameterEncoding

        instanceRestClient?.parameterEncoding = AFPropertyListParameterEncoding
        result = instanceRestClient?.request(forDeletedObject: artist)

        XCTAssertNotNil(result , "should not be nil")
        XCTAssertTrue((result?.url?.absoluteString.contains("https://localhost/artists/"))!, "should contains https://localhost/artists/")

        httpHeader = result?.allHTTPHeaderFields
        XCTAssertNotNil(httpHeader, "should not be nil")
        XCTAssertNotNil(httpHeader?["User-Agent"], "should not be nil")
        XCTAssertNotNil(httpHeader?["Accept-Language"], "should not be nil")

    }


    func test_ShouldBeAbleToCreateAFLimitAndOffsetPaginator() {
        let instancePaginator = AFLimitAndOffsetPaginator(limitParameter: "limitTest", offsetParameter: "offsetTest")

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFLimitAndOffsetPaginator")
    }

    func test_ShouldBeAbleToGetParametersForFetchRequest_whenThereIsAOffsetPaginator() {
        let instancePaginator = AFLimitAndOffsetPaginator(limitParameter: "limitTest", offsetParameter: "offsetTest")

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFLimitAndOffsetPaginator")

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchOffset = 1

        let result = instancePaginator?.parameters(for: fetchRequest)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue(Array(result!.keys).count == 2, "should be equals to 2")
        XCTAssertNotNil(result?["limitTest"], "should not be nil")
        XCTAssertNotNil(result?["offsetTest"], "should not be nil")
    }



    func test_ShouldBeAbleToCreateAFPageAndPerPagePaginator() {
        let instancePaginator = AFPageAndPerPagePaginator(pageParameter: "pageTest", perPageParameter: "perPageTest")

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFPageAndPerPagePaginator")
    }

    func test_ShouldBeAbleToGetParametersForFetchRequest_whenThereIsAPagePaginator() {
        let instancePaginator = AFPageAndPerPagePaginator(pageParameter: "pageTest", perPageParameter: "perPageTest")

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFPageAndPerPagePaginator")

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 20
        fetchRequest.fetchOffset = 1

        let result = instancePaginator?.parameters(for: fetchRequest)

        XCTAssertNotNil(result, "should not be nil")
        XCTAssertTrue(Array(result!.keys).count == 2, "should be equals to 2")
        XCTAssertNotNil(result?["pageTest"], "should not be nil")
        XCTAssertNotNil(result?["perPageTest"], "should not be nil")
    }


    func test_ShouldBeAbleToCreateAFBlockPaginator() {
        let instancePaginator = AFBlockPaginator {
            (fetchRequest) -> [AnyHashable : Any]? in

            return [:]

        }

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFBlockPaginator")
    }

    func test_ShouldBeAbleToGetParametersForFetchRequest_whenThereIsABlockPaginator() {
        let instancePaginator = AFBlockPaginator {
            (fetchRequest) -> [AnyHashable : Any]? in
            return [:]
        }

        XCTAssertNotNil(instancePaginator, "should be able to create an instance of AFBlockPaginator")

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 20
        fetchRequest.fetchOffset = 1

        let result = instancePaginator?.parameters(for: fetchRequest)

        XCTAssertNotNil(result, "should not be nil")
    }

}
