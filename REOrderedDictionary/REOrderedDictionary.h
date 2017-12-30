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

/**
 @brief Coder/decoder key for sorted keys array.
 @note Each key at position conforms to value at same position.
 */
FOUNDATION_EXPORT NSString * _Nonnull const REOrderedDictionaryCoderKeyKeys;

/**
 @brief Coder/decoder key for sorted objects array.
 @note Each value at position conforms to key at same position.
 */
FOUNDATION_EXPORT NSString * _Nonnull const REOrderedDictionaryCoderKeyObjects;

/**
 @brief Key comparator block type for dictionary sorting methods.
 @return `NSOrderedAscending` if left key is smaller than the right key, otherwise any value.
 */
typedef NSInteger (^REOrderedDictionaryKeyComparatorBlock)(id _Nullable, id _Nullable);

/**
 @brief Key comparator function callback for dictionary sorting methods.
 @return `NSOrderedAscending` if left key is smaller than the right key, otherwise any value.
 @note Using comparator function you can provide any context.
 */
typedef NSInteger (*REOrderedDictionaryKeyComparatorFunction)(id _Nullable, id _Nullable, void * _Nullable);

/**
 @brief Key/object container that stores ordered key/object pairs by key.
 @note Order can be defined by adding/inserting order or using sort methods.
 */
@interface REOrderedDictionary<__covariant KeyType, __covariant ObjectType> : NSObject <NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration>

/**
 @return Returns number of key/object pairs.
 */
@property (nonatomic, assign, readonly) NSUInteger count;

/**
 @brief Initialize empty ordered dictionary instance.
 */
- (nonnull instancetype) init NS_DESIGNATED_INITIALIZER;

/**
 @brief Initialize ordered dictionary instance with initial object/key values.
 @param firstObject The first nullable object argument.
 @note Provide `nil` at the end of object/key values.
 @code
 [[REOrderedDictionary alloc] initWithObjectsAndKeys:@"some object", @(0), nil];
 @endcode
 */
- (nonnull instancetype) initWithObjectsAndKeys:(nullable id) firstObject, ... NS_REQUIRES_NIL_TERMINATION;

/**
 @brief Initialize ordered dictionary instance with initial arrays of objects and keys.
 @code
 [[REOrderedDictionary alloc] initWithObjects:@[ @"some object" ] andKeys:@[ @(0) ]];
 @endcode
 */
- (nonnull instancetype) initWithObjects:(nonnull NSArray<ObjectType> *) allObjects
                                 andKeys:(nonnull NSArray<KeyType> *) allKeys;

/**
 @brief Initialize ordered dictionary instance with NS dictionary with possibility to sort by key.
 @param dictionary The source dictionary with initial keys and object.
 @param keyComparator Optional comparator function. Provide `nil` to ignore sorting.
 @param context Optional context for comparator function, of course if comparator exists.
 */
- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                       usingKeySortFunction:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorFunction) keyComparator
                                    context:(nullable void *) context;

/**
 @brief Initialize ordered dictionary instance with NS dictionary with possibility to sort by key.
 @param dictionary The source dictionary with initial keys and object.
 @param keyComparator Optional comparator block. Provide `nil` to ignore sorting.
 */
- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                          usingKeySortBlock:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator;

#pragma mark - All keys and values

/**
 @return Array with all keys.
 @note Each key at position conforms to object at position returned by `allObjects` method.
 */
- (nonnull NSArray<KeyType> *) allKeys;

/**
 @return Array with all objects.
 @note Each object at position conforms to key at position returned by `allKeys` method.
 */
- (nonnull NSArray<ObjectType> *) allObjects;

#pragma mark - Subscripts

- (nullable ObjectType) objectAtIndexedSubscript:(NSUInteger) index;

- (nullable ObjectType) objectForKeyedSubscript:(nonnull id) key;

#pragma mark - Equality

- (BOOL) isEqualToOrderedDictionary:(nonnull REOrderedDictionary *) orderedDictionary;

- (BOOL) isEqualToDictionary:(nonnull NSDictionary *) dictionary;

@end

#pragma mark - NSMutableOrderedDictionary

@interface NSMutableOrderedDictionary<KeyType, ObjectType> : REOrderedDictionary<KeyType, ObjectType>

- (void) sortUsingKeySortFunction:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorFunction) keyComparator
                          context:(nullable void *) context;

- (void) sortUsingKeySortBlock:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator;

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

@interface NSDictionary (REOrderedDictionary)

- (nonnull REOrderedDictionary *) orderedCopy;

- (nonnull NSMutableOrderedDictionary *) mutableOrderedCopy;

@end
