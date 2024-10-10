//
//  ViewController.m
//  testpromise
//
//  Created by db on 2024/9/19.
//

#import "ViewController.h"
#import "SJPromise.h"

@implementation ViewController

- (IBAction)test11:(id)sender {
    NSLog(@"测试常规流程");
    SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {  // 任务1
        NSLog(@"执行任务 1 (in promise executor) before");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"执行任务 1 (in promise executor) after");
            // resolve
            complete.resolve(@(1));
        });
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) { // 任务2
        // 测试直接返回结果
        NSLog(@"执行任务 2 (return number), prev=%@", value);
        return @([value integerValue] + 10);
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) { // 任务3
        // 测试返回promise
        NSLog(@"执行任务 3 (return promise), prev=%@", value);
        return SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 3 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 3 (in promise executor) after");
                complete.resolve(@([value integerValue] + 10));
            });
        });
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) { // 任务4
        // 测试promise出错
        NSLog(@"执行任务 4 (return promise), prev=%@", value);
        return SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            // reject
            complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"测试一下报错"
            }]);
        });
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) { // 错误捕获
        NSLog(@"执行任务 5 (catch error)");
        NSLog(@"捕获到异常: %@", error);
        return @(456);
    }).finally(^{ // 结束回调
        NSLog(@"任务结束");
    });
}

- (IBAction)test22:(id)sender {
    NSLog(@"测试异常捕获");
    
    SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
        // reject
        NSLog(@"抛出异常, 此异常应`捕获点 1`捕获...");
        complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"测试异常捕获 reject 1"
        }]);
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        return @(123);
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        return @(123);
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) { // 捕获点 1
        NSLog(@"捕获点 1 捕获到异常: %@", error);
        return nil;
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        return @(123);
    }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        return SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            // reject
            NSLog(@"抛出异常, 此异常应`捕获点 2`捕获...");
            complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"测试新的异常 reject 2"
            }]);
        });
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) { // 捕获点 2
        NSLog(@"捕获点 2 捕获到异常: %@", error);
        return nil;
    }).finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test33:(id)sender {
    NSLog(@"测试异常捕获33");

    SJPromise *promise = SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
        // reject
        complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"测试异常捕获 reject 1"
        }]);
    });
    
    promise.then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        NSLog(@"执行任务");
        return nil;
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        NSLog(@"捕获点 1 捕获到异常: %@", error);
        return nil;
    });
    
    promise.catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        NSLog(@"捕获点 2 捕获到异常: %@", error);
        return nil;
    });
    
    promise.finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test44:(id)sender {
    NSLog(@"测试延迟执行 第一次订阅时执行块");

    NSLog(@"创建promise...");
    SJPromise *promise = SJPromise.lazy(^(SJPromiseContinuation * _Nonnull complete) {
        NSLog(@"执行 lazy 任务 (in promise executor) before");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"执行 lazy 任务 (in promise executor) after");
            // resolve
            complete.resolve(@(1));
        });
    });
    
    NSLog(@"延迟 2 秒后订阅...");
    NSLog(@"delay before...");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"delay after...");
        NSLog(@"开始订阅");
        promise.then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            NSLog(@"then 回调: value=%@", value);
            return nil;
        });
        
        promise.catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
            NSLog(@"fail 回调: error=%@", error);
            return nil;
        });
    });
    
    promise.finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test55:(id)sender {
    NSLog(@"测试 Promise.all()");
    
    NSLog(@"测试任务 1 和 任务 2 同时执行...");
    NSArray<SJPromise *> *promises = @[
        SJPromise.lazyAndRetryable(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 1 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 1 (in promise executor) after");
                // resolve
                complete.resolve(@(1));
            });
        }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
            NSLog(@"执行任务 1 fail 回调");
            return nil;
        }).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            NSLog(@"执行任务 1-1, prev=%@", value);
            return SJPromise.lazyAndRetryable(^(SJPromiseContinuation * _Nonnull complete) {
                NSLog(@"执行任务 1-1 (in promise executor) before");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSLog(@"执行任务 1-1 (in promise executor) after, 返回 11");
                    // resolve
                    complete.resolve(@(11));
                });
            });
        }),
        SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 2 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 2 (in promise executor) after");
                // resolve
                complete.resolve(@(2));
//                complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
//                    NSLocalizedDescriptionKey: @"任务 2 rejected"
//                }]);
            });
        })
    ];
    
    SJPromise.all(promises).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        NSLog(@"then 回调: value=%@", value);
        return nil;
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        NSLog(@"fail 回调: error=%@", error);
        return nil;
    }).finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test66:(id)sender {
    NSLog(@"测试 Promise.race()");
    
    NSLog(@"测试首个promise填充好或报错时就返回...");
    
    NSArray<SJPromise *> *promises = @[
        SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 1 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 1 (in promise executor) after");
                complete.resolve(@"任务 1 resolved");
            });
        }),
        SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 2 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 2 (in promise executor) after");
                complete.resolve(@"任务 2 resolved");
//                complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
//                    NSLocalizedDescriptionKey: @"任务 2 rejected"
//                }]);
            });
        })
    ];
    SJPromise.race(promises).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        NSLog(@"then 回调: value=%@", value);
        return nil;
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        NSLog(@"fail 回调: error=%@", error);
        return nil;
    }).finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test77:(id)sender {
    NSLog(@"测试 Promise.any()");
    
    NSLog(@"测试首个promise填充好时就返回...");
    
    NSArray<SJPromise *> *promises = @[
        SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 1 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 1 (in promise executor) after");
                complete.resolve(@"任务 1 resolved");
//                complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
//                    NSLocalizedDescriptionKey: @"task 1 rejected"
//                }]);
            });
        }),
        SJPromise.promise(^(SJPromiseContinuation * _Nonnull complete) {
            NSLog(@"执行任务 2 (in promise executor) before");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"执行任务 2 (in promise executor) after");
                complete.resolve(@"任务 2 resolved");
//                complete.reject([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
//                    NSLocalizedDescriptionKey: @"task 2 rejected"
//                }]);
            });
        })
    ];
    SJPromise.any(promises).then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
        NSLog(@"then 回调: value=%@", value);
        return nil;
    }).catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
        NSLog(@"fail 回调: error=%@", error);
        return nil;
    }).finally(^{
        NSLog(@"任务结束");
    });
}

- (IBAction)test88:(id)sender {
    NSLog(@"测试 Promise.resolve()");

    SJPromise.resolve(@(123))
        .then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            NSLog(@"then 回调 1: value=%@", value);
            return value;
        })
        .catch(^SJPromiseReturnValue _Nullable(NSError * _Nonnull error) {
            NSLog(@"fail 回调: error=%@", error);
            return nil;
        })
        .then(^SJPromiseReturnValue _Nullable(id  _Nullable value) {
            NSLog(@"then 回调 2: value=%@", value);
            return nil;
        })
        .finally(^{
            NSLog(@"任务结束");
        });
}

@end
