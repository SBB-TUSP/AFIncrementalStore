# AFIncrementalStore
**Core Data Persistence with AFNetworking, Done Right**

AFIncrementalStore is an [`NSIncrementalStore`](http://nshipster.com/nsincrementalstore/) subclass that uses [AFNetworking](https://github.com/afnetworking/afnetworking) to automatically request resources as properties and relationships are needed.

Weighing in at just a few hundred LOC, in a single `{.swift}` file pair, AFIncrementalStore is something you can get your head around. Integrating it into your project couldn't be easier--just swap out your `NSPersistentStore` for it. No monkey-patching, no extra properties on your models.

> That said, unless you're pretty confident in your Core Data jitsu, you'll probably be much better off rolling your own simple [NSCoding / NSKeyedArchiver](http://nshipster.com/nscoding/)-based solution (at least to start off).

## Incremental Store Persistence

`AFIncrementalStore` does not persist data directly. Instead, _it manages a persistent store coordinator_ that can be configured to communicate with any number of persistent stores of your choice.

In the Twitter example, a SQLite persistent store is added, which works to persist tweets between launches, and return locally-cached results while the network request finishes:

``` objective-c
NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Twitter.sqlite"];
NSDictionary *options = @{ NSInferMappingModelAutomaticallyOption : @(YES) };

NSError *error = nil;
if (![incrementalStore.backingPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
abort();
}
```

If your data set is of a more fixed or ephemeral nature, you may want to use `NSInMemoryStoreType`.

## Mapping Core Data to HTTP

The only thing you need to do is tell `AFIncrementalStore` how to map Core Data to an HTTP client. These methods are defined in the `AFIncrementalStoreHTTPClient` protocol:

> Don't worry if this looks like a lot of work--if your web service is RESTful, `AFRESTClient` does a lot of the heavy lifting for you. If your target web service is SOAP, RPC, or kinda ad-hoc, you can easily use these protocol methods to get everything hooked up.

```objective-c

@required

- (id)representationOrArrayOfRepresentationsOfEntity:(NSEntityDescription *)entity
fromResponseObject:(id)responseObject;

- (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation
ofEntity:(NSEntityDescription *)entity
fromResponse:(NSHTTPURLResponse *)response;

- (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation
ofEntity:(NSEntityDescription *)entity
fromResponse:(NSHTTPURLResponse *)response;

- (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation
ofEntity:(NSEntityDescription *)entity
fromResponse:(NSHTTPURLResponse *)response;

- (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
withContext:(NSManagedObjectContext *)context;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
pathForObjectWithID:(NSManagedObjectID *)objectID
withContext:(NSManagedObjectContext *)context;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
pathForRelationship:(NSRelationshipDescription *)relationship
forObjectWithID:(NSManagedObjectID *)objectID
withContext:(NSManagedObjectContext *)context;

@optional

- (NSDictionary *)representationOfAttributes:(NSDictionary *)attributes
ofManagedObject:(NSManagedObject *)managedObject;

- (NSMutableURLRequest *)requestForInsertedObject:(NSManagedObject *)insertedObject;

- (NSMutableURLRequest *)requestForUpdatedObject:(NSManagedObject *)updatedObject;

- (NSMutableURLRequest *)requestForDeletedObject:(NSManagedObject *)deletedObject;

- (BOOL)shouldFetchRemoteAttributeValuesForObjectWithID:(NSManagedObjectID *)objectID
inManagedObjectContext:(NSManagedObjectContext *)context;

- (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
forObjectWithID:(NSManagedObjectID *)objectID
inManagedObjectContext:(NSManagedObjectContext *)context;
```

## Getting Started

Check out the example projects that are included in the repository. They are somewhat simple demonstration of an app that uses Core Data with `AFIncrementalStore` to communicate with an API for faulted properties and relationships. Note that there are no explicit network requests being made in the app--it's all done automatically by Core Data.

Also, don't forget to pull down AFNetworking with `git submodule update --init` if you want to run the example.

## Requirements

AFIncrementalStore requires Xcode 4.4 with either the [iOS 8.0](https://developer.apple.com/library/content/releasenotes/General/WhatsNewIniOS/Articles/iOS8.html) or [Mac OS 10.9](https://developer.apple.com/library/content/releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_9.html#//apple_ref/doc/uid/TP40013207-CH100) ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) SDK, as well as [AFNetworking](https://github.com/afnetworking/afnetworking) 3.2.0 or higher.

## Installation

[CocoaPods](http://cocoapods.org) is the recommended way to add AFIncrementalStore to your project.

Here's an example podfile that installs AFIncrementalStore and its dependency, AFNetworking:

### Podfile

```ruby
platform :ios, '8.0'

pod 'AFIncrementalStore', :git => 'https://github.com/SBB-TUSP/AFIncrementalStore.git'
```

## References

Apple has recently updated their programming guide for `NSIncrementalStore`, which is [available from the Developer Center](https://developer.apple.com/library/prerelease/ios/documentation/DataManagement/Conceptual/IncrementalStorePG/ImplementationStrategy/ImplementationStrategy.html). You may find this useful in debugging the behavior of `AFIncrementalStore`, and its interactions with your app's Core Data stack.

## Credits

AFIncrementalStore was created by [Mattt Thompson](https://github.com/mattt/).

## Contact

Follow AFNetworking on Twitter ([@AFNetworking](https://twitter.com/AFNetworking))

### Creators

[Mattt Thompson](http://github.com/mattt)
[@mattt](https://twitter.com/mattt)

#### Swift translation and AFNetworking/Alamofire 3 update:

[Alessandro Ranaldi](https://github.com/Ciaolo)
[Ignazio Altomare](https://github.com/Boom2112)

## License

AFIncrementalStore and AFNetworking are available under the MIT license. See the LICENSE file for more info.
