//
//  SJPromise.h
//
//  Created by changsanjiang on 2020/9/18.
//

#import <Foundation/Foundation.h>
@class SJPromise, SJPromiseContinuation, SJPromiseResult, SJPromiseResolvers;

NS_ASSUME_NONNULL_BEGIN
typedef id PromiseOrObjectOrNil;
typedef PromiseOrObjectOrNil SJPromiseReturnValue;

typedef void(^SJPromiseContinuationHandler)(SJPromiseContinuation *continuation);
typedef SJPromiseReturnValue _Nullable (^SJPromiseFulfillmentHandler)(id _Nullable value);
typedef SJPromiseReturnValue _Nullable (^SJPromiseRejectionHandler)(NSError *error);
typedef void(^SJPromiseFinalityHandler)(void);

@interface SJPromise : NSObject

@end

@interface SJPromise (PromiseLike)
/// 创建一个 Promise 执行任务;
///
/// 该 block 将会在子线程执行;
///
/// 任务结束后请务必在 block 中调用`continuation.resolve 或 continuation.reject`把执行结果通知给 Promise;
@property (nonatomic, copy, readonly, class) SJPromise *(^promise)(SJPromiseContinuationHandler block);

/// 串联一个新的 Promise 到 Promise 链的尾部, 当 Promise 处于 fulfilled 状态时开始执行 block 块任务;
///
/// Promise 链会传递状态给下一个 Promise, 当状态为 fulfilled 时开始执行 block 块任务;
///
/// 该 block 在子线程执行;
///
/// 回调块中的返回值可以是:
///     1. 返回 普通值; 这时 Promise 会将该值传递给 Promise 链中的下一个 Promise;
///     2. 返回 Promise; 此时会等待返回的 Promise 执行结束, 才会将执行结果传递给下一个 Promise;
///
/// 注意: 与 js 中的 then 方法有两个参数不同, 该方法仅处理 onFulfilled 函数, 不提供 onRejected 函数;
@property (nonatomic, copy, readonly) SJPromise *(^then)(SJPromiseFulfillmentHandler block);

/// 串联一个新的 Promise 到 Promise 链的尾部, 当 Promise 处于 rejected 状态时开始执行 block 块任务;
///
/// Promise 链会传递状态给下一个 Promise, 当状态为 rejected 时开始执行 block 块任务;
///
/// 该 block 块将会在子线程执行;
///
/// 回调块中返回的值可以是：
///     1. 返回 普通值; 这时 Promise 会将该值传递给 Promise 链中的下一个 Promise;
///     2. 返回 Promise; 此时会等待返回的 Promise 执行结束, 才会将执行结果传递给下一个 Promise;
@property (nonatomic, copy, readonly) SJPromise *(^catch)(SJPromiseRejectionHandler block);

/// 串联一个新的 Promise 到 Promise 链的尾部, 当前面的 Promise 执行结束无论成功还是失败都会执行该 block 块任务;
///
/// 该 block 块将会在子线程执行;
@property (nonatomic, copy, readonly) SJPromise *(^finally)(SJPromiseFinalityHandler block);

/// 接受一个 Promise 数组, 并返回一个新的 Promise; 这个新的 Promise 将等待数组中的 promise 全部执行成功(fulfilled) 此时新的 Promise 也会 fulfilled 并返回`value数组`;
/// 但如果数组中的任意一个 promise 失败(rejected), 新的 Promise 会 rejected 并直接返回该错误;
///
/// 并发执行;
///
/// 返回的值是`value数组`, 可以通过对应 promise 的索引获取值;
///
/// 当你需要等待多个 Promise 并发执行, 并且其中任意一个失败就不再继续时可以使用 Promise.all();
@property (nonatomic, copy, readonly, class) SJPromise *(^all)(NSArray<SJPromise *> *promises);

/// 接受一个 Promise 数组, 并返回一个新的 Promise; 这个新的 Promise 将等待数组中的 promise 全部执行完成(无论它们是 fulfilled 还是 rejected), 此时新的 Promise 也会 fulfilled;
///
/// 并发执行;
///
/// 返回的值是`NSArray<SJPromiseResult *> *results`, 记录着每个 promise 的执行结果, 可以通过对应 promise 的索引获取执行结果;
///
/// 用于等待多个 Promise 对象全部完成(无论它们是成功(fulfilled)还是失败(rejected)).
@property (nonatomic, copy, readonly, class) SJPromise *(^allSettled)(NSArray<SJPromise *> *promises);

/// 接受一个 Promise 数组, 并返回一个新的 Promise; 这个新的 Promise 将与第一个完成的 Promise(无论是成功或失败)保持相同的状态(fulfilled 或 rejected);
///
/// 并发执行;
///
/// 当你只关心最先完成的异步操作, 而不在意其他异步操作的结果时, 可以使用 Promise.race(); 常见的场景包括超时控制;
@property (nonatomic, copy, readonly, class) SJPromise *(^race)(NSArray<SJPromise *> *promises);

/// 接受一个 Promise 数组, 并返回一个新的 Promise; 当数组中任意一个 Promise 成功(fulfilled)时, 它就会返回该成功值;
/// 如果所有 Promise 都失败(rejected), 则返回 SJPromiseErrorCodeAggregateError, 表明所有 Promise 都被 rejected;
///
/// 当你需要等待至少一个 Promise 成功, 而不关心其他失败的 Promise 时 可以使用 Promise.any(); 它在处理可能有多个失败, 但你只关心第一个成功结果时非常有用;
@property (nonatomic, copy, readonly, class) SJPromise *(^any)(NSArray<SJPromise *> *promises);

/// 返回一个状态为已完成(fulfilled)的 Promise;
///
/// 你可以用这个方法将一个普通的值转换为一个已成功的 Promise;
@property (nonatomic, copy, readonly, class) SJPromise *(^resolve)(SJPromiseReturnValue _Nullable value);

/// 返回一个状态为已拒绝(rejected)的 Promise;
///
/// 你可以用这个方法返回一个已失败的 Promise;
@property (nonatomic, copy, readonly, class) SJPromise *(^reject)(NSError *error);

/// 用于创建一个 Promise, 同时包含 resolve 和 reject 这两个回调函数, 允许在外部代码中手动控制 Promise 的解决和拒绝;
///
@property (nonatomic, copy, readonly, class) SJPromiseResolvers *(^withResolvers)(void);

/// 数组中第一个 Promise 的优先级最高; 优先返回第一个 Promise 成功时的值;
///
/// 其他 Promise 作为后备, 如果第一个 Promise 执行失败了, 则会取其他 Promise 的值;
///
/// 如果所有 Promise 都失败(rejected), 则返回 SJPromiseErrorCodeAggregateError, 表明所有 Promise 都被 rejected;
@property (nonatomic, copy, readonly, class) SJPromise *(^firstPriority)(NSArray<SJPromise *> *promises);
@end

@interface SJPromiseContinuation: NSObject

@end

@interface SJPromiseContinuation(PromiseLike)
/// 用于通知 Promise 处理结束;
///
///
/// 传入的值可以是：
///     1. 传入 普通值; 这时 Promise 将直接进入 fulfilled 状态;
///     2. 传入 Promise; 当前 Promise 会等待传入的 Promise 执行结束, 最终状态会与传入的 Promise 保持一致;
@property (nonatomic, copy, readonly) void(^resolve)(SJPromiseReturnValue _Nullable value);

/// 用于通知 Promise 处理失败;
@property (nonatomic, copy, readonly) void(^reject)(NSError *error);
@end


@interface SJPromise (Extensions)
/// 可重试;
///
/// 如果 Promise 执行失败(rejected), 进行新的订阅操作(then 或 fail 这两个订阅操作)就会触发重试, 即重新执行 retryableBlock, 新的执行结果会回调给执行期间发生的订阅;
///
/// 也就是说当 Promise 处于失败状态, 当发生了新的订阅操作时就会触发重试, retryableBlock 将被重新执行, Promise 的状态也会被重置为 pending, 并等待执行完毕, 期间发生的订阅将在执行完毕后进行回调;
///
/// 要留意是否会造成循环引用, 以防止 retryableBlock 中的内存泄露;
///
/// 当你需要在 Promise 处于失败状态, 对它进行新的订阅操作时能自动重试可以使用 Promise.retryable();
@property (nonatomic, copy, readonly, class) SJPromise *(^retryable)(SJPromiseContinuationHandler retryableBlock);

/// 延迟执行;
///
/// 延迟 block 块的执行到第一次订阅操作时;
///
/// block 块不会立即执行, 而是等待第一次订阅操作时才开始执行块;
///
/// 当你需要在 Promise 不立刻执行, 而是延迟到第一次订阅操作时才开始执行可以使用 Promise.lazy();
@property (nonatomic, copy, readonly, class) SJPromise *(^lazy)(SJPromiseContinuationHandler block);

/// 延迟执行并且可重试;
///
/// 延迟 block 块的执行到第一次订阅操作时, 并且可重试;
@property (nonatomic, copy, readonly, class) SJPromise *(^lazyAndRetryable)(SJPromiseContinuationHandler retryableBlock);

/// 在指定的队列上执行block;
@property (nonatomic, copy, readonly, class) SJPromise *(^promiseOnQueue)(dispatch_queue_t queue, SJPromiseContinuationHandler block);
/// 在指定的队列上执行block;
@property (nonatomic, copy, readonly) SJPromise *(^thenOnQueue)(dispatch_queue_t queue, SJPromiseFulfillmentHandler block);
/// 在指定的队列上执行block;
@property (nonatomic, copy, readonly) SJPromise *(^catchOnQueue)(dispatch_queue_t queue, SJPromiseRejectionHandler block);
/// 在指定的队列上执行block;
@property (nonatomic, copy, readonly) SJPromise *(^finallyOnQueue)(dispatch_queue_t queue, SJPromiseFinalityHandler block);
@end


@interface SJPromiseResult : NSObject
@property (nonatomic, readonly) BOOL isFulfilled;
@property (nonatomic, strong, readonly, nullable) id value;
@property (nonatomic, strong, readonly, nullable) NSError *error;
@end


@interface SJPromiseResolvers : SJPromise
/// 用于通知 Promise 处理结束;
@property (nonatomic, copy, readonly) void(^resolve)(SJPromiseReturnValue _Nullable value);
/// 用于通知 Promise 处理失败;
@property (nonatomic, copy, readonly) void(^reject)(NSError *error);
@end

#pragma mark - errors

FOUNDATION_EXPORT NSErrorDomain const SJPromiseErrorDomain;
FOUNDATION_EXPORT NSErrorUserInfoKey const SJPromiseAggregateErrorsKey; // value type is NSArray<NSError *> *;

typedef NS_ENUM(NSUInteger, SJPromiseErrorCode) {
    SJPromiseErrorCodeAggregateError = -1000,
};
NS_ASSUME_NONNULL_END
