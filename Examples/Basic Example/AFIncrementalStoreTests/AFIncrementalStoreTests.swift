//
//  AFIncrementalStoreTests.swift
//  AFIncrementalStoreTests
//
//  Created by Alessandro Ranaldi on 25/01/2018.
//

import XCTest
import CoreData

class AFIncrementalStoreTests: XCTestCase {

    private var modelUrl: URL!

    private var model: NSManagedObjectModel!

    private var coordinator: NSPersistentStoreCoordinator!

    private var store: AFIncrementalStore!

    private var errorCreatingBackingStore: Error!
    
    override func setUp() {
        UIApplication.shared.keyWindow?.rootViewController = nil
        super.setUp()
        guard let modelUrl = Bundle(for: AFIncrementalStoreTests.self).url(forResource: "IncrementalStoreExample", withExtension: "momd") else {
            return
        }
        self.modelUrl = modelUrl
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            return
        }
        self.model = model
        let storeType = NSStringFromClass(AFIncrementalStore.self)
        NSPersistentStoreCoordinator.registerStoreClass(AFIncrementalStore.self, forStoreType: storeType)
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            store = try coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: nil) as? AFIncrementalStore
            try store?.backingPersistentStoreCoordinator?.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let e {
            self.errorCreatingBackingStore = e
        }
    }
    
    override func tearDown() {
        _ = try? coordinator.remove(store)
        store.httpClient = nil
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
            _ = AFIncrementalStore.type
        })
    }

    func test_modelShouldThrowException() {
        XCTAssertTrue(blockThrowsException {
            _ = AFIncrementalStore.model
        })
    }

    func test_executeFetchRequestShouldReturnEmptyArray_whenDBAndResponseEmpty() {
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .AFIncrementalStoreContextDidFetchRemoteValues, object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer)
            XCTAssertEqual((notification.userInfo?["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID])?.isEmpty, true)
            testFinishExpectation.fulfill()
        }
        class FakeClientSubclass1: FakeClient {

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }
            
            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }
                
                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                return [String: Any]()
            }

        }
        let fakeClient = FakeClientSubclass1()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var results: [Artist]!
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        context.performAndWait {
            results = try! context.fetch(request)
        }
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnEmptyArray_whenDBNotEmptyAndResponseEmpty() {
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .init("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer)
            XCTAssertEqual((notification.userInfo?["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID])?.isEmpty, true)
            testFinishExpectation.fulfill()
        }
        class FakeClientSubclass2: FakeClient {

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                return [String: Any]()
            }

        }
        let fakeClient = FakeClientSubclass2()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.performAndWait {
            let _ = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            _ = try! context.save()
        }
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        var results: [Artist]!
        context.performAndWait {
            results = try! context.fetch(request)
        }
        XCTAssertNotNil(results)
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnNonEmptyArray_whenDBEmptyAndResponseNotEmpty() {
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .init("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer)
            XCTAssertEqual((notification.userInfo?["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID])?.count, 1)
            testFinishExpectation.fulfill()
        }
        class FakeClientSubclass3: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

        }
        let fakeClient = FakeClientSubclass3()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var results: [Artist]!
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        context.performAndWait {
            results = try! context.fetch(request)
        }
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequestShouldReturnObjects_whenRequestTypeIsManagedObjectResultType() {

    }

    func test_executeFetchRequestShouldReturnIDs_whenRequestTypeIsManagedObjectIDResultType() {
        let testFinishExpectation = expectation(description: "shouldFinishExecutingTest")
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .init("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer)
            XCTAssertEqual((notification.userInfo?["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID])?.count, 1)
            testFinishExpectation.fulfill()
        }
        class FakeClientSubclass4: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return dictionary
            }

        }
        let fakeClient = FakeClientSubclass4()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var results: [NSManagedObjectID]!
        let request = NSFetchRequest<NSManagedObjectID>()
        request.resultType = .managedObjectIDResultType
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        context.performAndWait {
            results = try! context.fetch(request)
        }
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
        wait(for: [testFinishExpectation], timeout: 10)
    }

    func test_executeFetchRequest_shouldNotifyWhenRemoteFetchIsPerformed() {
        let willFetchNotification = expectation(description: "should call will fetch remote values")
        willFetchNotification.assertForOverFulfill = false
        var observer1: NSObjectProtocol!
        observer1 = NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextWillFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer1)
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertFalse(operation.state == .completed)
            XCTAssertFalse(operation.state == .running)
            let request: NSFetchRequest<Artist>! = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSFetchRequest<Artist>
            XCTAssertNotNil(request)
            willFetchNotification.fulfill()
        }
        let didFetchNotification = expectation(description: "should call did fetch remote values")
        didFetchNotification.assertForOverFulfill = false
        var observer2: NSObjectProtocol!
        observer2 = NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer2)
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let ids: [NSManagedObjectID]! = userInfo["AFIncrementalStoreFetchedObjectIDs"] as? [NSManagedObjectID]
            XCTAssertNotNil(ids)
            guard !ids.isEmpty else {
                return
            }
            XCTAssertEqual(ids.count, 1)
            XCTAssertTrue(ids.first!.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.state == .completed)
            let request: NSFetchRequest<Artist>! = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSFetchRequest<Artist>
            XCTAssertNotNil(request)
            didFetchNotification.fulfill()
        }

        class FakeClientSubclass5: FakeClient {

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return entity?.name == "Artist" ? dictionary : nil
            }

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }

            var successClosure: ((URLSessionTask?, Any?) -> Void)!

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }
                
                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

        }
        let fakeClient = FakeClientSubclass5()
        store.httpClient = fakeClient
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<Artist>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
        context.performAndWait {
            _ = try! context.fetch(request)
        }
        wait(for: [willFetchNotification, didFetchNotification], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldNotifyWhenRemoteSaveIsPerformed() {
        let willSaveNotification = expectation(description: "should call will save remote values")
        var observer1: NSObjectProtocol!
        observer1 = NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextWillSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer1)
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertEqual(operations.count, 1)
            XCTAssertFalse(operation.state == .completed)
            XCTAssertFalse(operation.state == .running)
            let request: NSSaveChangesRequest? = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest
            XCTAssertNotNil(request)
            willSaveNotification.fulfill()
        }
        let didSaveNotification = expectation(description: "should call did save remote values")
        var observer2: NSObjectProtocol!
        observer2 = NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer2)
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertEqual(operations.count, 1)
            XCTAssertTrue(operation.state == .completed)
            let request: NSSaveChangesRequest! = userInfo["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest
            XCTAssertNotNil(request)
            let inserts: Set<NSManagedObject>! = request.insertedObjects
            XCTAssertNotNil(inserts)
            let insert: NSManagedObject! = inserts.first
            XCTAssertNotNil(insert)
            XCTAssertTrue(insert.objectID.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            didSaveNotification.fulfill()
        }
        class FakeClientSubclass5: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, "", nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return dictionary
            }

        }
        let client = FakeClientSubclass5()
        store.httpClient = client
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.perform {
            let artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.artistDescription = "TEST-DESCRIPTION"
            artist.name = "TEST-ARTIST"
            _ = try! context.save()
        }
        wait(for: [willSaveNotification, didSaveNotification], timeout: 10)
    }

    func test_newValuesForObjectWithId_shouldSendNotifications() {

        let context: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        var artist: Artist?

        let didSaveRemoteValues = expectation(description: "should send save new values notification")
        didSaveRemoteValues.assertForOverFulfill = false

        var observerSave: NSObjectProtocol!
        observerSave = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observerSave)
            context.perform {
                let node = try! self.store.newValuesForObject(with: artist!.objectID, with: context)
                XCTAssertEqual(node.objectID, artist!.objectID)
                let nameProperty = NSPropertyDescription()
                nameProperty.name = "name"
                XCTAssertEqual(node.value(for: nameProperty) as? String, nil)
                let descriptionProperty = NSPropertyDescription()
                descriptionProperty.name = "artistDescription"
                XCTAssertEqual(node.value(for: descriptionProperty) as? String, nil)
                XCTAssertEqual(node.version, 1)
                didSaveRemoteValues.fulfill()
            }
        }

        let willFetchNewValues = expectation(description: "should send will fetch new values notification")
        willFetchNewValues.assertForOverFulfill = false

        var observer1: NSObjectProtocol!
        observer1 = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextWillFetchNewValuesForObject"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer1)
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            if let operation = operations.first  {
                XCTAssertEqual(operations.count, 1)
                XCTAssertFalse(operation.state == .completed)
                XCTAssertFalse(operation.state == .running)
            }
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            willFetchNewValues.fulfill()
        }

        let didFetchNewValues = expectation(description: "should send did fetch new values notification")
        didFetchNewValues.assertForOverFulfill = false
        var observer2: NSObjectProtocol!
        observer2 = NotificationCenter.default.addObserver(forName: NSNotification.Name("AFIncrementalStoreContextDidFetchNewValuesForObject"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer2)
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.state == .completed)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            didFetchNewValues.fulfill()
        }
        class FakeClientSubclass6: FakeClient {

            func shouldFetchRemoteAttributeValues(forObjectWith objectID: NSManagedObjectID, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST",
                    "songs": [Any]()
                ]
                return entity?.name == "Artist" ? dictionary : nil
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                ]
                return entity?.name == "Artist" ? dictionary : nil
            }

            override func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest {
                return urlRequest
            }

        }
        let fakeClient = FakeClientSubclass6()
        context.persistentStoreCoordinator = coordinator

        store.httpClient = fakeClient

        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            try! context.save()
        }

        wait(for: [didSaveRemoteValues, willFetchNewValues, didFetchNewValues], timeout: 20)
    }

    func test_newValueForRelationship_shouldSendNotifications() {

        let context: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        var artist: Artist?

        let didSaveRemoteValues = expectation(description: "should send save new values notification")
        didSaveRemoteValues.assertForOverFulfill = false

        var observerSave: NSObjectProtocol!
        observerSave = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observerSave)
            context.perform {
                let relationshipDescription = NSEntityDescription.entity(forEntityName: "Artist", in: context)!.relationships(forDestination: NSEntityDescription.entity(forEntityName: "Song", in: context)!).first!
                let destination = try? self.store.newValue(forRelationship: relationshipDescription, forObjectWith: artist!.objectID, with: context)
                let ids: [NSManagedObjectID]! = destination as? [NSManagedObjectID]
                XCTAssertNotNil(ids)
                XCTAssertTrue(ids.isEmpty)
                didSaveRemoteValues.fulfill()
            }
        }

        let willFetchExpectation = expectation(description: "should send will fetch new values for relationship notification")
        willFetchExpectation.assertForOverFulfill = false
        var observer1: NSObjectProtocol!
        observer1 = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextWillFetchNewValuesForRelationship"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer1)
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let relationship: NSRelationshipDescription! = userInfo["AFIncrementalStoreFaultingRelationship"] as? NSRelationshipDescription
            XCTAssertNotNil(relationship)
            XCTAssertTrue((relationship.name == "songs" && relationship.inverseRelationship?.name == "artist") || relationship.name == "artist" && (relationship.inverseRelationship?.name == "songs"))
            XCTAssertTrue((relationship.destinationEntity?.name == "Song" && relationship.inverseRelationship?.destinationEntity?.name == "Artist") || (relationship.destinationEntity?.name == "Artist" && relationship.inverseRelationship?.destinationEntity?.name == "Song"))
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertFalse(operation.state == .completed)
            XCTAssertFalse(operation.state == .running)
            willFetchExpectation.fulfill()
        }
        let didFetchExpectation = expectation(description: "should send will fetch new values for relationship notification")
        didFetchExpectation.assertForOverFulfill = false
        var observer2: NSObjectProtocol!
        observer2 = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidFetchNewValuesForRelationship"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer2)
            let userInfo: [AnyHashable : Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let id: NSManagedObjectID! = userInfo["AFIncrementalStoreFaultingObjectID"] as? NSManagedObjectID
            XCTAssertNotNil(id)
            XCTAssertTrue(id.uriRepresentation().lastPathComponent.contains("TEST-ID"))
            let relationship: NSRelationshipDescription! = userInfo["AFIncrementalStoreFaultingRelationship"] as? NSRelationshipDescription
            XCTAssertNotNil(relationship)
            XCTAssertTrue((relationship.name == "songs" && relationship.inverseRelationship?.name == "artist") || relationship.name == "artist" && (relationship.inverseRelationship?.name == "songs"))
            XCTAssertTrue((relationship.destinationEntity?.name == "Song" && relationship.inverseRelationship?.destinationEntity?.name == "Artist") || (relationship.destinationEntity?.name == "Artist" && relationship.inverseRelationship?.destinationEntity?.name == "Song"))
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertFalse(operations.isEmpty)
            XCTAssertEqual(operations.count, 1)
            let operation: URLSessionTask! = operations.first
            XCTAssertNotNil(operation)
            XCTAssertTrue(operation.state == .completed)
            didFetchExpectation.fulfill()
        }
        class FakeClientSubclass7: FakeClient {

            func shouldFetchRemoteValues(forRelationship relationship: NSRelationshipDescription!, forObjectWith objectID: NSManagedObjectID!, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func shouldFetchRemoteAttributeValues(forObjectWith objectID: NSManagedObjectID, in context: NSManagedObjectContext!) -> Bool {
                return true
            }

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return urlRequest
            }

            override func request(withMethod method: String, pathForRelationship relationship: NSRelationshipDescription?, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = entity?.name == "Artist" ? [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                    ] : [
                        "title": "TEST-SONG"
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                let dictionary: [String: Any] = entity?.name == "Artist" ? [
                    "artistDescription": "TEST-DESCRIPTION",
                    "name": "TEST-ARTIST"
                    ] : [
                        "title": "TEST-SONG"
                ]
                return dictionary
            }

            override func request(withMethod method: String, pathForObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext) -> URLRequest {
                return urlRequest
            }

            override func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any] {
                return [:]
            }

        }
        let client = FakeClientSubclass7()
        context.persistentStoreCoordinator = coordinator

        store.httpClient = client
        context.perform {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            _ = try! context.save()
        }
        wait(for: [didSaveRemoteValues, willFetchExpectation, didFetchExpectation], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldWorkForUpdates() {
        class FakeClientSubclass8: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return URLRequest(url: URL(string: "http://localhost/insert")!)
            }

            func request(forUpdatedObject updatedObject: NSManagedObject!) -> URLRequest? {
                return URLRequest(url: URL(string: "http://localhost/update")!)
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    let dictionary: [String: Any] = [
                        "request": operation?.currentRequest!.url!.lastPathComponent as Any
                    ]
                    completionHandler?(urlResponse, dictionary, nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
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

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                return representation as? [String: Any]
            }

        }
        let client = FakeClientSubclass8()
        store.httpClient = client
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        let finishExpectation = expectation(description: "should finish all calls and callbacks")
        finishExpectation.assertForOverFulfill = false
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            let saveRequest = notification.userInfo?["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest
            guard saveRequest?.updatedObjects?.count == 1 else {
                if saveRequest?.insertedObjects?.count == 1 {
                    context.performAndWait {
                        artist.name = "TEST-ARTIST-EDITED"
                        _ = try! context.save()
                    }
                }
                return
            }
            NotificationCenter.default.removeObserver(observer)
            finishExpectation.fulfill()
        }
        context.performAndWait {
            artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.name = "TEST-ARTIST"
            artist.artistDescription = "TEST-DESCRIPTION"
            _ = try! context.save()
        }
        wait(for: [finishExpectation], timeout: 10)
    }

    func test_executeSaveChangesRequest_shouldWorkForDeletions() {
        class FakeClientSubclass8: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return URLRequest(url: URL(string: "http://localhost/insert")!)
            }

            func request(forDeletedObject updatedObject: NSManagedObject!) -> URLRequest? {
                return URLRequest(url: URL(string: "http://localhost/delete")!)
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    let dictionary: [String: Any] = [
                        "request": operation?.currentRequest!.url!.lastPathComponent as Any
                    ]
                    completionHandler?(urlResponse, dictionary, nil)
                }

                return operation as! URLSessionDataTask
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                let dictionary: [String: Any] = [
                    "name": "TEST-ARTIST",
                    "artistDescription": "TEST-DESCRIPTION"
                ]
                return dictionary
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return "TEST-ID"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                return representation as? [String: Any]
            }

        }
        let client = FakeClientSubclass8()
        store.httpClient = client
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var artist: Artist!
        let finishExpectation = expectation(description: "should finish all calls and callbacks")
        finishExpectation.assertForOverFulfill = false
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            guard (notification.userInfo?["AFIncrementalStorePersistentStoreRequest"] as? NSSaveChangesRequest)?.deletedObjects?.count == 1 else {
                context.perform {
                    context.delete(artist)
                    _ = try! context.save()
                }
                return
            }
            NotificationCenter.default.removeObserver(observer)
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

    func test_executeSaveChangesRequest_worksWithoutAPIRequest() {
        let willSaveNotification = expectation(description: "should send will save notification")
        var observer1: NSObjectProtocol!
        observer1 = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextWillSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer1)
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertTrue(operations.isEmpty)
            willSaveNotification.fulfill()
        }
        let didSaveNotification = expectation(description: "should send did save notification")
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var observer2: NSObjectProtocol!
        observer2 = NotificationCenter.default.addObserver(forName: Notification.Name("AFIncrementalStoreContextDidSaveRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer2)
            let userInfo: [AnyHashable: Any]! = notification.userInfo
            XCTAssertNotNil(userInfo)
            let operations: [URLSessionTask]! = userInfo["AFIncrementalStoreRequestOperations"] as? [URLSessionTask]
            XCTAssertNotNil(operations)
            XCTAssertTrue(operations.isEmpty)
            context.performAndWait {
                let request = NSFetchRequest<Artist>(entityName: "Artist")
                request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
                let count = try! context.count(for: request)
                XCTAssertEqual(count, 1)
            }
            didSaveNotification.fulfill()
        }
        class FakeClientSubclass9: FakeClient {

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return nil
            }

        }
        let client = FakeClientSubclass9()
        store.httpClient = client
        context.perform {
            let artist = Artist(entity: NSEntityDescription.entity(forEntityName: "Artist", in: context)!, insertInto: context)
            artist.name = "TEST-ARTIST"
            artist.artistDescription = "ARTIST-DESCRIPTION"
            _ = try! context.save()
        }
        wait(for: [willSaveNotification, didSaveNotification], timeout: 10)
    }

    func test_insertOrUpdateObjectsFromRepresentations_includesRelationships() {
        class FakeClientSubclass10: FakeClient {

            override func request(for fetchRequest: NSFetchRequest<NSFetchRequestResult>?, with context: NSManagedObjectContext?) -> URLRequest? {
                return urlRequest
            }

            func request(forInsertedObject insertedObject: NSManagedObject!) -> URLRequest? {
                return urlRequest
            }

            override func dataTask(with request: URLRequest, uploadProgress uploadProgressBlock: ((Progress) -> Void)?, downloadProgress downloadProgressBlock: ((Progress) -> Void)?, completionHandler: ((URLResponse, Any?, Error?) -> Void)? = nil) -> URLSessionDataTask {
                var operation: URLSessionTask?
                operation = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let urlResponse: HTTPURLResponse = HTTPURLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

                    completionHandler?(urlResponse, [String: Any](), nil)
                }

                return operation as! URLSessionDataTask
            }

            override func resourceIdentifier(forRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> String? {
                return entity?.name == "Artist" ? "TEST-ID" : "TEST-ID-SONG"
            }

            override func attributes(forRepresentation representation: [AnyHashable : Any]?, ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any]? {
                return entity?.name == "Artist" ? [
                    "name": "TEST-ARTIST",
                    "artistDescription": "TEST-DESCRIPTION"
                    ] : ["title": "TEST-SONG"]
            }

            override func representationOrArrayOfRepresentations(ofEntity entity: NSEntityDescription?, fromResponseObject responseObject: Any?) -> Any? {
                if entity?.name == "Artist" {
                    let dictionary: [String: Any] = [
                        "name": "TEST-ARTIST",
                        "artistDescription": "TEST-DESCRIPTION"
                    ]
                    return dictionary
                }
                let dictionary: [String: Any] = ["title": "TEST-SONG"]
                return dictionary
            }

            override func representationsForRelationships(fromRepresentation representation: [AnyHashable : Any], ofEntity entity: NSEntityDescription?, from response: HTTPURLResponse?) -> [String : Any] {
                if entity?.name == "Artist" {
                    let songs: [[String: Any]] = [["title": "TEST-SONG"]]
                    return ["songs": songs]
                } else {
                    return [:]
                }
            }

        }
        let finishExpectation = expectation(description: "should finish remote fetch")
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .init("AFIncrementalStoreContextDidFetchRemoteValues"), object: nil, queue: .main) {
            notification in
            NotificationCenter.default.removeObserver(observer)
            // TODO: add checks
            finishExpectation.fulfill()
        }
        store.httpClient = FakeClientSubclass10()
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.perform {
            let request: NSFetchRequest<Artist> = NSFetchRequest.init(entityName: "Artist")
            request.entity = NSEntityDescription.entity(forEntityName: "Artist", in: context)
            let results = try? context.fetch(request)
            XCTAssertNotNil(results)
            XCTAssertTrue(results!.isEmpty)
        }
        wait(for: [finishExpectation], timeout: 10)
    }

}
