//
//  SJPromise.m
//
//  Created by changsanjiang on 2020/9/18.
//

#import "SJPromise.h"
@class SJContinuationPromise;

@interface SJPromiseResult ()
+ (instancetype)fulfilledResultWithValue:(id _Nullable)value;
+ (instancetype)rejectedResultWithError:(NSError *)error;
- (void)setFulfilledWithValue:(id _Nullable)value;
- (void)setRejectedWithError:(NSError *)error;
@end

@implementation SJPromiseResult
+ (instancetype)fulfilledResultWithValue:(id _Nullable)value {
    SJPromiseResult *result = [SJPromiseResult.alloc init];
    result->_isFulfilled = YES;
    result->_value = value;
    return result;
}
+ (instancetype)rejectedResultWithError:(NSError *)error {
    SJPromiseResult *result = [SJPromiseResult.alloc init];
    result->_error = error;
    return result;
}
- (void)setFulfilledWithValue:(id _Nullable)value {
    _isFulfilled = YES;
    _value = value;
}
- (void)setRejectedWithError:(NSError *)error {
    if ( _isFulfilled ) _isFulfilled = NO;
    _error = error;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"SJPromiseResult<%p> { isFulfilled: %@, value: %@, error: %@ }", self, _isFulfilled ? @"true" : @"false", _value, _error];
}
- (BOOL)isRejected {
    return !_isFulfilled;
}
@end

#pragma mark - mark

@interface SJPromise()
+ (instancetype)promiseWithQueue:(dispatch_queue_t)queue lazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block;
+ (instancetype)promiseWithLazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block;
+ (instancetype)promiseWithHandler:(SJPromiseContinuationHandler)block;
+ (instancetype)retryablePromiseWithHandler:(SJPromiseContinuationHandler)block;
+ (instancetype)lazyPromiseWithHandler:(SJPromiseContinuationHandler)block;
+ (instancetype)lazyAndRetryablePromiseWithHandler:(SJPromiseContinuationHandler)block;
+ (SJPromiseResolvers *)resolvers;

- (SJPromise *)onFulfilled:(SJPromiseFulfillmentHandler)block;
- (SJPromise *)onRejected:(SJPromiseRejectionHandler)block;
- (SJPromise *)onFinally:(SJPromiseFinalityHandler)block;
- (void)addContinuationPromise:(SJContinuationPromise *)promise;

- (void)resolveWithValue:(SJPromiseReturnValue _Nullable)value;
- (void)rejectWithError:(NSError *)error;

- (void)willAddContinuationPromise;
- (void)retryIfFailed:(void (^)(void))retryableBlock;
- (void)didComplete:(SJPromiseResult *)result;
@end


#pragma mark - mark

@interface SJPromiseContinuation ()
- (instancetype)initWithPromise:(SJPromise *)promise;
- (void)resolveWithValue:(SJPromiseReturnValue _Nullable)value;
- (void)rejectWithError:(NSError *)error;
@end

@implementation SJPromiseContinuation {
    SJPromise *mPromise;
}

- (instancetype)initWithPromise:(SJPromise *)promise {
    self = [super init];
    mPromise = promise;
    return self;
}

- (void)resolveWithValue:(SJPromiseReturnValue _Nullable)value {
    [mPromise resolveWithValue:value];
}

- (void)rejectWithError:(NSError *)error {
    [mPromise rejectWithError:error];
}
@end


#pragma mark - mark

@implementation SJPromiseResolvers
- (void (^)(SJPromiseReturnValue _Nullable))resolve {
    return ^(SJPromiseReturnValue value) {
        [self resolveWithValue:value];
    };
}

- (void (^)(NSError * _Nonnull))reject {
    return ^(NSError *error) {
        [self rejectWithError:error];
    };
}
@end


#pragma mark - mark

@interface SJExecutionPromise : SJPromise
- (instancetype)initWithQueue:(dispatch_queue_t)queue lazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block;
- (void)start;
@end


@implementation SJExecutionPromise {
    dispatch_queue_t _Nullable mQueue;
    SJPromiseContinuationHandler _Nullable mBlock;
    BOOL mRetryable;
    BOOL mLazy;
    BOOL mPerformed;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue lazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block {
    self = [super init];
    mQueue = queue;
    mLazy = isLazy;
    mRetryable = isRetryable;
    mBlock = block;
    return self;
}

- (void)start {
    if ( !mLazy ) [self performBlock]; // lazy时, 推迟任务执行到首次订阅;
}

- (void)willAddContinuationPromise {
    if ( mLazy ) {
        if ( !mPerformed ) {
            mPerformed = YES;
            [self performBlock]; // lazy时, 首次订阅时执行任务;
            return;
        }
    }
    
    if ( mRetryable ) [self retryIfFailed:^{ [self performBlock]; }]; // retryable时, 尝试重试;
}

- (void)performBlock {
    dispatch_async(mQueue, ^{
        self->mBlock([SJPromiseContinuation.alloc initWithPromise:self]);
    });
}

- (void)didComplete:(SJPromiseResult *)result {
    if ( mRetryable && !result.isFulfilled ) {
        return;
    }
    
    mBlock = nil;
    mQueue = nil;
}
@end

@interface SJContinuationPromise : SJPromise
- (instancetype)initWithQueue:(dispatch_queue_t)queue fulfillmentHandler:(SJPromiseFulfillmentHandler _Nullable)fulfillmentHandler rejectionHandler:(SJPromiseRejectionHandler _Nullable)rejectionHandler;
- (instancetype)initWithFulfillmentHandler:(SJPromiseFulfillmentHandler _Nullable)fulfillmentHandler rejectionHandler:(SJPromiseRejectionHandler _Nullable)rejectionHandler;
- (instancetype)initWithFulfillmentHandler:(SJPromiseFulfillmentHandler)fulfillmentHandler;
- (instancetype)initWithRejectionHandler:(SJPromiseRejectionHandler)rejectionHandler;
- (instancetype)initWithFinalityHandler:(SJPromiseFinalityHandler)finalityHandler;
- (instancetype)initWithQueue:(dispatch_queue_t)queue finalityHandler:(SJPromiseFinalityHandler)finalityHandler;
- (void)start:(SJPromiseResult *)prev;
@end

@implementation SJContinuationPromise {
    dispatch_queue_t _Nullable mQueue;
    SJPromiseFulfillmentHandler _Nullable mFulfillmentHandler;
    SJPromiseFulfillmentHandler _Nullable mRejectionHandler;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue fulfillmentHandler:(SJPromiseFulfillmentHandler _Nullable)fulfillmentHandler rejectionHandler:(SJPromiseRejectionHandler _Nullable)rejectionHandler {
    self = [super init];
    mQueue = queue;
    mFulfillmentHandler = fulfillmentHandler;
    mRejectionHandler = rejectionHandler;
    return self;
}

- (instancetype)initWithFulfillmentHandler:(SJPromiseFulfillmentHandler _Nullable)fulfillmentHandler rejectionHandler:(SJPromiseRejectionHandler _Nullable)rejectionHandler {
    return [self initWithQueue:dispatch_get_global_queue(0, 0) fulfillmentHandler:fulfillmentHandler rejectionHandler:rejectionHandler];
}

- (instancetype)initWithFulfillmentHandler:(SJPromiseFulfillmentHandler _Nullable)fulfillmentHandler {
    return [self initWithFulfillmentHandler:fulfillmentHandler rejectionHandler:nil];
}

- (instancetype)initWithRejectionHandler:(SJPromiseRejectionHandler _Nullable)rejectionHandler {
    return [self initWithFulfillmentHandler:nil rejectionHandler:rejectionHandler];
}

- (instancetype)initWithFinalityHandler:(SJPromiseFinalityHandler)finalityHandler {
    return [self initWithQueue:dispatch_get_global_queue(0, 0) finalityHandler:finalityHandler];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue finalityHandler:(SJPromiseFinalityHandler)finalityHandler {
    return [self initWithQueue:queue fulfillmentHandler:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        finalityHandler();
        return nil;
    } rejectionHandler:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        finalityHandler();
        return nil;
    }];
}

- (void)start:(SJPromiseResult *)prev {
    if ( prev.isFulfilled ) {
        if ( self->mFulfillmentHandler != nil ) {
            dispatch_async(mQueue, ^{
                SJPromiseReturnValue ret = self->mFulfillmentHandler(prev.value); // prev处于成功状态时执行mFulfillmentHandler;
                [self resolveWithValue:ret];
            });
            return;
        }
        [self resolveWithValue:prev.value];
    }
    else {
        if ( self->mRejectionHandler != nil ) {
            dispatch_async(mQueue, ^{
                SJPromiseReturnValue ret = self->mRejectionHandler(prev.error); // prev处于失败状态时执行mRejectionHandler;
                [self resolveWithValue:ret];
            });
            return;
        }
        [self rejectWithError:prev.error];
    }
}

- (void)didComplete:(SJPromiseResult *)result {
    mQueue = nil;
    if ( mFulfillmentHandler != nil ) mFulfillmentHandler = nil;
    if ( mRejectionHandler != nil ) mRejectionHandler = nil;
}
@end

static dispatch_queue_t mPromiseQueue;

@implementation SJPromise {
    SJPromiseResult *_Nullable mResult;
    NSMutableArray<SJContinuationPromise *> *_Nullable mContinuations;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mPromiseQueue = dispatch_queue_create("com.lwz.queue.promise", DISPATCH_QUEUE_SERIAL);
    });
}

+ (instancetype)promiseWithQueue:(dispatch_queue_t)queue lazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block {
    SJExecutionPromise *promise = [[SJExecutionPromise alloc] initWithQueue:queue lazy:isLazy retryable:isRetryable handler:block];
    @try {
        return promise;
    }
    @finally {
        [promise start];
    }
}

+ (instancetype)promiseWithLazy:(BOOL)isLazy retryable:(BOOL)isRetryable handler:(SJPromiseContinuationHandler)block {
    return [self promiseWithQueue:dispatch_get_global_queue(0, 0) lazy:isLazy retryable:isRetryable handler:block];
}

+ (instancetype)promiseWithHandler:(SJPromiseContinuationHandler)block {
    return [self promiseWithLazy:NO retryable:NO handler:block];
}

+ (instancetype)retryablePromiseWithHandler:(SJPromiseContinuationHandler)block {
    return [self promiseWithLazy:NO retryable:YES handler:block];
}

+ (instancetype)lazyPromiseWithHandler:(SJPromiseContinuationHandler)block {
    return [self promiseWithLazy:YES retryable:NO handler:block];
}

+ (instancetype)lazyAndRetryablePromiseWithHandler:(SJPromiseContinuationHandler)block {
    return [self promiseWithLazy:YES retryable:YES handler:block];
}

+ (instancetype)promiseWithResolve:(SJPromiseReturnValue _Nullable)value {
    if ( [value isKindOfClass:SJPromise.class] ) {
        return value;
    }
    SJPromise *promise = [SJPromise.alloc init];
    promise->mResult = [SJPromiseResult fulfilledResultWithValue:value];
    return promise;
}

+ (instancetype)promiseWithReject:(NSError *)error {
    SJPromise *promise = [SJPromise.alloc init];
    promise->mResult = [SJPromiseResult rejectedResultWithError:error];
    return promise;
}

+ (SJPromiseResolvers *)resolvers {
    SJPromiseResolvers *resolvers = [SJPromiseResolvers.alloc init];
    return resolvers;
}

- (SJPromise *)onFulfilled:(SJPromiseFulfillmentHandler)block {
    SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithFulfillmentHandler:block];
    [self addContinuationPromise:promise];
    return promise;
}

- (SJPromise *)onRejected:(SJPromiseRejectionHandler)block {
    SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithRejectionHandler:block];
    [self addContinuationPromise:promise];
    return promise;
}

- (SJPromise *)onFinally:(SJPromiseFinalityHandler)block {
    SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithFinalityHandler:block];
    [self addContinuationPromise:promise];
    return promise;
}

- (void)resolveWithValue:(SJPromiseReturnValue _Nullable)value {
    if ( [value isKindOfClass:SJPromise.class] ) {
        [(SJPromise *)value onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            [self completeWithResult:[SJPromiseResult fulfilledResultWithValue:value]];
            return nil;
        }];
        
        [(SJPromise *)value onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
            [self completeWithResult:[SJPromiseResult rejectedResultWithError:error]];
            return nil;
        }];
        return; // return; wait promise resolved;
    }
    
    [self completeWithResult:[SJPromiseResult fulfilledResultWithValue:value]];
}

- (void)rejectWithError:(NSError *)error {
    [self completeWithResult:[SJPromiseResult rejectedResultWithError:error]];
}

#pragma mark - queue

- (void)addContinuationPromise:(SJContinuationPromise *)promise {
    dispatch_async(mPromiseQueue, ^{
        [self willAddContinuationPromise];
        
        if ( self->mResult == nil ) {
            if ( self->mContinuations == nil ) self->mContinuations = [NSMutableArray array];
            [self->mContinuations addObject:promise];
        }
        else {
            [promise start:self->mResult];
        }
    });
}

- (void)completeWithResult:(SJPromiseResult *)result {
    dispatch_async(mPromiseQueue, ^{
        if ( self->mResult != nil ) return;
        self->mResult = result;
        NSMutableArray<SJContinuationPromise *> *_Nullable continuations = self->mContinuations;
        if ( self->mContinuations != nil ) self->mContinuations = nil;
        
        [continuations enumerateObjectsUsingBlock:^(SJContinuationPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj start:result];
        }];
        
        [self didComplete:result];
    });
}

- (void)retryIfFailed:(void (^)(void))retryableBlock {
    if ( mResult != nil && !mResult.isFulfilled ) {
        mResult = nil;
        retryableBlock();
    }
}

- (void)willAddContinuationPromise { }
- (void)didComplete:(SJPromiseResult *)result { }
@end


@implementation SJPromise (Generics)
- (SJPromise *)withThen:(SJPromiseReturnValue _Nullable (^)(id _Nullable value))block {
    return [self onFulfilled:block];
}
@end

@implementation SJPromise(PromiseLike)

+ (instancetype)promiseWithAll:(NSArray<SJPromise *> *)promises {
    promises = promises.copy;
    return [self promiseWithHandler:^(SJPromiseContinuation * _Nonnull continuation) {
        NSInteger count = promises.count;
        NSMutableArray<SJPromiseResult *> *results = [NSMutableArray arrayWithCapacity:count];
        for ( NSInteger i = 0 ; i < count ; ++ i ) {
            [results addObject:[SJPromiseResult.alloc init]];
        }

        dispatch_group_t group = dispatch_group_create();
        [promises enumerateObjectsUsingBlock:^(SJPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SJPromiseResult *result = results[idx];
            dispatch_group_enter(group);
            [obj onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                [result setFulfilledWithValue:value];
                dispatch_group_leave(group);
                return nil;
            }];
            
            [obj onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
                [result setRejectedWithError:error];
                [continuation rejectWithError:error];
                dispatch_group_leave(group);
                return nil;
            }];
        }];
        
        dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
            for ( SJPromiseResult *r in results ) {
                if ( r.isRejected ) return; // 如果有rejected则return, 否则代表所有任务都成功了;
            }
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:count];
            [results enumerateObjectsUsingBlock:^(SJPromiseResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [values addObject:obj.value ?: [NSNull null]];
            }];
            [continuation resolveWithValue:values];
        });
    }];
}

+ (instancetype)promiseWithAllSettled:(NSArray<SJPromise *> *)promises {
    promises = promises.copy;
    return [self promiseWithHandler:^(SJPromiseContinuation * _Nonnull continuation) {
        NSInteger count = promises.count;
        NSMutableArray<SJPromiseResult *> *results = [NSMutableArray arrayWithCapacity:count];
        for ( NSInteger i = 0 ; i < count ; ++ i ) {
            [results addObject:[SJPromiseResult.alloc init]];
        }
        dispatch_group_t group = dispatch_group_create();
        [promises enumerateObjectsUsingBlock:^(SJPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SJPromiseResult *result = results[idx];
            dispatch_group_enter(group);
            [obj onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                [result setFulfilledWithValue:value];
                dispatch_group_leave(group);
                return nil;
            }];
            
            [obj onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
                [result setRejectedWithError:error];
                dispatch_group_leave(group);
                return nil;
            }];
        }];
        
        dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
            [continuation resolveWithValue:results];
        });
    }];
}

+ (instancetype)promiseWithRace:(NSArray<SJPromise *> *)promises {
    promises = promises.copy;
    return [self promiseWithHandler:^(SJPromiseContinuation * _Nonnull continuation) {
        [promises enumerateObjectsUsingBlock:^(SJPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                [continuation resolveWithValue:value];
                return nil;
            }];
            
            [obj onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
                [continuation rejectWithError:error];
                return nil;
            }];
        }];
    }];
}

+ (instancetype)promiseWithAny:(NSArray<SJPromise *> *)promises {
    promises = promises.copy;
    return [self promiseWithHandler:^(SJPromiseContinuation * _Nonnull continuation) {
        NSInteger count = promises.count;
        NSMutableArray<SJPromiseResult *> *results = [NSMutableArray arrayWithCapacity:count];
        for ( NSInteger i = 0 ; i < count ; ++ i ) {
            [results addObject:[SJPromiseResult.alloc init]];
        }
        dispatch_group_t group = dispatch_group_create();
        [promises enumerateObjectsUsingBlock:^(SJPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SJPromiseResult *result = results[idx];
            dispatch_group_enter(group);
            [obj onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                [result setFulfilledWithValue:value];
                [continuation resolveWithValue:value];
                dispatch_group_leave(group);
                return nil;
            }];
            
            [obj onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
                [result setRejectedWithError:error];
                dispatch_group_leave(group);
                return nil;
            }];
        }];

        dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
            for ( SJPromiseResult *r in results ) {
                if ( r.isFulfilled ) return; // 如果有fulfilled则return, 否则代表所有任务都失败了;
            }
            NSMutableArray<NSError *> *errors = [NSMutableArray arrayWithCapacity:count];
            [results enumerateObjectsUsingBlock:^(SJPromiseResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [errors addObject:obj.error];
            }];
            [continuation rejectWithError:[NSError.alloc initWithDomain:SJPromiseErrorDomain code:SJPromiseErrorCodeAggregateError userInfo:@{
                NSLocalizedDescriptionKey: @"All Promises rejected",
                SJPromiseAggregateErrorsKey: errors,
            }]];
        });
    }];
}

+ (instancetype)promiseWithFirstPriority:(NSArray<SJPromise *> *)promises {
    promises = promises.copy;
    return [self promiseWithHandler:^(SJPromiseContinuation * _Nonnull continuation) {
        /// 数组中第一个 Promise 的优先级最高; 优先返回第一个 Promise 成功时的值;
        /// 如果第一个 Promise 执行失败了, 则会取其他 Promise 的值;
        /// 如果所有 Promise 都失败(rejected), 则返回 SJPromiseErrorCodeAggregateError, 表明所有 Promise 都被 rejected;
        NSInteger count = promises.count;
        NSMutableArray<SJPromiseResult *> *results = [NSMutableArray arrayWithCapacity:count];
        for ( NSInteger i = 0 ; i < count ; ++ i ) {
            [results addObject:[SJPromiseResult.alloc init]];
        }
        SJPromiseResolvers *fallback = [SJPromise resolvers];
        dispatch_group_t group = dispatch_group_create();
        [promises enumerateObjectsUsingBlock:^(SJPromise * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SJPromiseResult *result = results[idx];
            dispatch_group_enter(group);
            // idx == 0 时为主请求
            [obj onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                // 主请求 Promise 的优先级最高, 否则记录后续的首个后备值;
                idx == 0 ? [continuation resolveWithValue:value] : fallback.resolve(value);
                [result setFulfilledWithValue:value];
                dispatch_group_leave(group);
                return nil;
            }];
            
            [obj onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
                // 如果主请求 Promise 执行失败了, 则取后备值;
                if ( idx == 0 ) {
                    [fallback onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
                        continuation.resolve(value);
                        return nil;
                    }];
                }
                [result setRejectedWithError:error];
                dispatch_group_leave(group);
                return nil;
            }];
        }];

        dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
            for ( SJPromiseResult *r in results ) {
                if ( r.isFulfilled ) return; // 如果有值填充则return, 否则代表所有任务均失败了;
            }
            NSMutableArray<NSError *> *errors = [NSMutableArray arrayWithCapacity:count];
            [results enumerateObjectsUsingBlock:^(SJPromiseResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [errors addObject:obj.error];
            }];
            [continuation rejectWithError:[NSError.alloc initWithDomain:SJPromiseErrorDomain code:SJPromiseErrorCodeAggregateError userInfo:@{
                NSLocalizedDescriptionKey: @"All Promises rejected",
                SJPromiseAggregateErrorsKey: errors,
            }]];
        });
    }];
}

+ (SJPromise * _Nonnull (^)(SJPromiseContinuationHandler _Nonnull))promise {
    return ^SJPromise *(SJPromiseContinuationHandler block) {
        return [SJPromise promiseWithHandler:block];
    };
}
- (SJPromise * _Nonnull (^)(SJPromiseFulfillmentHandler _Nonnull))then {
    return ^SJPromise *(SJPromiseFulfillmentHandler block) {
        return [self onFulfilled:block];
    };
}
- (SJPromise * _Nonnull (^)(SJPromiseRejectionHandler _Nonnull))catch {
    return ^SJPromise *(SJPromiseRejectionHandler block) {
        return [self onRejected:block];
    };
}
- (SJPromise * _Nonnull (^)(SJPromiseFinalityHandler _Nonnull))finally {
    return ^SJPromise *(SJPromiseFinalityHandler block) {
        return [self onFinally:block];
    };
}

+ (SJPromise * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))all {
    return ^SJPromise *(NSArray<SJPromise *> *promises) {
        return [SJPromise promiseWithAll:promises];
    };
}
+ (SJPromise * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))allSettled {
    return ^SJPromise *(NSArray<SJPromise *> *promises) {
        return [SJPromise promiseWithAllSettled:promises];
    };
}
+ (SJPromise * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))race {
    return ^SJPromise *(NSArray<SJPromise *> *promises) {
        return [SJPromise promiseWithRace:promises];
    };
}
+ (SJPromise * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))any {
    return ^SJPromise *(NSArray<SJPromise *> *promises) {
        return [SJPromise promiseWithAny:promises];
    };
}
+ (SJPromise * _Nonnull (^)(SJPromiseReturnValue _Nullable))resolve {
    return ^SJPromise *(SJPromiseReturnValue _Nullable value) {
        return [SJPromise promiseWithResolve:value];
    };
}
+ (SJPromise * _Nonnull (^)(NSError * _Nonnull))reject {
    return ^SJPromise *(NSError *error) {
        return [SJPromise promiseWithReject:error];
    };
}
+ (SJPromiseResolvers * _Nonnull (^)(void))withResolvers {
    return ^SJPromiseResolvers *(void) {
        return [SJPromise resolvers];
    };
}
+ (SJPromise * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))firstPriority {
    return ^SJPromise *(NSArray<SJPromise *> *promises) {
        return [SJPromise promiseWithFirstPriority:promises];
    };
}

- (SJPromiseResult * _Nonnull (^)(void))wait {
    return ^SJPromiseResult *(void) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block SJPromiseResult *result;
        [self onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            result = [SJPromiseResult fulfilledResultWithValue:value];
            dispatch_semaphore_signal(semaphore);
            return nil;
        }];
        [self onRejected:^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
            result = [SJPromiseResult rejectedResultWithError:error];
            dispatch_semaphore_signal(semaphore);
            return nil;
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return result;
    };
}
+ (NSArray<SJPromiseResult *> * _Nonnull (^)(NSArray<SJPromise *> * _Nonnull))join {
    return ^NSArray<SJPromiseResult *> *(NSArray<SJPromise *> *promises) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block NSArray<SJPromiseResult *> *results;
        SJPromise *promise = SJPromise.allSettled(promises);
        [promise onFulfilled:^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            results = value;
            dispatch_semaphore_signal(semaphore);
            return nil;
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return nil;
    };
}
@end

@implementation SJPromiseContinuation(PromiseLike)
- (void (^)(SJPromiseReturnValue _Nullable))resolve {
    return ^(SJPromiseReturnValue _Nullable value) {
        [self resolveWithValue:value];
    };
}

- (void (^)(NSError * _Nonnull))reject {
    return ^(NSError *error) {
        [self rejectWithError:error];
    };
}
@end

@implementation SJPromise(Extensions)
+ (SJPromise * _Nonnull (^)(SJPromiseContinuationHandler _Nonnull))retryable {
    return ^SJPromise *(SJPromiseContinuationHandler retryableBlock) {
        return [SJPromise retryablePromiseWithHandler:retryableBlock];
    };
}

+ (SJPromise * _Nonnull (^)(SJPromiseContinuationHandler _Nonnull))lazy {
    return ^SJPromise *(SJPromiseContinuationHandler block) {
        return [SJPromise lazyPromiseWithHandler:block];
    };
}

+ (SJPromise * _Nonnull (^)(SJPromiseContinuationHandler _Nonnull))lazyAndRetryable {
    return ^SJPromise *(SJPromiseContinuationHandler retryableBlock) {
        return [SJPromise lazyAndRetryablePromiseWithHandler:retryableBlock];
    };
}

+ (SJPromise * _Nonnull (^)(dispatch_queue_t _Nonnull, SJPromiseContinuationHandler _Nonnull))promiseOnQueue {
    return ^SJPromise *(dispatch_queue_t queue, SJPromiseContinuationHandler handler) {
        return [SJPromise promiseWithQueue:queue lazy:NO retryable:NO handler:handler];
    };
}

- (SJPromise * _Nonnull (^)(dispatch_queue_t _Nonnull, SJPromiseFulfillmentHandler _Nonnull))thenOnQueue {
    return ^SJPromise *(dispatch_queue_t queue, SJPromiseFulfillmentHandler handler) {
        SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithQueue:queue fulfillmentHandler:handler rejectionHandler:nil];
        [self addContinuationPromise:promise];
        return promise;
    };
}

- (SJPromise * _Nonnull (^)(dispatch_queue_t _Nonnull, SJPromiseRejectionHandler _Nonnull))catchOnQueue {
    return ^SJPromise *(dispatch_queue_t queue, SJPromiseRejectionHandler handler) {
        SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithQueue:queue fulfillmentHandler:nil rejectionHandler:handler];
        [self addContinuationPromise:promise];
        return promise;
    };
}

- (SJPromise * _Nonnull (^)(dispatch_queue_t _Nonnull, SJPromiseFinalityHandler _Nonnull))finallyOnQueue {
    return ^SJPromise *(dispatch_queue_t queue, SJPromiseFinalityHandler handler) {
        SJContinuationPromise *promise = [SJContinuationPromise.alloc initWithQueue:queue finalityHandler:handler];
        [self addContinuationPromise:promise];
        return promise;
    };
}
@end

#pragma mark - errors

NSErrorDomain const SJPromiseErrorDomain = @"SJPromiseErrorDomain";
NSErrorUserInfoKey const SJPromiseAggregateErrorsKey = @"SJPromiseAggregateErrorsKey"; // value type is NSArray<NSError *> *;
