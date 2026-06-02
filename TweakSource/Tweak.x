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

// ── Floating button manager ─────────────────────

@interface WinkFloatingButton : NSObject
@property (nonatomic, readonly) UIButton *button;
- (instancetype)initWithWindow:(UIWindow *)window;
- (void)refreshLook;
- (void)pingTop;
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

    _button.transform = CGAffineTransformMakeScale(1.25, 1.25);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5
          initialSpringVelocity:0.5 options:0
                     animations:^{ _button.transform = CGAffineTransformIdentity; }
                     completion:nil];

    if (nowOn && !wasOn) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [self showResetAlert]; });
    }
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
}

- (void)showResetAlert {
    UIWindow *kw = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            kw = ((UIWindowScene *)scene).windows.firstObject;
            if (kw) break;
        }
    }
    UIViewController *root = kw.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    if (!root) return;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Wink VIP"
        message:@"VIP Crack da BAT.\nApp se thoat de ap dung.\nMo lai Wink sau do."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK - Thoat App" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            UIControl *ctl = [[UIControl alloc] init];
            [ctl sendAction:@selector(suspend) to:[UIApplication sharedApplication] forEvent:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ exit(0); });
        }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"De sau" style:UIAlertActionStyleCancel handler:nil]];
    [root presentViewController:alert animated:YES completion:nil];
}

@end

// ── Swizzled UIWindow methods ───────────────────

static void swizzled_makeKeyAndVisible(id self, SEL _cmd) {
    // Call original (we swapped IMPs, so calling this selector runs the original)
    ((void (*)(id, SEL))objc_msgSend)(self, @selector(swizzled_makeKeyAndVisible));

    if (!sharedFloating) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (!sharedFloating) {
                sharedFloating = [[WinkFloatingButton alloc] initWithWindow:(UIWindow *)self];
            }
        });
    }
}

static void swizzled_addSubview(id self, SEL _cmd, UIView *view) {
    ((void (*)(id, SEL, UIView *))objc_msgSend)(self, @selector(swizzled_addSubview:), view);
    if (sharedFloating && view != sharedFloating.button) {
        dispatch_async(dispatch_get_main_queue(), ^{ [sharedFloating pingTop]; });
    }
}

static void swizzled_setBounds(id self, SEL _cmd, CGRect bounds) {
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

// ── Swizzled NSURLSession ───────────────────────

typedef NSURLSessionDataTask * (*DataTaskIMP)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));

static DataTaskIMP orig_dataTask;

static NSURLSessionDataTask *swizzled_dataTask(id self, SEL _cmd, NSURLRequest *req, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
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
    // UIWindow hooks
    Class winClass = objc_getClass("UIWindow");
    if (winClass) {
        swizzle(winClass, @selector(makeKeyAndVisible), @selector(swizzled_makeKeyAndVisible));
        swizzle(winClass, @selector(addSubview:), @selector(swizzled_addSubview:));
        swizzle(winClass, @selector(setBounds:), @selector(swizzled_setBounds:));
    }

    // NSURLSession hook — save original IMP
    Class sessClass = objc_getClass("NSURLSession");
    if (sessClass) {
        Method m = class_getInstanceMethod(sessClass,
            @selector(dataTaskWithRequest:completionHandler:));
        if (m) {
            orig_dataTask = (DataTaskIMP)method_getImplementation(m);
            method_setImplementation(m, (IMP)swizzled_dataTask);
        }
    }
}
