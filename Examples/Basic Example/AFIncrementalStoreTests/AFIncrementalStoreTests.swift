//
//  AFIncrementalStoreTests.swift
//  AFIncrementalStoreTests
//
//  Created by Alessandro Ranaldi on 25/01/2018.
//

import XCTest

class AFIncrementalStoreTests: XCTestCase {

    private var modelUrl: URL!

    private var model: NSManagedObjectModel!

    private var coordinator: NSPersistentStoreCoordinator!

    private var store: AFIncrementalStore!

    private var errorCreatingBackingStore: Error!
    
    override func setUp() {
        super.setUp()
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
    }
    
    override func tearDown() {
        store = nil
        model = nil
        coordinator = nil
        modelUrl = nil
        errorCreatingBackingStore = nil
        super.tearDown()
    }

    func test_ShouldBeAbleToCreateIncrementalStore() {
        XCTAssertNotNil(modelUrl)
        XCTAssertNotNil(model)
        XCTAssertNil(errorCreatingBackingStore, "\(errorCreatingBackingStore)")
        XCTAssertNotNil(store)
    }

    func test_typeShouldThrowException() {
        XCTAssertTrue(blockThrowsException {
            _ = AFIncrementalStore.type()
        })
    }

    func test_modelShouldThrowException() {
        XCTAssertTrue(blockThrowsException {
            _ = AFIncrementalStore.model()
        })
    }

//    func test_executeFetchRequestShouldReturnEmptyArray_whenDBAndResponseEmpty() {
//        class FakeClientSubclass: FakeClient {
//
//            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
//                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
//            }
//
//            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!
//
//            var testFinishedClosure: (() -> Void)!
//
//            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
//                successClosure = success
//                return AFHTTPRequestOperation(request: urlRequest)
//            }
//
//            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
//                testFinishedClosure()
//                return [Artist]()
//            }
//
//            override func enqueue(_ operation: AFHTTPRequestOperation!) {
//                successClosure(operation, [String: Any]())
//            }
//
//        }
//        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
//        let fakeClient = FakeClientSubclass(baseURL: URL(string: "http://localhost"))
//        fakeClient?.testFinishedClosure = {
//            testFinishExpectation.fulfill()
//        }
//        store.httpClient = fakeClient
//        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        context.persistentStoreCoordinator = coordinator
//        let request = NSFetchRequest<Artist>()
//        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
//        var results: [Artist]!
//        context.performAndWait {
//            do {
//                results = try self.store.execute(request, with: context) as? [Artist]
//            } catch let e {
//                print(e)
//            }
//        }
//        XCTAssertNotNil(results)
//        XCTAssertTrue(results.isEmpty)
//        wait(for: [testFinishExpectation], timeout: 1)
//    }
//
//    func test_executeFetchRequestShouldReturnEmptyArray_whenDBNotEmptyAndResponseEmpty() {
//        class FakeClientSubclass: FakeClient {
//
//            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
//                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
//            }
//
//            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!
//
//            var testFinishedClosure: (() -> Void)!
//
//            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
//                successClosure = success
//                return AFHTTPRequestOperation(request: urlRequest)
//            }
//
//            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
//                testFinishedClosure()
//                return [Artist]()
//            }
//
//            override func enqueue(_ operation: AFHTTPRequestOperation!) {
//                successClosure(operation, [String: Any]())
//            }
//
//        }
//        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
//        let fakeClient = FakeClientSubclass(baseURL: URL(string: "http://localhost"))
//        fakeClient?.testFinishedClosure = {
//            testFinishExpectation.fulfill()
//        }
//        store.httpClient = fakeClient
//        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        context.persistentStoreCoordinator = coordinator
//        context.performAndWait {
//            _ = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
//            _ = try! context.save()
//        }
//        let request = NSFetchRequest<Artist>()
//        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
//        var results: [Artist]!
//        context.performAndWait {
//            do {
//                results = try self.store.execute(request, with: context) as? [Artist]
//            } catch let e {
//                print(e)
//            }
//        }
//        XCTAssertNotNil(results)
//        XCTAssertTrue(results.isEmpty)
//        wait(for: [testFinishExpectation], timeout: 1)
//    }
//
//    func test_executeFetchRequestShouldReturnNonEmptyArray_whenDBEmptyAndResponseNotEmpty() {
//        class FakeClientSubclass: FakeClient {
//
//            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
//                return "TEST-ID"
//            }
//
//            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
//                let dictionary: [String: Any] = [
//                    "artistDescription": "TEST-DESCRIPTION",
//                    "name": "TEST-ARTIST",
//                    "songs": [Any]()
//                ]
//                return dictionary
//            }
//
//            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
//                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
//            }
//
//            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!
//
//            var testFinishedClosure: (() -> Void)!
//
//            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
//                successClosure = success
//                return AFHTTPRequestOperation(request: urlRequest)
//            }
//
//            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
//                testFinishedClosure()
//                let dictionary: [String: Any] = [
//                    "artistDescription": "TEST-DESCRIPTION",
//                    "name": "TEST-ARTIST",
//                    "songs": [[String: Any]]()
//                ]
//                return dictionary
//            }
//
//            override func enqueue(_ operation: AFHTTPRequestOperation!) {
//                successClosure(operation, [String: Any]())
//            }
//
//        }
//        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
//        let fakeClient = FakeClientSubclass(baseURL: URL(string: "http://localhost"))
//        fakeClient?.testFinishedClosure = {
//            testFinishExpectation.fulfill()
//        }
//        store.httpClient = fakeClient
//        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        context.persistentStoreCoordinator = coordinator
//        let request = NSFetchRequest<Artist>()
//        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
//        var results: [NSManagedObject]!
//        context.performAndWait {
//            results = try! self.store.execute(request, with: context) as! [NSManagedObject]
//        }
//        XCTAssertNotNil(results)
//        XCTAssertFalse(results.isEmpty)
//        let rawArtist: NSManagedObject! = results.first
//        XCTAssertNotNil(rawArtist)
//        XCTAssertEqual(rawArtist.entity.name, "Artist")
//        XCTAssertEqual(rawArtist.value(forKey: "name") as? String, "TEST-ARTIST")
//        wait(for: [testFinishExpectation], timeout: 1)
//    }
//
//    func test_executeFetchRequestShouldReturnIDs_whenRequestTypeIsIDResultType() {
//        class FakeClientSubclass: FakeClient {
//
//            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
//                return "TEST-ID"
//            }
//
//            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
//                let dictionary: [String: Any] = [
//                    "artistDescription": "TEST-DESCRIPTION",
//                    "name": "TEST-ARTIST",
//                    "songs": [Any]()
//                ]
//                return dictionary
//            }
//
//            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
//                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
//            }
//
//            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!
//
//            var testFinishedClosure: (() -> Void)!
//
//            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
//                successClosure = success
//                return AFHTTPRequestOperation(request: urlRequest)
//            }
//
//            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
//                testFinishedClosure()
//                let dictionary: [String: Any] = [
//                    "artistDescription": "TEST-DESCRIPTION",
//                    "name": "TEST-ARTIST",
//                    "songs": [[String: Any]]()
//                ]
//                return dictionary
//            }
//
//            override func enqueue(_ operation: AFHTTPRequestOperation!) {
//                successClosure(operation, [String: Any]())
//            }
//
//        }
//        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
//        let fakeClient = FakeClientSubclass(baseURL: URL(string: "http://localhost"))
//        fakeClient?.testFinishedClosure = {
//            testFinishExpectation.fulfill()
//        }
//        store.httpClient = fakeClient
//        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        context.persistentStoreCoordinator = coordinator
//        let request = NSFetchRequest<Artist>()
//        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
//        request.resultType = NSFetchRequestResultType.managedObjectIDResultType
//        var rawResults: Any!
//        context.performAndWait {
//            _ = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
//            _ = try! context.save()
//            rawResults = try! self.store.execute(request, with: context)
//        }
//        XCTAssertNotNil(rawResults)
//        let arrayResults: [NSManagedObjectID]! = rawResults as? [NSManagedObjectID]
//        XCTAssertNotNil(arrayResults)
//        let id: NSManagedObjectID! = arrayResults.first
//        XCTAssertNotNil(id)
//        XCTAssert(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
//        wait(for: [testFinishExpectation], timeout: 1)
//    }

}
