//
//  ObjCAssertWrapper.m
//  AFIncrementalStoreTests
//
//  Created by Alessandro Ranaldi on 25/01/2018.
//

#import "ObjCAssertWrapper.h"

BOOL throwsToBool(VoidBlock const block) {
    @try {
        block();
    }
    @catch (NSException * const notUsed) {
        return YES;
    }
    return NO;
}
