//
//  NSOrderedDictionary_iOSTests.m
//  NSOrderedDictionary-iOSTests
//
//  Created by Oleh Kulykov on 23.11.17.
//

#import <XCTest/XCTest.h>
#import "NSOrderedDictionary.h"

@interface NSOrderedDictionary_iOSTests : XCTestCase

@end

@implementation NSOrderedDictionary_iOSTests

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testCodingDecoding {
    NSOrderedDictionary * d1 = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), @"#1", @(1), nil];
    NSMutableData * data = [[NSMutableData alloc] init];
    NSKeyedArchiver * coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [d1 encodeWithCoder:coder];
    [coder finishEncoding];
    NSKeyedUnarchiver * decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSOrderedDictionary * d2 = [[NSOrderedDictionary alloc] initWithCoder:decoder];
    XCTAssertNotNil(d1);
    XCTAssertNotNil(d2);
    XCTAssertTrue(d2.count == d1.count);
    XCTAssertTrue([d2 isKindOfClass:[NSOrderedDictionary class]]);
    d1 = nil;
    d2 = nil;
}

- (void) testMutableCopy {
    NSOrderedDictionary * d1 = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), nil];
    NSMutableOrderedDictionary * d2 = [d1 mutableCopy];
    XCTAssertNotNil(d1);
    XCTAssertNotNil(d2);
    XCTAssertTrue(d2.count == d1.count);
    XCTAssertTrue([d2 isKindOfClass:[NSMutableOrderedDictionary class]]);
    d1 = nil;
    d2 = nil;
}

- (void) testCopy {
    NSOrderedDictionary * d1 = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), nil];
    NSOrderedDictionary * d2 = [d1 copy];
    XCTAssertNotNil(d1);
    XCTAssertNotNil(d2);
    XCTAssertTrue(d2.count == d1.count);
    d1 = nil;
    d2 = nil;
}

static NSInteger compareNumberKeys1(NSNumber * k1, NSNumber * k2, void * _Nullable context) {
    return [k1 compare:k2];
}

- (void) testCreation {
    NSOrderedDictionary * d = [[NSOrderedDictionary alloc] init];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:nil];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", nil];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), nil];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 1);
    
    d = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), @"#1", @(1), nil];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 2);
    
    d = [[NSOrderedDictionary alloc] initWithObjectsAndKeys:@"#0", @(0), @"#1", @(1), @"2", nil];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 2);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[] andKeys:@[]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[ @"#0" ] andKeys:@[]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[ @"#0" ] andKeys:@[ @(0) ]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 1);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[ @"#0", @"#1" ] andKeys:@[ @(0) ]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 1);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[ @"#0", @"#1" ] andKeys:@[ ]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 0);
    
    d = [[NSOrderedDictionary alloc] initWithObjects:@[ @"#0", @"#1" ] andKeys:@[ @(0), @(1) ]];
    XCTAssertNotNil(d);
    XCTAssertTrue(d.count == 2);
    
    d = [[NSOrderedDictionary alloc] initWithDictionary:@{ @(1) : @"#1",
                                                           @(9) : @"#9",
                                                           @(0) : @"#0",
                                                           @(7) : @"#7" }
                                   usingKeySortFunction:compareNumberKeys1
                                                context:NULL];
    NSLog(@"%@", d);
    
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:@{ @(1) : @"#1",
                                                                  @(9) : @"#9",
                                                                  @(0) : @"#0",
                                                                  @(7) : @"#7" }
                                          usingKeySortFunction:nil
                                                       context:NULL];
    NSLog(@"Before sort: %@", d);
    [(NSMutableOrderedDictionary *)d sortUsingKeySortFunction:compareNumberKeys1
                                                      context:NULL];
    NSLog(@"After sort: %@", d);
    
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:@{ @(1) : @"#1",
                                                                  @(9) : @"#9",
                                                                  @(0) : @"#0",
                                                                  @(7) : @"#7" }
                                             usingKeySortBlock:^NSInteger(NSNumber * _Nullable n1, NSNumber * _Nullable n2) {
                                                 return [n1 compare:n2];
                                             }];
    NSLog(@"%@", d);
 
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:@{ @(1) : @"#1",
                                                                  @(9) : @"#9",
                                                                  @(0) : @"#0",
                                                                  @(7) : @"#7" }
                                          usingKeySortFunction:nil
                                                       context:NULL];
    NSLog(@"Before sort: %@", d);
    [(NSMutableOrderedDictionary *)d sortUsingKeySortBlock:^NSInteger(NSNumber * _Nullable n1, NSNumber * _Nullable n2) {
        return [n1 compare:n2];
    }];
    NSLog(@"After sort: %@", d);
    
    
    NSLog(@"Start enumerate keys");
    for (NSString * key in d) {
        NSLog(@"Key: %@", key);
    }
    
    id obj = d[0];
    NSLog(@"Obj: %@", obj);
    obj = d[@(0)];
    NSLog(@"Obj: %@", obj);
    obj = d[1];
    NSLog(@"Obj: %@", obj);
    obj = d[@(1)];
    NSLog(@"Obj: %@", obj);
    obj = d[3];
    NSLog(@"Obj: %@", obj);
    
    obj = d[22];
    NSLog(@"Obj: %@", obj);
    obj = d[@(22)];
    NSLog(@"Obj: %@", obj);
}

@end
