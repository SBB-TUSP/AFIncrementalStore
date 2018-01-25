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

    func test_typeShouldThrowError() {
        XCTAssertTrue(throwsToBool {
            _ = AFIncrementalStore.type()
        })
    }

    func test_modelShouldThrowError() {
        XCTAssertTrue(throwsToBool {
            _ = AFIncrementalStore.model()
        })
    }

    func test_executeFetchRequestShouldReturnEmptyArray_whenDBEmpty() {
        class FakeClient: AFHTTPClient, AFIncrementalStoreHTTPClient {

            func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                return nil
            }

            func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return nil
            }

            func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                return nil
            }

            func request(withMethod method: String!, pathForObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return nil
            }

            func request(withMethod method: String!, pathForRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return nil
            }

            func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            var testFinishedClosure: (() -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                successClosure = success
                return AFHTTPRequestOperation(request: urlRequest)
            }

            func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                testFinishedClosure()
                return [Artist]()
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                successClosure(operation, [String: Any]())
            }

        }
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        let fakeClient = FakeClient(baseURL: URL(string: "http://localhost"))
        fakeClient?.testFinishedClosure = {
            testFinishExpectation.fulfill()
        }
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        var results: [Artist]!
        context.performAndWait {
            do {
                results = try self.store.execute(request, with: context) as? [Artist]
            } catch let e {
                print(e)
            }
        }
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
        wait(for: [testFinishExpectation], timeout: 1)
    }
    
}
