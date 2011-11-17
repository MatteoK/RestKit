//
//  RKObjectRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKSpecEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKSpecUser.h"

@interface RKSpecObject : NSObject
@end
@implementation RKSpecObject
+ (id)object {
    return [[self new] autorelease];
}
@end

@interface RKSpecSubclassedObject : RKSpecObject
@end
@implementation RKSpecSubclassedObject
@end

@interface RKObjectRouterSpec : RKSpec {
}

@end

@implementation RKSpecUser (PolymorphicResourcePath)

- (NSString *)polymorphicResourcePath {
    return @"/this/is/the/path";
}

@end

@implementation RKObjectRouterSpec

-(void)itShouldThrowAnExceptionWhenAskedForAPathForAnUnregisteredClassAndMethod {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    NSException* exception = nil;
    @try {
        [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodPOST];
    }
    @catch (NSException * e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

-(void)itShouldThrowAnExceptionWhenAskedForAPathForARegisteredClassButUnregisteredMethod {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSException* exception = nil;
    @try {
        [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodPOST];
    }
    @catch (NSException * e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

-(void)itShouldReturnPathsRegisteredForSpecificRequestMethods {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSString* path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

-(void)itShouldReturnPathsRegisteredForTheClassAsAWhole {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
    NSString* path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldReturnPathsIfTheSuperclassIsRegistered {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
    NSString* path = [router resourcePathForObject:[RKSpecSubclassedObject new] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

- (void)testShouldFavorExactMatcherOverSuperclassMatches {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[RKSpecSubclassedObject class] toResourcePath:@"/SubclassedHumanService.asp"];
    NSString* path = [router resourcePathForObject:[RKSpecSubclassedObject new] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/SubclassedHumanService.asp")));
    path = [router resourcePathForObject:[RKSpecObject new] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
}

-(void)itShouldFavorSpecificMethodsWhenClassAndSpecificMethodsAreRegistered {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp"];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanServiceForPUT.asp" forMethod:RKRequestMethodPUT];
    NSString* path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodGET];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodPOST];
    assertThat(path, is(equalTo(@"/HumanService.asp")));
    path = [router resourcePathForObject:[RKSpecObject object] method:RKRequestMethodPUT];
    assertThat(path, is(equalTo(@"/HumanServiceForPUT.asp")));
}

-(void)itShouldRaiseAnExceptionWhenAttemptIsMadeToRegisterOverAnExistingRoute {
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecObject class] toResourcePath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    NSException* exception = nil;
    @try {
        [router routeClass:[RKSpecObject class] toResourcePathPattern:@"/HumanService.asp" forMethod:RKRequestMethodGET];
    }
    @catch (NSException * e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMapping {
    RKSpecUser* blake = [RKSpecUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecUser class] toResourcePathPattern:@"/humans/:userID/:name" forMethod:RKRequestMethodGET];
    
    NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldInterpolatePropertyNamesReferencedInTheMappingWithDeprecatedParentheses {
    RKSpecUser* blake = [RKSpecUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecUser class] toResourcePathPattern:@"/humans/(userID)/(name)" forMethod:RKRequestMethodGET];
    
    NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/humans/31337/blake")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCalls {
    RKSpecUser* blake = [RKSpecUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecUser class] toResourcePathPattern:@":polymorphicResourcePath" forMethod:RKRequestMethodGET escapeRoutedPath:NO];
    
    NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

- (void)testShouldAllowForPolymorphicURLsViaMethodCallsWithDeprecatedParentheses {
    RKSpecUser* blake = [RKSpecUser user];
    blake.name = @"blake";
    blake.userID = [NSNumber numberWithInt:31337];
    RKObjectRouter* router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKSpecUser class] toResourcePathPattern:@"(polymorphicResourcePath)" forMethod:RKRequestMethodGET escapeRoutedPath:NO];
    
    NSString* resourcePath = [router resourcePathForObject:blake method:RKRequestMethodGET];
    assertThat(resourcePath, is(equalTo(@"/this/is/the/path")));
}

@end
