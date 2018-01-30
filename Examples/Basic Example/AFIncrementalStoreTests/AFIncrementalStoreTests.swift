//
//  AFIncrementalStoreTests.swift
//  AFIncrementalStoreTests
//
//  Created by Alessandro Ranaldi on 25/01/2018.
//

import XCTest

private class FakeClient: AFHTTPClient, AFIncrementalStoreHTTPClient {

    override init() {
        super.init(baseURL: URL(string: "http://localhost")!)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

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
        return nil
    }

    func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
        return nil
    }

}

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
        NotificationCenter.default.removeObserver(self)
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

    func test_executeFetchRequestShouldReturnEmptyArray_whenDBAndResponseEmpty() {
        class FakeClientSubclass1: FakeClient {

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            var testFinishedClosure: (() -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                successClosure = success
                return AFHTTPRequestOperation(request: urlRequest)
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                testFinishedClosure()
                return [Artist]()
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                successClosure(operation, [String: Any]())
            }

        }
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        let fakeClient = FakeClientSubclass1()
        fakeClient.testFinishedClosure = {
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
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnEmptyArray_whenDBNotEmptyAndResponseEmpty() {
        class FakeClientSubclass2: FakeClient {

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            var testFinishedClosure: (() -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                successClosure = success
                return AFHTTPRequestOperation(request: urlRequest)
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                testFinishedClosure()
                return [Artist]()
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                successClosure(operation, [String: Any]())
            }

        }
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        let fakeClient = FakeClientSubclass2()
        fakeClient.testFinishedClosure = {
            testFinishExpectation.fulfill()
        }
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.performAndWait {
            _ = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            _ = try! context.save()
        }
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
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnNonEmptyArray_whenDBEmptyAndResponseNotEmpty() {
        class FakeClientSubclass3: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            var testFinishedClosure: (() -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                successClosure = success
                return AFHTTPRequestOperation(request: urlRequest)
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                testFinishedClosure()
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                successClosure(operation, [String: Any]())
            }

        }
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        let fakeClient = FakeClientSubclass3()
        fakeClient.testFinishedClosure = {
            testFinishExpectation.fulfill()
        }
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        var results: [NSManagedObject]!
        context.performAndWait {
            results = try! self.store.execute(request, with: context) as! [NSManagedObject]
        }
        XCTAssertNotNil(results)
        XCTAssertFalse(results.isEmpty)
        let rawArtist: NSManagedObject! = results.first
        XCTAssertNotNil(rawArtist)
        XCTAssertEqual(rawArtist.entity.name, "Artist")
        XCTAssertEqual(rawArtist.value(forKey: "name") as? String, "TEST-ARTIST")
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnIDs_whenRequestTypeIsIDResultType() {
        class FakeClientSubclass4: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            var testFinishedClosure: (() -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                successClosure = success
                return AFHTTPRequestOperation(request: urlRequest)
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                testFinishedClosure()
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                successClosure(operation, [String: Any]())
            }

        }
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        let fakeClient = FakeClientSubclass4()
        fakeClient.testFinishedClosure = {
            testFinishExpectation.fulfill()
        }
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        request.resultType = NSFetchRequestResultType.managedObjectIDResultType
        var rawResults: Any!
        context.performAndWait {
            _ = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            _ = try! context.save()
            rawResults = try! self.store.execute(request, with: context)
        }
        XCTAssertNotNil(rawResults)
        let arrayResults: [NSManagedObjectID]! = rawResults as? [NSManagedObjectID]
        XCTAssertNotNil(arrayResults)
        let id: NSManagedObjectID! = arrayResults.first
        XCTAssertNotNil(id)
        XCTAssert(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequest_shouldNotifyWhenRemoteFetchIsPerformed() {
        let willFetchNotification = expectation(description: "should call will fetch remote values")
        willFetchNotification.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextWillFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertFalse(operation.isFinished)
            XCTAssertFalse(operation.isExecuting)
            let request: NSFetchRequest<Artist>! = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSFetchRequest<Artist>
            XCTAssertNotNil(request)
            willFetchNotification.fulfill()
        }
        let didFetchNotification = expectation(description: "should call did fetch remote values")
        didFetchNotification.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let ids: [NSManagedObjectID]! = userInfo["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID]
            XCTAssertNotNil(ids)
            XCTAssertFalse(ids.isEmpty)
            XCTAssertEqual(ids.count, 1)
            XCTAssertTrue(ids.first!.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.isFinished)
            let request: NSFetchRequest<Artist>! = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSFetchRequest<Artist>
            XCTAssertNotNil(request)
            didFetchNotification.fulfill()
        }

        class FakeClientSubclass5: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return entity.name == "Artist" ? dictionary : nil
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            var successClosure: ((AFHTTPRequestOperation?, Any?) -> Void)!

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation.init(request: urlRequest)
                operation?.setCompletionBlockWithSuccess({ _, _ in }, failure: { (operation, error) in
                    success(operation, [String: Any]())
                })
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

            override func enqueue(_ operation: AFHTTPRequestOperation!) {
                operation.start()
            }

        }
        let fakeClient = FakeClientSubclass5()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        context.performAndWait {
            _ = try! self.store.execute(request, with: context)
        }
        wait(for: [willFetchNotification, didFetchNotification], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldNotifyWhenRemoteFetchIsPerformed() {
        let willSaveNotification = expectation(description: "should call will save remote values")
        willSaveNotification.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextWillSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            if let operation = operations.first  {
                XCTAssertEqual(operations.count, 1)
                XCTAssertFalse(operation.isFinished)
                XCTAssertFalse(operation.isExecuting)
            }
            let request: NSSaveChangesRequest? = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest
            XCTAssertNotNil(request)
            willSaveNotification.fulfill()
        }
        let didSaveNotification = expectation(description: "should call did save remote values")
        didSaveNotification.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.isFinished)
            let request: NSSaveChangesRequest? = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest
            XCTAssertNotNil(request)
            didSaveNotification.fulfill()
        }
        class FakeClientSubclass5: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation(request: urlRequest)
                operation?.failureCallbackQueue = .main
                operation?.setCompletionBlockWithSuccess({_,_ in}, failure: { operation, _ in
                    success(operation, "")
                })
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

            override func enqueueBatch(ofHTTPRequestOperations operations: [Any]!, progressBlock: ((UInt, UInt) -> Void)!, completionBlock: (([Any]?) -> Void)!) {
                super.enqueueBatch(ofHTTPRequestOperations: operations, progressBlock: progressBlock) {
                    operations in
                    completionBlock(operations)
                    self.completion?()
                }
            }

            var completion: (() -> Void)?

        }
        let client = FakeClientSubclass5()
        store.httpClient = client
        let finishExpectation = expectation(description: "should finish async calls")
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        client.completion = {
            context.perform {
                let request = NSFetchRequest<Artist>()
                request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
                let result = try! context.fetch(request)
                XCTAssertEqual(result.count, 1)
                let artist = result.first!
                XCTAssertEqual(artist.name, "TEST-ARTIST")
                XCTAssertEqual(artist.artistDescription, "TEST-DESCRIPTION")
                finishExpectation.fulfill()
            }
        }
        context.perform {
            let artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.artistDescription = "TEST-DESCRIPTION"
            artist.name = "TEST-ARTIST"
            let request = NSSaveChangesRequest(inserted: [artist], updated: [], deleted: [], locked: [])
            _ = try! self.store.execute(request, with: context)
        }
        wait(for: [finishExpectation, willSaveNotification, didSaveNotification], timeout: 10)
    }

    func test_newValuesForObjectWithId_shouldSendNotifications() {
        let willFetchNewValues = expectation(description: "should send will fetch new values notification")
        willFetchNewValues.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextWillFetchNewValuesForObject"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            if let operation = operations.first  {
                XCTAssertEqual(operations.count, 1)
                XCTAssertFalse(operation.isFinished)
                XCTAssertFalse(operation.isExecuting)
            }
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            willFetchNewValues.fulfill()
        }
        let didFetchNewValues = expectation(description: "should send did fetch new values notification")
        didFetchNewValues.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidFetchNewValuesForObject"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.isFinished)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            didFetchNewValues.fulfill()
        }
        class FakeClientSubclass6: FakeClient {

            func shouldFetchRemoteAttributeValuesForObject(with objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation(request: urlRequest)
                operation?.failureCallbackQueue = .main
                operation?.setCompletionBlockWithSuccess({ _, _ in }, failure: {
                    operation, _ in
                    success?(operation, [String: Any]())
                })
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return entity.name == "Artist" ? dictionary : nil
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return entity.name == "Artist" ? dictionary : nil
            }

            override func request(withMethod method: String!, pathForObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func enqueueBatch(ofHTTPRequestOperations operations: [Any]!, progressBlock: ((UInt, UInt) -> Void)!, completionBlock: (([Any]?) -> Void)!) {
                super.enqueueBatch(ofHTTPRequestOperations: operations, progressBlock: progressBlock) {
                    operations in
                    completionBlock(operations)
                    self.completion?()
                }
            }

            var completion: (() -> Void)?

        }
        let finishExpectation = expectation(description: "should finish calls and checks")
        finishExpectation.assertForOverFulfill = false
        let fakeClient = FakeClientSubclass6()
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        fakeClient.completion = {
            context.perform {
                let node = try! self.store.newValuesForObject(with: artist.objectID, with: context)
                XCTAssertEqual(node.objectID, artist.objectID)
                let nameProperty = NSPropertyDescription()
                nameProperty.name = "name"
                XCTAssertEqual(node.value(for: nameProperty) as? String, nil)
                let descriptionProperty = NSPropertyDescription()
                descriptionProperty.name = "artistDescription"
                XCTAssertEqual(node.value(for: descriptionProperty) as? String, nil)
                XCTAssertEqual(node.version, 1)
                finishExpectation.fulfill()
            }
        }
        store.httpClient = fakeClient
        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            try! self.store.execute(NSSaveChangesRequest(inserted: [artist], updated: nil, deleted: nil, locked: nil), with: context)
        }
        wait(for: [finishExpectation, willFetchNewValues, didFetchNewValues], timeout: 10)
    }

    func test_newValueForRelationship_shouldSendNotifications() {
        let willFetchExpectation = expectation(description: "should send will fetch new values for relationship notification")
        willFetchExpectation.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextWillFetchNewValuesForRelationship"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let relationship: NSRelationshipDescription! = userInfo["AFIncrementalStoreFaultingRelationship"] as? NSRelationshipDescription
            XCTAssertNotNil(relationship)
            XCTAssertTrue((relationship.name == "songs" && relationship.inverseRelationship?.name == "artist") || relationship.name == "artist" && (relationship.inverseRelationship?.name == "songs"))
            XCTAssertTrue((relationship.destinationEntity?.name == "Song" && relationship.inverseRelationship?.destinationEntity?.name == "Artist") || (relationship.destinationEntity?.name == "Artist" && relationship.inverseRelationship?.destinationEntity?.name == "Song"))
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertFalse(operation.isFinished)
            XCTAssertFalse(operation.isExecuting)
            willFetchExpectation.fulfill()
        }
        let didFetchExpectation = expectation(description: "should send will fetch new values for relationship notification")
        didFetchExpectation.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidFetchNewValuesForRelationship"), object: nil, queue: .main) {
            notification in
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let relationship: NSRelationshipDescription! = userInfo["AFIncrementalStoreFaultingRelationship"] as? NSRelationshipDescription
            XCTAssertNotNil(relationship)
            XCTAssertTrue((relationship.name == "songs" && relationship.inverseRelationship?.name == "artist") || relationship.name == "artist" && (relationship.inverseRelationship?.name == "songs"))
            XCTAssertTrue((relationship.destinationEntity?.name == "Song" && relationship.inverseRelationship?.destinationEntity?.name == "Artist") || (relationship.destinationEntity?.name == "Artist" && relationship.inverseRelationship?.destinationEntity?.name == "Song"))
            let operations: [AFHTTPRequestOperation]! = userInfo["AFIncrementalStoreRequestOperations"] as? [AFHTTPRequestOperation]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: AFHTTPRequestOperation! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.isFinished)
            didFetchExpectation.fulfill()
        }
        class FakeClientSubclass7: FakeClient {

            func shouldFetchRemoteValues(forRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func shouldFetchRemoteAttributeValuesForObject(with objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func request(withMethod method: String!, pathForRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation(request: urlRequest)
                operation?.failureCallbackQueue = .main
                operation?.setCompletionBlockWithSuccess({ _, _ in }, failure: {
                    operation, _ in
                    success?(operation, [String: Any]())
                })
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                let dictionary: [String: Any] = entity.name == "Artist" ? [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                    ] : [
                        "title": "TEST-SONG"
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                let dictionary: [String: Any] = entity.name == "Artist" ? [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                    ] : [
                        "title": "TEST-SONG"
                ]
                return dictionary
            }

            override func request(withMethod method: String!, pathForObjectWith objectID: NSManagedObjectID!, with context: NSManagedObjectContext!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost")!)
            }

            override func enqueueBatch(ofHTTPRequestOperations operations: [Any]!, progressBlock: ((UInt, UInt) -> Void)!, completionBlock: (([Any]?) -> Void)!) {
                super.enqueueBatch(ofHTTPRequestOperations: operations, progressBlock: progressBlock) {
                    operations in
                    completionBlock(operations)
                    self.completion?()
                }
            }

            override func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                return [AnyHashable: Any]()
            }

            var completion: (() -> Void)?

        }
        let client = FakeClientSubclass7()
        let finishExpectation = expectation(description: "should finish calls and callbacks")
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        client.completion = {
            client.completion = nil
            context.perform {
                let relationshipDescription = NSEntityDescription.entity(forEntityName: "Artist", in: context)!.relationships(forDestination: NSEntityDescription.entity(forEntityName: "Song", in: context)!).first!
                let destination = try? self.store.newValue(forRelationship: relationshipDescription, forObjectWith: artist.objectID, with: context)
                let ids: [NSManagedObjectID]! = destination as? [NSManagedObjectID]
                XCTAssertNotNil(ids)
                XCTAssertTrue(ids.isEmpty)
                finishExpectation.fulfill()
            }
        }
        store.httpClient = client
        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            try! self.store.execute(NSSaveChangesRequest.init(inserted: [artist], updated: nil, deleted: nil, locked: nil), with: context)
        }
        wait(for: [finishExpectation, willFetchExpectation, didFetchExpectation], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldWorkForUpdates() {
        class FakeClientSubclass8: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost/insert")!)
            }

            func request(forUpdatedObject updatedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost/update")!)
            }

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation(request: urlRequest)
                operation?.failureCallbackQueue = .main
                operation?.setCompletionBlockWithSuccess(nil) {
                    operation, _ in
                    let dictionary: [String: Any] = [
                        "request": operation!.request.url!.lastPathComponent
                    ]
                    success?(operation, dictionary)
                }
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                if (responseObject as! [String: Any])["request"] as! String == "insert" {
                    let dictionary: [String: Any] = [
                        "name": "TEST-ARTIST",
                        "artistDescription": "TEST-DESCRIPTION"
                    ]
                    return dictionary
                }
                let dictionary: [String: Any] = [
                    "name": "TEST-ARTIST-EDITED",
                    "artistDescription": "TEST-DESCRIPTION"
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                return representation
            }

        }
        let client = FakeClientSubclass8()
        store.httpClient = client
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        let finishExpectation = expectation(description: "should finish all calls and callbacks")
        finishExpectation.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) { [weak self]
            notification in
            guard (notification.userInfo?["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest)?.updatedObjects?.count == 1 else {
                context.perform {
                    artist.name = "TEST-ARTIST-EDITED"
                    _ = try? self?.store?.execute(NSSaveChangesRequest(inserted: nil, updated: [artist], deleted: nil, locked: nil), with: context)
                }
                return
            }
            finishExpectation.fulfill()
        }
        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.name = "TEST-ARTIST"
            artist.artistDescription = "TEST-DESCRIPTION"
            _ = try! self.store.execute(NSSaveChangesRequest(inserted: [artist], updated: nil, deleted: nil, locked: nil), with: context)
        }
        wait(for: [finishExpectation], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldWorkForDeletions() {
        class FakeClientSubclass8: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost/insert")!)
            }

            func request(forDeletedObject updatedObject: NSManagedObject!) -> NSMutableURLRequest! {
                return NSMutableURLRequest(url: URL(string: "http://localhost/delete")!)
            }

            override func httpRequestOperation(with urlRequest: URLRequest!, success: ((AFHTTPRequestOperation?, Any?) -> Void)!, failure: ((AFHTTPRequestOperation?, Error?) -> Void)!) -> AFHTTPRequestOperation! {
                let operation = AFHTTPRequestOperation(request: urlRequest)
                operation?.failureCallbackQueue = .main
                operation?.setCompletionBlockWithSuccess(nil) {
                    operation, _ in
                    let dictionary: [String: Any] = [
                        "request": operation!.request.url!.lastPathComponent
                    ]
                    success?(operation, dictionary)
                }
                return operation
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription!, fromResponseObject responseObject: Any!) -> Any! {
                let dictionary: [String: Any] = [
                    "name": "TEST-ARTIST",
                    "artistDescription": "TEST-DESCRIPTION"
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> String! {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]!, ofEntity entity: NSEntityDescription!, from response: HTTPURLResponse!) -> [AnyHashable : Any]! {
                return representation
            }

        }
        let client = FakeClientSubclass8()
        store.httpClient = client
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        let finishExpectation = expectation(description: "should finish all calls and callbacks")
        finishExpectation.assertForOverFulfill = false
        NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) { [weak self]
            notification in
            guard (notification.userInfo?["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest)?.deletedObjects?.count == 1 else {
                context.perform {
                    context.delete(artist)
                    _ = try? self?.store?.execute(NSSaveChangesRequest(inserted: nil, updated: nil, deleted: [artist], locked: nil), with: context)
                }
                return
            }
            finishExpectation.fulfill()
        }
        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.name = "TEST-ARTIST"
            artist.artistDescription = "TEST-DESCRIPTION"
            _ = try! self.store.execute(NSSaveChangesRequest(inserted: [artist], updated: nil, deleted: nil, locked: nil), with: context)
        }
        wait(for: [finishExpectation], timeout: 10)
    }
    }

}
