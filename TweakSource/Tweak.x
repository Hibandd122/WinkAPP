#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ── Toggle state ────────────────────────────────

static NSString *const kDisableKey = @"WinkCrack_Disable";

static BOOL crackEnabled(void) {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableKey];
}

static void setCrackEnabled(BOOL on) {
    [[NSUserDefaults standardUserDefaults] setBool:!on forKey:kDisableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

        CGFloat size = 48.0;
        CGFloat margin = 14.0;
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

        [_button addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
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
    if (_button.superview) {
        [_button.superview bringSubviewToFront:_button];
    }
}

- (void)onTap {
    BOOL wasOn = crackEnabled();
    BOOL nowOn = !wasOn;
    setCrackEnabled(nowOn);
    [self refreshLook];

    _button.transform = CGAffineTransformMakeScale(1.25, 1.25);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5
          initialSpringVelocity:0.5 options:0
                     animations:^{ _button.transform = CGAffineTransformIdentity; }
                     completion:nil];

    if (nowOn && !wasOn) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self showResetAlert];
        });
    }
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    UIView *sv = _button.superview;
    if (!sv) return;
    CGPoint t = [pan translationInView:sv];
    CGPoint c = CGPointMake(_button.center.x + t.x, _button.center.y + t.y);

    CGFloat half = _button.bounds.size.width / 2.0;
    CGFloat pad = 8.0;
    CGFloat sw = sv.bounds.size.width;
    CGFloat sh = sv.bounds.size.height;
    CGFloat top = sv.safeAreaInsets.top;
    CGFloat bot = sv.safeAreaInsets.bottom;

    c.x = MAX(half + pad, MIN(sw - half - pad, c.x));
    c.y = MAX(half + pad + top, MIN(sh - half - pad - bot, c.y));

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

// ── Hook: Add floating button when window appears ──

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    if (!sharedFloating) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (!sharedFloating) {
                sharedFloating = [[WinkFloatingButton alloc] initWithWindow:self];
            }
        });
    }
}

// Keep button on top whenever any subview is added
- (void)addSubview:(UIView *)view {
    %orig;
    if (sharedFloating && view != sharedFloating.button) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sharedFloating pingTop];
        });
    }
}

// Handle screen rotation — reposition button
- (void)setBounds:(CGRect)bounds {
    %orig;
    if (sharedFloating) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Clamp button position within new bounds
            UIButton *b = sharedFloating.button;
            CGFloat half = b.bounds.size.width / 2.0;
            CGFloat pad = 8.0;
            CGPoint c = b.center;
            c.x = MAX(half + pad, MIN(bounds.size.width - half - pad, c.x));
            c.y = MAX(half + pad + self.safeAreaInsets.top,
                      MIN(bounds.size.height - half - pad - self.safeAreaInsets.bottom, c.y));
            b.center = c;
        });
    }
}

%end

// ── Hook: Intercept API response to inject VIP data ──

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {

    if ([request.URL.absoluteString containsString:@"api-sub.meitu.com/v2/user/vip_info_by_group.json"]) {

        void (^custom)(NSData *, NSURLResponse *, NSError *) =
        ^(NSData *data, NSURLResponse *response, NSError *error) {

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

        return %orig(request, custom);
    }

    return %orig;
}

%end
