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


#import "NSOrderedDictionary.h"

#include <list>

class NSOrderedDictionaryPair {
public:
    CFTypeRef key, obj;
    
    void resetObj(id _Nonnull o) {
        if (obj) {
            CFBridgingRelease(obj);
        }
        obj = CFBridgingRetain(o);
    }
    
    void set(id _Nonnull k, id _Nonnull o) {
        key = CFBridgingRetain(k);
        obj = CFBridgingRetain(o);
    }
    
    NSOrderedDictionaryPair() : key(NULL), obj(NULL) {
        NSLog(@"NSOrderedDictionaryPair()");
    }
    
    ~NSOrderedDictionaryPair() {
        NSLog(@"~NSOrderedDictionaryPair(), { %@ : %@ }", (__bridge id)key, (__bridge id)obj);
        CFBridgingRelease(key);
        CFBridgingRelease(obj);
    }
};

typedef std::shared_ptr<NSOrderedDictionaryPair> NSOrderedDictionaryPairPtr;
typedef std::list<NSOrderedDictionaryPairPtr> NSOrderedDictionaryPairList;

struct NSOrderedDictionaryKeySortFunctorWithCallback {
    void * context;
    NSOrderedDictionaryKeyComparatorFunction comparator;
    bool operator()(const NSOrderedDictionaryPairPtr & a, const NSOrderedDictionaryPairPtr & b) {
        return (comparator((__bridge id)a->key, (__bridge id)b->key, context) == NSOrderedAscending);
    }
};

struct NSOrderedDictionaryKeySortFunctorWithBlock {
    NSOrderedDictionaryKeyComparatorBlock comparator;
    bool operator()(const NSOrderedDictionaryPairPtr & a, const NSOrderedDictionaryPairPtr & b) {
        return (comparator((__bridge id)a->key, (__bridge id)b->key) == NSOrderedAscending);
    }
};

NSString * _Nonnull const NSOrderedDictionaryCoderKeyKeys =     @"NSOrderedDictionary.coder.keys";
NSString * _Nonnull const NSOrderedDictionaryCoderKeyObjects =  @"NSOrderedDictionary.coder.objs";

@interface NSOrderedDictionary() {
@protected
    NSOrderedDictionaryPairList * _p;
}

@end

@implementation NSOrderedDictionary

#pragma mark - NSCopying

- (nonnull id) copyWithZone:(nullable NSZone *) zone {
    NSLog(@"copyWithZone:");
    NSOrderedDictionary * d = [[[self class] allocWithZone:zone] init];
    for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        d->_p->push_back(*it);
    }
    return d;
}

#pragma mark - NSMutableCopying

- (nonnull id) mutableCopyWithZone:(nullable NSZone *) zone {
    NSLog(@"mutableCopyWithZone:");
    NSOrderedDictionary * d = [[NSMutableOrderedDictionary alloc] init];
    for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        d->_p->push_back(*it);
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
        for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            [allKeys addObject:(__bridge id)(*it)->key];
            [allObjs addObject:(__bridge id)(*it)->obj];
        }
        keys = allKeys;
        objs = allObjs;
    } else {
        keys = objs = @[];
    }
    [aCoder encodeObject:keys forKey:NSOrderedDictionaryCoderKeyKeys];
    [aCoder encodeObject:objs forKey:NSOrderedDictionaryCoderKeyObjects];
}

- (nullable instancetype) initWithCoder:(nonnull NSCoder *) aDecoder {
    NSArray * allKeys = [aDecoder decodeObjectForKey:NSOrderedDictionaryCoderKeyKeys];
    NSArray * allObjs = [aDecoder decodeObjectForKey:NSOrderedDictionaryCoderKeyObjects];
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
        
        NSOrderedDictionaryPairList::iterator it = _p->begin();
        std::advance(it, countOfItemsAlreadyEnumerated);
        
        while ((countOfItemsAlreadyEnumerated < size) && (count < stackbufLength)) {
            NSOrderedDictionaryPairPtr pair = *it;
            stackbuf[count] = (__bridge id)pair->key;
            it++;
            countOfItemsAlreadyEnumerated++;
            count++;
        }
    }
    state->state = countOfItemsAlreadyEnumerated;
    return count;
}

#pragma mark - Subscripts

- (nullable id) objectAtIndexedSubscript:(NSUInteger) index {
    const size_t size = _p->size();
    if (index < size) {
        NSOrderedDictionaryPairList::iterator it = _p->begin();
        std::advance(it, index);
        return (__bridge id)(*it)->obj;
    }
    return nil;
}

- (nullable id) objectForKeyedSubscript:(nonnull id) key {
    NSParameterAssert(key != nil);
    for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        if ([(__bridge id)(*it)->key isEqual:key]) {
            return (__bridge id)(*it)->obj;
        }
    }
    return nil;
}

#pragma mark - All keys and values

- (nonnull NSArray *) allKeys {
    const size_t count = _p->size();
    if (count > 0) {
        NSMutableArray * values = [NSMutableArray arrayWithCapacity:count];
        for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            [values addObject:(__bridge id)(*it)->key];
        }
        return values;
    }
    return @[];
}

- (nonnull NSArray *) allObjects {
    const size_t count = _p->size();
    if (count > 0) {
        NSMutableArray * objects = [NSMutableArray arrayWithCapacity:count];
        for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
            [objects addObject:(__bridge id)(*it)->obj];
        }
        return objects;
    }
    return @[];
}

#pragma mark -

- (NSUInteger) count {
    return (NSUInteger)_p->size();
}

- (nonnull instancetype) init {
    NSLog(@"init");
    self = [super init];
    if (self) {
        _p = new NSOrderedDictionaryPairList();
        assert(_p);
    }
    return self;
}

- (nonnull instancetype) initWithObjectsAndKeys:(nullable id) firstObject, ... {
    NSLog(@"initWithObjectsAndKeys:");
    self = [self init];
    if (self && firstObject) {
        id key = firstObject, obj = nil;
        va_list argsList;
        va_start(argsList, firstObject);
        do {
            if (obj) {
                NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
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
    if (self) {
        NSEnumerator * keysEnumerator = [allKeys objectEnumerator];
        NSEnumerator * objsEnumerator = [allObjects objectEnumerator];
        id key = [keysEnumerator nextObject], obj = [objsEnumerator nextObject];
        while (key && obj) {
            NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
            pair->set(key, obj);
            _p->push_back(pair);
            key = [keysEnumerator nextObject];
            obj = [objsEnumerator nextObject];
        }
    }
    return self;
}

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                       usingKeySortFunction:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorFunction) keyComparator
                                    context:(nullable void *) context {
    self = [self init];
    if (self) {
        NSOrderedDictionaryPairList * p = _p;
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
            pair->set(key, obj);
            p->push_back(pair);
        }];
        if (keyComparator) {
            NSOrderedDictionaryKeySortFunctorWithCallback functor;
            functor.comparator = keyComparator;
            functor.context = context;
            _p->sort(functor);
        }
    }
    return self;
}

- (nonnull instancetype) initWithDictionary:(nonnull NSDictionary *) dictionary
                          usingKeySortBlock:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorBlock) keyComparator {
    self = [self init];
    if (self) {
        NSParameterAssert(dictionary != nil);
        NSOrderedDictionaryPairList * p = _p;
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
            pair->set(key, obj);
            p->push_back(pair);
        }];
        if (keyComparator) {
            NSOrderedDictionaryKeySortFunctorWithBlock functor;
            functor.comparator = keyComparator;
            _p->sort(functor);
        }
    }
    return self;
}

- (void) dealloc {
    NSLog(@"dealloc");
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
    for (NSOrderedDictionaryPairList::iterator it = _p->begin(); it != _p->end(); ++it) {
        id obj = (__bridge id)(*it)->obj;
        if ([obj isKindOfClass:[NSString class]]) {
            [str appendFormat:@"\n    %@ = \"%@\";", (__bridge id)(*it)->key, obj];
        } else {
            [str appendFormat:@"\n    %@ = %@;", (__bridge id)(*it)->key, obj];
        }
    }
    [str appendString:@"\n}"];
    return str;
}

#endif

@end

#pragma mark - NSMutableOrderedDictionary

@implementation NSMutableOrderedDictionary

- (void) sortUsingKeySortFunction:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorFunction) keyComparator
                          context:(nullable void *) context {
    if (keyComparator) {
        NSOrderedDictionaryKeySortFunctorWithCallback functor;
        functor.comparator = keyComparator;
        functor.context = context;
        _p->sort(functor);
    }
}

- (void) sortUsingKeySortBlock:(nullable NS_NOESCAPE NSOrderedDictionaryKeyComparatorBlock) keyComparator {
    if (keyComparator) {
        NSOrderedDictionaryKeySortFunctorWithBlock functor;
        functor.comparator = keyComparator;
        _p->sort(functor);
    }
}

static void NSMutableOrderedDictionarySetObjectForKey(NSOrderedDictionaryPairList * p, id _Nullable o, id _Nonnull k) {
    for (NSOrderedDictionaryPairList::iterator it = p->begin(); it != p->end(); ++it) {
        if ([(__bridge id)(*it)->key isEqual:k]) {
            if (o) {
                (*it)->resetObj(o);
            } else {
                p->erase(it);
            }
            return;
        }
    }
    if (o) {
        NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
        pair->set(k, o);
        p->push_back(pair);
    }
}

- (void) setObject:(nullable id) object forKey:(nonnull id) key {
    NSParameterAssert(key != nil);
    NSMutableOrderedDictionarySetObjectForKey(_p, object, key);
}

- (void) removeObjectForKey:(nonnull id) key {
    NSParameterAssert(key != nil);
    NSMutableOrderedDictionarySetObjectForKey(_p, nil, key);
}

- (void) setObject:(nullable id) object forKeyedSubscript:(nonnull id) key {
    NSParameterAssert(key != nil);
    NSMutableOrderedDictionarySetObjectForKey(_p, object, key);
}

- (void) insertObject:(nullable id) object forKey:(nonnull id) key atIndex:(NSUInteger) index {
    NSParameterAssert(object != nil && key != nil && index <= _p->size());
    NSOrderedDictionaryPairList::iterator it = _p->begin();
    std::advance(it, index);
    NSOrderedDictionaryPairPtr pair = std::make_shared<NSOrderedDictionaryPair>();
    pair->set(key, object);
    _p->insert(it, pair);
}

@end

#pragma mark - Extensions

@implementation NSDictionary (NSOrderedDictionary)

- (nonnull NSOrderedDictionary *) orderedCopy {
    return [[NSOrderedDictionary alloc] initWithDictionary:self usingKeySortFunction:NULL context:NULL];
}

- (nonnull NSMutableOrderedDictionary *) mutableOrderedCopy {
    return [[NSMutableOrderedDictionary alloc] initWithDictionary:self usingKeySortFunction:NULL context:NULL];
}

@end

