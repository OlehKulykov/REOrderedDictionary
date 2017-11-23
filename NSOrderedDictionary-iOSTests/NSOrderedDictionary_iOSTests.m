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

static NSInteger compareNumberKeys1(NSNumber * k1, NSNumber * k2, void * _Nullable context) {
    return [k1 compare:k2];
}

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (BOOL) isSortedByNumberKeys:(NSOrderedDictionary *) dict {
    NSNumber * lastKey = nil;
    for (NSNumber * key in dict) {
        XCTAssertTrue([key isKindOfClass:[NSNumber class]]);
        if (lastKey) {
            if ([lastKey compare:key] == NSOrderedDescending) {
                return NO;
            }
        }
        lastKey = key;
    }
    return YES;
}

- (void) testInsert {
    NSMutableOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] init];
    [d insertObject:@"#0" forKey:@(0) atIndex:0];
    [d insertObject:@"#1" forKey:@(1) atIndex:1];
    [d insertObject:@"#-1" forKey:@(-1) atIndex:0];
    NSLog(@"%@", d);
}

- (void) testWritableSubscripts {
    NSMutableOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] init];
    
    XCTAssertNil(d[@(1)]);
    d[@(1)] = @"#1";
    XCTAssertNotNil(d[@(1)]);
    XCTAssertTrue([ d[@(1)] isEqualToString:@"#1"]);
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    
    XCTAssertNil(d[@(0)]);
    d[@(0)] = @"#0";
    XCTAssertNotNil(d[@(0)]);
    XCTAssertTrue([ d[@(0)] isEqualToString:@"#0"]);
    XCTAssertFalse([self isSortedByNumberKeys:d]);
}

- (void) testReadableSubscripts {
    NSDictionary * unsortedDict = @{ @(2) : @"#2",
                                     @(8) : @"#8",
                                     @(4) : @"#4",
                                     @(1) : @"#1",
                                     };
    NSMutableOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                                                       usingKeySortFunction:compareNumberKeys1
                                                                                    context:NULL];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    XCTAssertTrue([d[0] isEqual:@"#1"]);
    XCTAssertTrue([d[1] isEqual:@"#2"]);
    XCTAssertTrue([d[2] isEqual:@"#4"]);
    XCTAssertTrue([d[3] isEqual:@"#8"]);
    
    XCTAssertNil(d[4]);
    XCTAssertNil(d[4345]);
    
    XCTAssertTrue([d[@(1)] isEqual:@"#1"]);
    XCTAssertTrue([d[@(2)] isEqual:@"#2"]);
    XCTAssertTrue([d[@(4)] isEqual:@"#4"]);
    XCTAssertTrue([d[@(8)] isEqual:@"#8"]);
    
    XCTAssertNil(d[@"asdasd"]);
    XCTAssertNil(d[@""]);
    XCTAssertTrue(d.count == 4);
}

- (void) testForEachKey {
    NSDictionary * unsortedDict = @{ @(2) : @"#2",
                                     @(8) : @"#8",
                                     @(4) : @"#4",
                                     @(1) : @"#1",
                                     };
    NSMutableOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                                                       usingKeySortFunction:compareNumberKeys1
                                                                                    context:NULL];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    NSUInteger index = 0;
    for (NSNumber * key in d) {
        switch (index) {
            case 0:
                XCTAssertTrue([key isEqual:@(1)]);
                break;
            case 1:
                XCTAssertTrue([key isEqual:@(2)]);
                break;
            case 2:
                XCTAssertTrue([key isEqual:@(4)]);
                break;
            case 3:
                XCTAssertTrue([key isEqual:@(8)]);
                break;
            default:
                break;
        }
        index++;
    }
    XCTAssertTrue(index == 4); // 4 keys
    XCTAssertTrue(d.count == 4); // 4 keys
}

- (void) testSortByKeys {
    XCTAssertTrue([self isSortedByNumberKeys:[[NSMutableOrderedDictionary alloc] init]]);
    
    NSDictionary * unsortedDict = @{ @(2) : @"#2",
                                     @(8) : @"#8",
                                     @(4) : @"#4",
                                     @(1) : @"#1",
                                     };
    NSMutableOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                                                       usingKeySortFunction:compareNumberKeys1
                                                                                    context:NULL];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                          usingKeySortFunction:nil
                                                       context:NULL];
    [(NSMutableOrderedDictionary *)d sortUsingKeySortFunction:compareNumberKeys1
                                                      context:NULL];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    
    
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                             usingKeySortBlock:^NSInteger(NSNumber * _Nullable n1, NSNumber * _Nullable n2) {
                                                 return [n1 compare:n2];
                                             }];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
    
    d = [[NSMutableOrderedDictionary alloc] initWithDictionary:unsortedDict
                                          usingKeySortFunction:nil
                                                       context:NULL];
    [(NSMutableOrderedDictionary *)d sortUsingKeySortBlock:^NSInteger(NSNumber * _Nullable n1, NSNumber * _Nullable n2) {
        return [n1 compare:n2];
    }];
    XCTAssertTrue([self isSortedByNumberKeys:d]);
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
    
    NSLog(@"%@", d);
}

@end
