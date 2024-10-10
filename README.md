# LWZPromise

like js promise;

## Installation
```ruby
pod 'LWZPromise'
```

```Objective-c
SJPromise.promise(^(LWZPromiseContinuation * _Nonnull complete) {  // task 1
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // resolve
        complete.resolve(@(1));
        // or reject
        // complete.reject([NSError errorWithXXX]);
    });
}).then(^LWZPromiseReturnValue _Nullable(id  _Nullable value) { // task 2
    return xxx; // or return LWZPromise.promise(...);
}).catch(^LWZPromiseReturnValue _Nullable(NSError * _Nonnull error) { // catch error
    return xxx; // or return LWZPromise.promise(...);
}).finally(^{  
    NSLog(@"任务结束");
});
```
