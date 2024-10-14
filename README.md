# SJPromise

like js promise;

## Installation

```ruby
pod 'SJPromise'
```

## Usage

```Objective-C
SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {  // task 1
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // resolve
        complete.resolve(@(1));
        // or reject
        // complete.reject([NSError errorWithXXX]);
    });
}).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) { // task 2
    return xxx; // or return SJPromise.promise(...);
}).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) { // catch error
    return xxx; // or return SJPromise.promise(...);
}).finally(^{  
    NSLog(@"任务结束");
});
```

## Features

- SJPromise.promise: 创建 Promise 执行任务;
- SJPromise.then: 串联一个新的 Promise 到 Promise 链的尾部, 当 Promise 处于 fulfilled 状态时开始执行 block 块任务;
- SJPromise.catch: 串联一个新的 Promise 到 Promise 链的尾部, 当 Promise 处于 rejected 状态时开始执行 block 块任务;
- SJPromise.finally: 串联一个新的 Promise 到 Promise 链的尾部, 当前面的 Promise 执行结束无论成功还是失败都会执行该 block 块任务;

- SJPromise.lazy: 延迟执行任务; 
    类似于懒加载, 当你需要在 Promise 不立刻执行, 而是在有监听操作时才开始执行可以使用 Promise.lazy();
- SJPromise.retryable: 可重试; 
    当你需要在 Promise 处于失败状态, 再次对它进行新的监听操作能自动重试可以使用 Promise.retryable();
- SJPromise.lazyAndRetryable: 延迟执行并且可重试;
    延迟执行到第一次监听操作时, 并且失败后再次监听可重试;
    
- SJPromise.all: 接受一个 Promise 数组, 并返回一个新的 Promise, 它会记录数组中的每个 Promise 的值, 当全部执行成功后返回该数组; 但如果任意一个 promise 执行失败(rejected), 它会立刻 rejected 并直接返回该错误;
    当你需要等待多个 Promise 并发执行, 并且其中任意一个失败就不再继续时可以使用 Promise.all();
- SJPromise.allSettled: 接受一个 Promise 数组, 并返回一个新的 Promise, 它会记录每个 Promise 的执行结果, 当全部执行结束后返回该数组; 返回的值是`NSArray<SJPromiseResult *> *results`, 记录着每个 Promise 的执行结果, 可以通过对应 Promise 的索引获取执行结果;
    用于等待多个 Promise 对象全部完成(无论它们是成功(fulfilled)还是失败(rejected));
- SJPromise.race: 接受一个 Promise 数组, 并返回一个新的 Promise, 它会与第一个执行完成的 Promise 保持相同的状态无论是 fulfilled 还是 rejected;
    当你只关心最先完成的异步操作, 而不在意其他操作的结果时, 可以使用 Promise.race(); 常见的场景包括超时控制;
- SJPromise.any: 接受一个 Promise 数组, 并返回一个新的 Promise; 当数组中任意一个 Promise 成功(fulfilled)时, 它就会返回该成功值; 如果所有 Promise 都失败(rejected), 则返回 SJPromiseErrorCodeAggregateError, 表明所有 Promise 都被 rejected;
    当你需要等待至少一个 Promise 成功, 而不关心其他失败的 Promise 时 可以使用 Promise.any(); 它在处理可能有多个失败, 但你只关心第一个成功结果时非常有用;
- SJPromise.resolve: 返回一个状态为已完成(fulfilled)的 Promise;
    你可以用这个方法将一个普通的值转换为一个已成功的 Promise;
- SJPromise.reject: 返回一个状态为已拒绝(rejected)的 Promise;
    你可以用这个方法返回一个已失败的 Promise;
- SJPromise.withResolvers: 用于创建一个 Promise, 同时包含 resolve 和 reject 这两个回调函数, 允许在外部代码中手动控制 Promise 的解决和拒绝;
- SJPromise.firstPriority: 数组中第一个 Promise 的优先级最高; 优先返回第一个 Promise 成功时的值; 其他 Promise 作为后备, 如果第一个 Promise 执行失败了, 则会取其他 Promise 的值; 如果所有 Promise 都失败(rejected), 则返回 SJPromiseErrorCodeAggregateError, 表明所有 Promise 都被 rejected;

- SJPromise.wait: 阻塞当前线程, 等待 Promise 执行结束;
- SJPromise.join: 传入一个 Promise 数组, 阻塞当前线程, 等待 Promises 执行结束;
- SJPromise.promiseOnQueue, SJPromise.thenOnQueue, SJPromise.catchOnQueue, SJPromise.finallyOnQueue: 在指定的队列上执行block;
