/*
 *   Copyright (c) 2017 Kulykov Oleh <info@resident.name>
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *   THE SOFTWARE.
 */


#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * _Nonnull const NSOrderedDictionaryCoderKeyKeys;

FOUNDATION_EXPORT NSString * _Nonnull const NSOrderedDictionaryCoderKeyObjects;

typedef NSInteger (^NSOrderedDictionaryKeyComparatorBlock)(id _Nullable, id _Nullable);

typedef NSInteger (*NSOrderedDictionaryKeyComparatorFunction)(id _Nullable, id _Nullable, void * _Nullable);

@interface NSOrderedDictionary<__covariant KeyType, __covariant ObjectType> : NSObject <NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration>

@property (nonatomic, assign, readonly) NSUInteger count;

- (nonnull instancetype) init NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype) initWithObjectsAndKeys:(nullable id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;

- (nonnull instancetype) initWithObjects:(nonnull NSArray<ObjectType> *) allObjects
                                 andKeys:(nonnull NSArray<KeyType> *) allKeys;

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                       usingKeySortFunction:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorFunction) keyComparator
                                    context:(nullable void *) context;

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                          usingKeySortBlock:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorBlock) keyComparator;

#pragma mark - All keys and values

- (nonnull NSArray<KeyType> *) allKeys;

- (nonnull NSArray<ObjectType> *) allObjects;

#pragma mark - Subscripts

- (nullable ObjectType) objectAtIndexedSubscript:(NSUInteger) index;

- (nullable ObjectType) objectForKeyedSubscript:(nonnull id) key;

#pragma mark - Equality

- (BOOL) isEqualToOrderedDictionary:(nonnull NSOrderedDictionary *) orderedDictionary;

- (BOOL) isEqualToDictionary:(nonnull NSDictionary *) dictionary;

@end

#pragma mark - NSMutableOrderedDictionary

@interface NSMutableOrderedDictionary<KeyType, ObjectType> : NSOrderedDictionary<KeyType, ObjectType>

- (void) sortUsingKeySortFunction:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorFunction) keyComparator
                          context:(nullable void *) context;

- (void) sortUsingKeySortBlock:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorBlock) keyComparator;

- (void) removeObjectForKey:(nonnull KeyType) key;

/**
 @note If `key` not exists yet, than new object will be added at the end. Can break sorting order.
 */
- (void) setObject:(nullable ObjectType) object forKey:(nonnull KeyType) key;

/**
 @note If `key` not exists yet, than new object will be added at the end. Can break sorting order.
 */
- (void) setObject:(nullable ObjectType) object forKeyedSubscript:(nonnull KeyType) key;

- (void) insertObject:(nullable ObjectType) object forKey:(nonnull KeyType) key atIndex:(NSUInteger) index;

@end


#pragma mark - Extensions

@interface NSDictionary (NSOrderedDictionary)

- (nonnull NSOrderedDictionary *) orderedCopy;

- (nonnull NSMutableOrderedDictionary *) mutableOrderedCopy;

@end
