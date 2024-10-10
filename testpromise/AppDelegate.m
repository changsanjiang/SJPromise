//
//  AppDelegate.m
//  testpromise
//
//  Created by db on 2024/9/19.
//

#import "AppDelegate.h"
@interface A : NSObject
@property (nonatomic, copy, nullable) void(^block)(A *a);
@property (nonatomic, copy, nullable) void(^block2)(A *a, NSNumber *b);
- (void)performBlock;
- (void)performBlock2;
@end

@implementation A
- (void)performBlock {
    if ( _block ) _block(self);
}

- (void)performBlock2 {
    if ( _block2 ) _block2(self, @(12));
}
@end

@interface B : NSObject
- (void)test;
@end


@implementation B
- (void)test {
    NSNumber *n123 = @(13);
    A *a = [[A alloc] init];
    a.block = ^(A *a) {
        NSLog(@"before: %@", self);
        NSLog(@"before n123: %@", n123);
        a.block = nil;
        if ( self == nil  ) { }
        if ( n123 == nil  ) { }
    };
    
    [a performBlock];
    
    a.block2 = ^(A *a, NSNumber *b) {
        NSLog(@"before: %@", self);
        NSLog(@"before n123: %@", n123);
        a.block = nil;
        if ( self == nil  ) { }
        if ( n123 == nil  ) { }
    };
    
    [a performBlock2];
}
@end
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    _window = [UIWindow.alloc initWithFrame:UIScreen.mainScreen.bounds];
    _window.backgroundColor = UIColor.whiteColor;
    _window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
