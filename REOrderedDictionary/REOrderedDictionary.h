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
 */
@interface REOrderedDictionary<__covariant KeyType, __covariant ObjectType> : NSObject <NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration>

/**
 @return Returns number of key/object pairs.
 */
@property (nonatomic, assign, readonly) NSUInteger count;

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

/**
 @param index The index of requested object.
 @return Object at index. If index out of bounds returns nil.
 @code
 REOrderedDictionary * orderedDictionary = ...;
 id objectAtIndex = orderedDictionary[1];
 @endcode
 */
- (nullable ObjectType) objectAtIndexedSubscript:(NSUInteger) index;

/**
 @param key Nonnull key of requested object.
 @return Object for key. If key not found than returns nil.
 @code
 REOrderedDictionary * orderedDictionary = ...;
 id objectAtIndex = orderedDictionary[@"myKey"];
 @endcode
 */
- (nullable ObjectType) objectForKeyedSubscript:(nonnull id) key;

#pragma mark - Equality

/**
 @brief Compare receiver with another ordered dictionary.
 @note Both dictionaries are equal when:
 - Both have the same number of key/object pairs.
 - Each key/object pair equal and placed at the same index/position.
 @return YES - both ordered dictionaries are equal, otherwise NO.
 */
- (BOOL) isEqualToOrderedDictionary:(nonnull REOrderedDictionary *) orderedDictionary;

/**
 @brief Compare receiver with another NSDictionary.
 @note Both dictionaries are equal when:
 - Both have the same number of key/object pairs.
 - Each key/object pair equal. Ordered index is ignored.
 @return YES - both ordered dictionaries are equal, otherwise NO.
 */
- (BOOL) isEqualToDictionary:(nonnull NSDictionary *) dictionary;

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
 @brief Initialize ordered dictionary instance with NSDictionary with possibility to sort by key.
 @param dictionary The source dictionary with initial keys and object.
 @param keyComparator Optional comparator block. Provide `nil` to ignore sorting.
 */
- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                          usingKeySortBlock:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator;

@end


#pragma mark - REMutableOrderedDictionary

/**
 @brief Thread safe, mutable ordered dictionary.
 */
@interface REMutableOrderedDictionary<KeyType, ObjectType> : REOrderedDictionary<KeyType, ObjectType>

/**
 @brief Sort mutable ordered dictionary by key using comparator function.
 @param keyComparator The comparator function.
 @param context Optional context that uses within comparator function.
 */
- (void) sortUsingKeySortFunction:(nonnull NS_NOESCAPE REOrderedDictionaryKeyComparatorFunction) keyComparator
                          context:(nullable void *) context;

/**
 @brief Sort mutable ordered dictionary by key using comparator block.
 @param keyComparator The comparator block.
 */
- (void) sortUsingKeySortBlock:(nonnull NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator;

/**
 @brief Remove object for key.
 @param key Nonnull key.
 @note Find coresponding pair using key's `isEqual:` method.
 @note Can break sorting order.
 */
- (void) removeObjectForKey:(nonnull KeyType) key;

/**
 @brief Set or remove object for key.
 If key was found than replace coresponding object with nonnull provided object or
   remove pair if provided object is `nil`.
 If key not found than add new key/object pair to the end.
 @param object Nullable object.
 @param key Nonnull key.
 @note Find coresponding pair using key's `isEqual:` method.
 @note Can break sorting order.
 */
- (void) setObject:(nullable ObjectType) object forKey:(nonnull KeyType) key;

/**
 @brief Set or remove object for key.
 Same logic as `setObject:forKey:`, but using subscript syntax.
 If key was found than replace coresponding object with nonnull provided object or
   remove pair if provided object is `nil`.
 If key not found than add new key/object pair to the end.
 @param object Nullable object.
 @param key Nonnull key.
 @note Find coresponding pair using key's `isEqual:` method.
 @note Can break sorting order.
 @code
 REMutableOrderedDictionary * orderedDictionary = ...;
 orderedDictionary[@"myKey"] = @"Initial object";       // set object for key.
 orderedDictionary[@"myKey"] = @"Replacement object";   // reset object for key.
 orderedDictionary[@"myKey"] = nil;                     // remove object for key.
 @endcode
 */
- (void) setObject:(nullable ObjectType) object forKeyedSubscript:(nonnull KeyType) key;

@end


#pragma mark - Extensions

@interface NSDictionary (REOrderedDictionary)

/**
 @return New ordered dictionary instance from NSDictionary.
 @note Contains all keys and objects from source dictionary.
 */
- (nonnull REOrderedDictionary *) orderedCopy;

/**
 @return New mutable ordered dictionary instance from NSDictionary.
 @note Contains all keys and objects from source dictionary.
 */
- (nonnull REMutableOrderedDictionary *) mutableOrderedCopy;

@end
