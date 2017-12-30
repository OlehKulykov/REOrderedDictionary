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


#import "REOrderedDictionary.h"

#include <algorithm>    // std::sort
#include <vector>       // std::vector
#include <pthread.h>

class REOrderedDictionaryPair {
public:
    CFTypeRef key, obj;
    
    void resetObj(id _Nonnull o) {
#if defined(_DEBUG) || defined(DEBUG)
        assert(obj != nil);
#endif
        CFBridgingRelease(obj);
        obj = CFBridgingRetain(o);
    }
    
    void set(id _Nonnull k, id _Nonnull o) {
        key = CFBridgingRetain(k);
        obj = CFBridgingRetain(o);
    }
    
    REOrderedDictionaryPair() : key(NULL), obj(NULL) { }
    
    ~REOrderedDictionaryPair() {
        CFBridgingRelease(key);
        CFBridgingRelease(obj);
    }
};

typedef std::shared_ptr<REOrderedDictionaryPair> REOrderedDictionaryPairPtr;
typedef std::vector<REOrderedDictionaryPairPtr> REOrderedDictionaryPairList;

struct REOrderedDictionaryKeySortFunctorWithCallback {
    void * context;
    REOrderedDictionaryKeyComparatorFunction comparator;
    // copy srared ptr.
    bool operator()(const REOrderedDictionaryPairPtr a, const REOrderedDictionaryPairPtr b) {
        return (comparator((__bridge id)a->key, (__bridge id)b->key, context) == NSOrderedAscending);
    }
};

struct REOrderedDictionaryKeySortFunctorWithBlock {
    REOrderedDictionaryKeyComparatorBlock comparator;
    // copy srared ptr.
    bool operator()(const REOrderedDictionaryPairPtr a, const REOrderedDictionaryPairPtr b) {
        return (comparator((__bridge id)a->key, (__bridge id)b->key) == NSOrderedAscending);
    }
};

NSString * _Nonnull const REOrderedDictionaryCoderKeyKeys =     @"REOrderedDictionary.coder.keys";
NSString * _Nonnull const REOrderedDictionaryCoderKeyObjects =  @"REOrderedDictionary.coder.objs";

@interface REOrderedDictionary() {
@protected
    REOrderedDictionaryPairList * _p;
}

- (nonnull REOrderedDictionaryPairList *) _pairList;

@end

@implementation REOrderedDictionary

#pragma mark - NSCopying

- (nonnull id) copyWithZone:(nullable NSZone *) zone {
    REOrderedDictionary * d = [[[self class] allocWithZone:zone] init];
    for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        REOrderedDictionaryPairPtr pair = *it;
        d->_p->push_back(pair);
    }
    return d;
}

#pragma mark - NSMutableCopying

- (nonnull id) mutableCopyWithZone:(nullable NSZone *) zone {
    REMutableOrderedDictionary * d = [[REMutableOrderedDictionary alloc] init];
    REOrderedDictionaryPairList * p = [d _pairList];
    for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        REOrderedDictionaryPairPtr pair = *it;
        p->push_back(pair);
    }
    return d;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(nonnull NSCoder *) aCoder {
    const size_t count = _p->size();
    NSArray * keys = nil, * objs = nil;
    if (count > 0) {
        NSMutableArray * allKeys = [NSMutableArray arrayWithCapacity:count];
        NSMutableArray * allObjs = [NSMutableArray arrayWithCapacity:count];
        for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            REOrderedDictionaryPairPtr pair = *it;
            [allKeys addObject:(__bridge id)pair->key];
            [allObjs addObject:(__bridge id)pair->obj];
        }
        keys = allKeys;
        objs = allObjs;
    } else {
        keys = objs = @[];
    }
    [aCoder encodeObject:keys forKey:REOrderedDictionaryCoderKeyKeys];
    [aCoder encodeObject:objs forKey:REOrderedDictionaryCoderKeyObjects];
}

- (nullable instancetype) initWithCoder:(nonnull NSCoder *) aDecoder {
    NSArray * allKeys = [aDecoder decodeObjectForKey:REOrderedDictionaryCoderKeyKeys];
    NSArray * allObjs = [aDecoder decodeObjectForKey:REOrderedDictionaryCoderKeyObjects];
    return (allKeys && allObjs) ? [self initWithObjects:allObjs andKeys:allKeys] : nil;
}

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

#pragma mark - NSFastEnumeration

- (NSUInteger) countByEnumeratingWithState:(nonnull NSFastEnumerationState *) state
                                   objects:(id _Nullable __unsafe_unretained * _Nonnull) stackbuf
                                     count:(NSUInteger) stackbufLength {
    NSUInteger count = 0;
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    const size_t size = _p->size();
    
    if (countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[0];
    }
    if (countOfItemsAlreadyEnumerated < size) {
        state->itemsPtr = stackbuf;
        
        while ((countOfItemsAlreadyEnumerated < size) && (count < stackbufLength)) {
            REOrderedDictionaryPairPtr pair = (*_p)[countOfItemsAlreadyEnumerated++];
            stackbuf[count++] = (__bridge id)pair->key;
        }
    }
    state->state = countOfItemsAlreadyEnumerated;
    return count;
}

#pragma mark - Common

- (nonnull REOrderedDictionaryPairList *) _pairList {
    return _p;
}

- (NSUInteger) count {
    return (NSUInteger)_p->size();
}

#pragma mark - All keys and values

- (nonnull NSArray *) allKeys {
    const size_t count = _p->size();
    if (count > 0) {
        NSMutableArray * values = [NSMutableArray arrayWithCapacity:count];
        for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            REOrderedDictionaryPairPtr pair = *it;
            [values addObject:(__bridge id)pair->key];
        }
        return values;
    }
    return @[];
}

- (nonnull NSArray *) allObjects {
    const size_t count = _p->size();
    if (count > 0) {
        NSMutableArray * objects = [NSMutableArray arrayWithCapacity:count];
        for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            REOrderedDictionaryPairPtr pair = *it;
            [objects addObject:(__bridge id)pair->obj];
        }
        return objects;
    }
    return @[];
}

#pragma mark - Subscripts

- (nullable id) objectAtIndexedSubscript:(NSUInteger) index {
    const size_t size = _p->size();
    if (index < size) {
        REOrderedDictionaryPairPtr pair = (*_p)[index];
        return (__bridge id)pair->obj;
    }
    return nil;
}

- (nullable id) objectForKeyedSubscript:(nonnull id) key {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(key != nil);
#endif
    for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        REOrderedDictionaryPairPtr pair = *it;
        if ([(__bridge id)pair->key isEqual:key]) {
            return (__bridge id)pair->obj;
        }
    }
    return nil;
}

#pragma mark - Equality

- (BOOL) isEqualToOrderedDictionary:(nonnull REOrderedDictionary *) orderedDictionary {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(orderedDictionary != nil);
    NSAssert([orderedDictionary isKindOfClass:[REOrderedDictionary class]], @"Unsupported 'orderedDictionary' class: %@", NSStringFromClass([orderedDictionary class]));
#endif
    const size_t s1 = _p->size();
    const size_t s2 = orderedDictionary->_p->size();
    if (s1 == s2) {
        REOrderedDictionaryPairList::iterator it1 = _p->begin();
        REOrderedDictionaryPairList::iterator it2 = orderedDictionary->_p->begin();
        while (it1 != _p->end() && it2 != orderedDictionary->_p->end()) {
            REOrderedDictionaryPairPtr pair1 = *it1, pair2 = *it2;
            if (![(__bridge id)pair1->key isEqual:(__bridge id)pair2->key] ||
                ![(__bridge id)pair1->obj isEqual:(__bridge id)pair2->obj]) {
                return NO;
            }
            ++it1;
            ++it2;
        }
        return YES;
    }
    return NO;
}

- (BOOL) isEqualToDictionary:(nonnull NSDictionary *) dictionary {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(dictionary != nil);
    NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Unsupported 'dictionary' class: %@", NSStringFromClass([dictionary class]));
#endif
    const size_t s1 = _p->size();
    const size_t s2 = [dictionary count];
    if (s1 == s2) {
        for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            REOrderedDictionaryPairPtr pair = *it;
            id obj = [dictionary objectForKey:(__bridge id)pair->key];
            if (!obj || ![obj isEqual:(__bridge id)pair->obj]) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL) isEqual:(id) object {
    if ([object isKindOfClass:[REOrderedDictionary class]]) {
        return [self isEqualToOrderedDictionary:(REOrderedDictionary *)object];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        return [self isEqualToDictionary:(NSDictionary *)object];
    }
    return [super isEqual:object];
}

#pragma mark - Initialization

- (nonnull instancetype) init {
    self = [super init];
    assert(self);
    _p = new REOrderedDictionaryPairList();
    assert(_p);
    return self;
}

- (nonnull instancetype) initWithObjectsAndKeys:(nullable id) firstObject, ... {
    self = [self init];
    if (firstObject) {
        id key = firstObject, obj = nil;
        va_list argsList;
        va_start(argsList, firstObject);
        do {
            if (obj) {
                REOrderedDictionaryPairPtr pair = std::make_shared<REOrderedDictionaryPair>();
                pair->set(key, obj);
                _p->push_back(pair);
                obj = nil;
            } else {
                obj = key;
            }
            key = va_arg(argsList, id);
        } while (key);
        va_end(argsList);
    }
    return self;
}

- (nonnull instancetype) initWithObjects:(nonnull NSArray *) allObjects andKeys:(nonnull NSArray *) allKeys {
    self = [self init];
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(allObjects != nil);
    NSParameterAssert(allKeys != nil);
#endif
    NSEnumerator * keysEnumerator = [allKeys objectEnumerator];
    NSEnumerator * objsEnumerator = [allObjects objectEnumerator];
    id key = [keysEnumerator nextObject], obj = [objsEnumerator nextObject];
    while (key && obj) {
        REOrderedDictionaryPairPtr pair = std::make_shared<REOrderedDictionaryPair>();
        pair->set(key, obj);
        _p->push_back(pair);
        key = [keysEnumerator nextObject];
        obj = [objsEnumerator nextObject];
    }
    return self;
}

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                       usingKeySortFunction:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorFunction) keyComparator
                                    context:(nullable void *) context {
    self = [self init];
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(dictionary != nil);
#endif
    REOrderedDictionaryPairList * p = _p;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        REOrderedDictionaryPairPtr pair = std::make_shared<REOrderedDictionaryPair>();
        pair->set(key, obj);
        p->push_back(pair);
    }];
    if (keyComparator) {
        REOrderedDictionaryKeySortFunctorWithCallback functor;
        functor.comparator = keyComparator;
        functor.context = context;
        std::sort(_p->begin(), _p->end(), functor);
    }
    return self;
}

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                          usingKeySortBlock:(nullable NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator {
    self = [self init];
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(dictionary != nil);
#endif
    REOrderedDictionaryPairList * p = _p;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        REOrderedDictionaryPairPtr pair = std::make_shared<REOrderedDictionaryPair>();
        pair->set(key, obj);
        p->push_back(pair);
    }];
    if (keyComparator) {
        REOrderedDictionaryKeySortFunctorWithBlock functor;
        functor.comparator = keyComparator;
        std::sort(_p->begin(), _p->end(), functor);
    }
    return self;
}

- (void) dealloc {
    delete _p;
}

#pragma mark - Debug description

#if defined(_DEBUG) || defined(DEBUG)

- (NSString *) description {
    return [self debugDescription];
}

- (NSString *) debugDescription {
    NSMutableString * str = [NSMutableString stringWithCapacity:128];
    [str appendString:@"{"];
    for (REOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        REOrderedDictionaryPairPtr pair = *it;
        id obj = (__bridge id)pair->obj;
        if ([obj isKindOfClass:[NSString class]]) {
            [str appendFormat:@"\n    %@ = \"%@\";", (__bridge id)pair->key, obj];
        } else {
            [str appendFormat:@"\n    %@ = %@;", (__bridge id)pair->key, obj];
        }
    }
    [str appendString:@"\n}"];
    return str;
}

#endif

@end

#pragma mark - REMutableOrderedDictionary

@interface REMutableOrderedDictionary() {
@private
    pthread_mutex_t _mutex;
}

@end

@implementation REMutableOrderedDictionary

#pragma mark - NSCopying

- (nonnull id) copyWithZone:(nullable NSZone *) zone {
    id res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super copyWithZone:zone];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - NSMutableCopying

- (nonnull id) mutableCopyWithZone:(nullable NSZone *) zone {
    id res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super mutableCopyWithZone:zone];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(nonnull NSCoder *) aCoder {
    pthread_mutex_lock(&_mutex);
    [super encodeWithCoder:aCoder];
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - NSFastEnumeration

- (NSUInteger) countByEnumeratingWithState:(nonnull NSFastEnumerationState *) state
                                   objects:(id _Nullable __unsafe_unretained * _Nonnull) stackbuf
                                     count:(NSUInteger) stackbufLength {
    NSUInteger res = 0;
    pthread_mutex_lock(&_mutex);
    res = [super countByEnumeratingWithState:state objects:stackbuf count:stackbufLength];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - Common

- (NSUInteger) count {
    NSUInteger res = 0;
    pthread_mutex_lock(&_mutex);
    res = [super count];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - Mutating

- (void) sortUsingKeySortFunction:(nonnull NS_NOESCAPE REOrderedDictionaryKeyComparatorFunction) keyComparator
                          context:(nullable void *) context {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(keyComparator != nil);
#endif
    pthread_mutex_lock(&_mutex);
    REOrderedDictionaryKeySortFunctorWithCallback functor;
    functor.comparator = keyComparator;
    functor.context = context;
    std::sort(_p->begin(), _p->end(), functor);
    pthread_mutex_unlock(&_mutex);
}

- (void) sortUsingKeySortBlock:(nonnull NS_NOESCAPE REOrderedDictionaryKeyComparatorBlock) keyComparator {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(keyComparator != nil);
#endif
    pthread_mutex_lock(&_mutex);
    REOrderedDictionaryKeySortFunctorWithBlock functor;
    functor.comparator = keyComparator;
    std::sort(_p->begin(), _p->end(), functor);
    pthread_mutex_unlock(&_mutex);
}

static void REMutableOrderedDictionarySetObjectForKey(REOrderedDictionaryPairList * p, id _Nullable o, id _Nonnull k) {
    for (REOrderedDictionaryPairList::iterator it = p->begin(); it != p->end(); ++it) {
        REOrderedDictionaryPairPtr pair = *it;
        if ([(__bridge id)pair->key isEqual:k]) {
            if (o) {
                pair->resetObj(o);
            } else {
                p->erase(it);
            }
            return;
        }
    }
    if (o) {
        REOrderedDictionaryPairPtr pair = std::make_shared<REOrderedDictionaryPair>();
        pair->set(k, o);
        p->push_back(pair);
    }
}

- (void) setObject:(nullable id) object forKey:(nonnull id) key {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(key != nil);
#endif
    pthread_mutex_lock(&_mutex);
    REMutableOrderedDictionarySetObjectForKey(_p, object, key);
    pthread_mutex_unlock(&_mutex);
}

- (void) removeObjectForKey:(nonnull id) key {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(key != nil);
#endif
    pthread_mutex_lock(&_mutex);
    REMutableOrderedDictionarySetObjectForKey(_p, nil, key);
    pthread_mutex_unlock(&_mutex);
}

- (void) setObject:(nullable id) object forKeyedSubscript:(nonnull id) key {
#if defined(_DEBUG) || defined(DEBUG)
    NSParameterAssert(key != nil);
#endif
    pthread_mutex_lock(&_mutex);
    REMutableOrderedDictionarySetObjectForKey(_p, object, key);
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - All keys and values

- (nonnull NSArray *) allKeys {
    NSArray * res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super allKeys];
    pthread_mutex_unlock(&_mutex);
    return res;
}

- (nonnull NSArray *) allObjects {
    NSArray * res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super allObjects];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - Subscripts

- (nullable id) objectAtIndexedSubscript:(NSUInteger) index {
    id res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super objectAtIndexedSubscript:index];
    pthread_mutex_unlock(&_mutex);
    return res;
}

- (nullable id) objectForKeyedSubscript:(nonnull id) key {
    id res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super objectForKeyedSubscript:key];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - Equality

- (BOOL) isEqualToOrderedDictionary:(nonnull REOrderedDictionary *) orderedDictionary {
    BOOL res = NO;
    pthread_mutex_lock(&_mutex);
    res = [super isEqualToOrderedDictionary:orderedDictionary];
    pthread_mutex_unlock(&_mutex);
    return res;
}

- (BOOL) isEqualToDictionary:(nonnull NSDictionary *) dictionary {
    BOOL res = NO;
    pthread_mutex_lock(&_mutex);
    res = [super isEqualToDictionary:dictionary];
    pthread_mutex_unlock(&_mutex);
    return res;
}

- (BOOL) isEqual:(id) object {
    BOOL res = NO;
    pthread_mutex_lock(&_mutex);
    res = [super isEqual:object];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#pragma mark - Initialization

- (nonnull instancetype) init {
    self = [super init];
    pthread_mutexattr_t attr;
    int res = pthread_mutexattr_init(&attr);
    assert(res == 0);
    res = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    assert(res == 0);
    pthread_mutex_init(&_mutex, &attr);
    pthread_mutexattr_destroy(&attr);
    return self;
}

- (void) dealloc {
    pthread_mutex_destroy(&_mutex);
}

#pragma mark - Debug description

#if defined(_DEBUG) || defined(DEBUG)

- (NSString *) description {
    NSString * res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super description];
    pthread_mutex_unlock(&_mutex);
    return res;
}

- (NSString *) debugDescription {
    NSString * res = nil;
    pthread_mutex_lock(&_mutex);
    res = [super debugDescription];
    pthread_mutex_unlock(&_mutex);
    return res;
}

#endif

@end

#pragma mark - Extensions

@implementation NSDictionary (REOrderedDictionary)

- (nonnull REOrderedDictionary *) orderedCopy {
    return [[REOrderedDictionary alloc] initWithDictionary:self usingKeySortFunction:NULL context:NULL];
}

- (nonnull REMutableOrderedDictionary *) mutableOrderedCopy {
    return [[REMutableOrderedDictionary alloc] initWithDictionary:self usingKeySortFunction:NULL context:NULL];
}

@end

