//
//  ObjCAssertWrapper.h
//  AFIncrementalStoreTests
//
//  Created by Alessandro Ranaldi on 25/01/2018.
//

#import <Foundation/Foundation.h>

typedef void (^VoidBlock)(void);

/// Returns: true if the block throws an `NSException`, otherwise false
BOOL blockThrowsException(VoidBlock block);
