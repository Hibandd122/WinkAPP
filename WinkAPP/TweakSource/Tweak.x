#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ── Toggle state ────────────────────────────────

static NSString *const kDisableKey = @"WinkCrack_Disable";

static BOOL crackEnabled(void) {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableKey];
}

static void setCrackEnabled(BOOL on) {
    [[NSUserDefaults standardUserDefaults] setBool:!on forKey:kDisableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ── Method swizzle helper ───────────────────────

static void swizzle(Class cls, SEL orig, SEL repl) {
    Method m1 = class_getInstanceMethod(cls, orig);
    Method m2 = class_getInstanceMethod(cls, repl);
    if (m1 && m2) {
        if (class_addMethod(cls, orig, method_getImplementation(m2), method_getTypeEncoding(m2))) {
            class_replaceMethod(cls, repl, method_getImplementation(m1), method_getTypeEncoding(m1));
        } else {
            method_exchangeImplementations(m1, m2);
        }
    }
}

// ── Find key window helper ──────────────────────

static UIWindow *findKeyWindow(void) {
    // iOS 13+: prefer the visible key window across all scenes
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.isKeyWindow && !w.hidden && w.bounds.size.width > 1 && w.alpha > 0.01)
                return w;
        }
    }
    // Next: any visible window with reasonable size
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (!w.hidden && w.bounds.size.width > 1 && w.alpha > 0.01)
                return w;
        }
    }
    // Legacy fallback (iOS 12 and below)
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow && !w.hidden && w.bounds.size.width > 1) return w;
    }
    return nil;
}

// ── Floating button manager ─────────────────────

@interface WinkFloatingButton : NSObject
@property (nonatomic, readonly) UIButton *button;
- (instancetype)initWithWindow:(UIWindow *)window;
- (void)refreshLook;
- (void)pingTop;
- (void)showToast:(NSString *)msg;
@end

static WinkFloatingButton *sharedFloating;

@implementation WinkFloatingButton

- (instancetype)initWithWindow:(UIWindow *)window {
    if (self = [super init]) {

        CGFloat size = 48.0, margin = 14.0;
        CGFloat sw = window.bounds.size.width;
        CGFloat sh = window.bounds.size.height;

        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(sw - size - margin, (sh - size) / 2.0, size, size);
        _button.layer.cornerRadius = size / 2.0;
        _button.layer.shadowColor = [UIColor blackColor].CGColor;
        _button.layer.shadowOffset = CGSizeMake(0, 2);
        _button.layer.shadowRadius = 6;
        _button.layer.shadowOpacity = 0.5;
        _button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        [_button addAction:[UIAction actionWithHandler:^(__kindof UIAction *a) {
            [self onTap];
        }] forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(onPan:)];
        [_button addGestureRecognizer:pan];

        [self refreshLook];
        
        // Restore position
        NSString *posStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"WinkCrack_BtnPos"];
        if (posStr) {
            CGPoint p = CGPointFromString(posStr);
            // Validate point is within screen
            if (p.x > 0 && p.y > 0 && p.x < sw && p.y < sh) {
                _button.center = p;
            }
        }
        
        [window addSubview:_button];
        [window bringSubviewToFront:_button];
    }
    return self;
}

- (void)refreshLook {
    BOOL on = crackEnabled();
    _button.backgroundColor = on
        ? [UIColor colorWithRed:0.22 green:0.76 blue:0.31 alpha:0.90]
        : [UIColor colorWithRed:0.88 green:0.28 blue:0.25 alpha:0.90];
    [_button setTitle:on ? @"ON" : @"OFF" forState:UIControlStateNormal];
}

- (void)pingTop {
    if (_button.superview) [_button.superview bringSubviewToFront:_button];
}

- (void)onTap {
    BOOL wasOn = crackEnabled(), nowOn = !wasOn;
    setCrackEnabled(nowOn);
    [self refreshLook];

    // Xoá cache để app có thể lấy data mới mà không cần thoát
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // Phát Notification giả lập app vừa được mở lại để ép Wink tự động load lại dữ liệu
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    _button.transform = CGAffineTransformMakeScale(1.25, 1.25);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5
          initialSpringVelocity:0.5 options:0
                     animations:^{ _button.transform = CGAffineTransformIdentity; }
                     completion:nil];

    // Tự động trigger viewWillAppear của trang hiện tại để làm mới UI ngay lập tức
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *kw = findKeyWindow();
        UIViewController *topVC = kw.rootViewController;
        while (topVC.presentedViewController) topVC = topVC.presentedViewController;
        if ([topVC isKindOfClass:[UITabBarController class]]) topVC = ((UITabBarController *)topVC).selectedViewController;
        if ([topVC isKindOfClass:[UINavigationController class]]) topVC = ((UINavigationController *)topVC).visibleViewController;
        
        if (topVC) {
            [topVC viewWillAppear:NO];
            [topVC viewDidAppear:NO];
        }
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ 
                       NSString *msg = nowOn ? @"VIP Crack BẬT\nĐã tự động làm mới VIP!" 
                                             : @"VIP Crack TẮT\nĐã tự động làm mới VIP!";
                       [self showToast:msg]; 
                   });
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    UIView *sv = _button.superview; if (!sv) return;
    CGPoint t = [pan translationInView:sv];
    CGPoint c = CGPointMake(_button.center.x + t.x, _button.center.y + t.y);
    CGFloat half = _button.bounds.size.width / 2.0, pad = 8.0;
    CGFloat sw = sv.bounds.size.width, sh = sv.bounds.size.height;
    c.x = MAX(half + pad, MIN(sw - half - pad, c.x));
    c.y = MAX(half + pad + sv.safeAreaInsets.top,
              MIN(sh - half - pad - sv.safeAreaInsets.bottom, c.y));
    _button.center = c;
    [pan setTranslation:CGPointZero inView:sv];
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(_button.center) forKey:@"WinkCrack_BtnPos"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)showToast:(NSString *)msg {
    UIWindow *w = findKeyWindow();
    if (!w) return;

    UILabel *toast = [[UILabel alloc] init];
    toast.text = msg;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    toast.numberOfLines = 0;
    toast.layer.cornerRadius = 12;
    toast.layer.masksToBounds = YES;

    CGSize max = CGSizeMake(w.bounds.size.width - 60, 100);
    CGSize sz = [toast sizeThatFits:max];
    toast.frame = CGRectMake(0, 0, sz.width + 32, sz.height + 16);
    toast.center = CGPointMake(w.bounds.size.width / 2, w.bounds.size.height - 120);
    toast.alpha = 0;
    toast.transform = CGAffineTransformMakeScale(0.8, 0.8);

    [w addSubview:toast];

    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.alpha = 1;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toast.alpha = 0;
            toast.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end

// ── Add button to best available window ──────────

static void tryAddButton(int attempt);

static void ensureButton(void) {
    if (sharedFloating) return;
    tryAddButton(0);
}

static void tryAddButton(int attempt) {
    if (sharedFloating) return;
    UIWindow *w = findKeyWindow();
    if (w) {
        sharedFloating = [[WinkFloatingButton alloc] initWithWindow:w];
        return;
    }
    // Self-retry up to 10 times with increasing delay: 0.3, 0.6, 0.9, ...
    if (attempt < 10) {
        CGFloat delay = 0.3 * (attempt + 1);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ tryAddButton(attempt + 1); });
    }
}

// ── Swizzled viewDidAppear (most reliable trigger) ──

__attribute__((used)) static void swizzled_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)(self, @selector(swizzled_viewDidAppear:), animated);
    if (!sharedFloating) {
        // Keep trying until button is successfully added
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ ensureButton(); });
    }
    if (sharedFloating) [sharedFloating refreshLook];
}

// ── Swizzled addSubview (keep button on top) ────

__attribute__((used)) static void swizzled_addSubview(id self, SEL _cmd, UIView *view) {
    ((void (*)(id, SEL, UIView *))objc_msgSend)(self, @selector(swizzled_addSubview:), view);
    if (sharedFloating && view != sharedFloating.button) {
        dispatch_async(dispatch_get_main_queue(), ^{ [sharedFloating pingTop]; });
    }
}

// ── Swizzled setBounds (screen rotation) ────────

__attribute__((used)) static void swizzled_setBounds(id self, SEL _cmd, CGRect bounds) {
    ((void (*)(id, SEL, CGRect))objc_msgSend)(self, @selector(swizzled_setBounds:), bounds);
    if (sharedFloating) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIButton *b = sharedFloating.button;
            CGFloat half = b.bounds.size.width / 2.0, pad = 8.0;
            CGPoint c = b.center;
            c.x = MAX(half + pad, MIN(bounds.size.width - half - pad, c.x));
            c.y = MAX(half + pad + ((UIWindow *)self).safeAreaInsets.top,
                      MIN(bounds.size.height - half - pad - ((UIWindow *)self).safeAreaInsets.bottom, c.y));
            b.center = c;
        });
    }
}

// ── Swizzled becomeKeyWindow (best trigger) ────

__attribute__((used)) static void swizzled_becomeKeyWindow(id self, SEL _cmd) {
    ((void (*)(id, SEL))objc_msgSend)(self, @selector(swizzled_becomeKeyWindow));
    if (!sharedFloating) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ ensureButton(); });
    }
    if (sharedFloating) [sharedFloating pingTop];
}

// ── Swizzled NSURLSession ───────────────────────

typedef NSURLSessionDataTask * (*DataTaskIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));

static DataTaskIMP orig_dataTask;

__attribute__((used)) static NSURLSessionDataTask *swizzled_dataTask(id self, SEL _cmd, NSURLRequest *req, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    if ([req.URL.absoluteString containsString:@"api-sub.meitu.com/v2/user/vip_info_by_group.json"]) {

        void (^wrapped)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!crackEnabled()) {
                if (handler) handler(data, response, error);
                return;
            }
            if (data && !error) {
                NSError *je;
                NSMutableDictionary *json = [NSJSONSerialization
                    JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&je];
                if (!je && json) {
                    NSMutableDictionary *d = json[@"data"];
                    if (!d || [d isKindOfClass:[NSNull class]]) {
                        d = [NSMutableDictionary dictionary];
                        json[@"data"] = d;
                    }
                    d[@"active_sub_type"] = @2;
                    d[@"account_type"] = @1;
                    d[@"sub_type_name"] = @"VIP";
                    d[@"active_sub_order_id"] = @"7069961436604422668";
                    d[@"current_order_invalid_time"] = @"32495508000000";
                    d[@"active_order_id"] = @"7069961436340181123";
                    d[@"use_vip"] = @YES;
                    d[@"have_valid_contract"] = @YES;
                    d[@"derive_type_name"] = @"VIP";
                    d[@"derive_type"] = @1;
                    d[@"is_vip"] = @YES;
                    d[@"membership"] = @{
                        @"id": @"4",
                        @"display_name": @"Wink VIP",
                        @"level": @1,
                        @"level_name": @"VIP"
                    };
                    d[@"active_promotion_status_list"] = @[@2];
                    d[@"sub_type"] = @2;
                    d[@"invalid_time"] = @"32495529599000";
                    d[@"valid_time"] = @"1569664800000";
                    d[@"active_product_id"] = @"0";
                    d[@"active_promotion_status"] = @2;
                    d[@"show_renew_flag"] = @YES;

                    NSData *nd = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (handler) handler(nd, response, error);
                    return;
                }
            }
            if (handler) handler(data, response, error);
        };

        return orig_dataTask(self, _cmd, req, wrapped);
    }
    return orig_dataTask(self, _cmd, req, handler);
}

// ── Constructor — called when dylib loads ───────

__attribute__((constructor))
static void winkcrack_init(void) {
    // Hook viewDidAppear — most reliable (fires after UI is ready)
    Class vcClass = objc_getClass("UIViewController");
    if (vcClass) {
        swizzle(vcClass, @selector(viewDidAppear:), @selector(swizzled_viewDidAppear:));
    }

    // Hook UIWindow for button z-order, rotation, and key-window detection
    Class winClass = objc_getClass("UIWindow");
    if (winClass) {
        swizzle(winClass, @selector(becomeKeyWindow), @selector(swizzled_becomeKeyWindow));
        swizzle(winClass, @selector(addSubview:), @selector(swizzled_addSubview:));
        swizzle(winClass, @selector(setBounds:), @selector(swizzled_setBounds:));
    }

    // Hook NSURLSession for API interception
    Class sessClass = objc_getClass("NSURLSession");
    if (sessClass) {
        Method m = class_getInstanceMethod(sessClass,
            @selector(dataTaskWithRequest:completionHandler:));
        if (m) {
            orig_dataTask = (DataTaskIMP)method_getImplementation(m);
            method_setImplementation(m, (IMP)swizzled_dataTask);
        }
    }

    // Fallback: also try adding button when app becomes active
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
        object:nil queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ ensureButton(); });
        }];
}
