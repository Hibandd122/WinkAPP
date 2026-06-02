#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Floating Toggle Button

static UIButton *toggleButton;
static NSString *const kDisableKey = @"WinkCrack_Disable";

static BOOL crackEnabled(void) {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableKey];
}

static void setCrackEnabled(BOOL on) {
    [[NSUserDefaults standardUserDefaults] setBool:!on forKey:kDisableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void updateButtonAppearance(void) {
    BOOL on = crackEnabled();
    toggleButton.backgroundColor = on
        ? [UIColor colorWithRed:0.25 green:0.78 blue:0.35 alpha:0.88]
        : [UIColor colorWithRed:0.90 green:0.30 blue:0.28 alpha:0.88];
    [toggleButton setTitle:on ? @"ON" : @"OFF" forState:UIControlStateNormal];
}

static void killApp(void) {
    UIControl *ctl = [[UIControl alloc] init];
    [ctl sendAction:@selector(suspend) to:[UIApplication sharedApplication] forEvent:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

static void showResetAlert(void) {
    UIWindow *kw = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            kw = ((UIWindowScene *)scene).windows.firstObject;
            break;
        }
    }
    UIViewController *root = kw.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Wink VIP"
        message:@"VIP Crack da BAT.\nApp se thoat de ap dung.\nMo lai Wink sau do."
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK - Thoat App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        killApp();
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"De sau" style:UIAlertActionStyleCancel handler:nil]];

    [root presentViewController:alert animated:YES completion:nil];
}

static void onButtonTap(void) {
    BOOL wasOn = crackEnabled();
    BOOL nowOn = !wasOn;
    setCrackEnabled(nowOn);
    updateButtonAppearance();

    toggleButton.transform = CGAffineTransformMakeScale(1.25, 1.25);
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:0
                     animations:^{ toggleButton.transform = CGAffineTransformIdentity; }
                     completion:nil];

    if (nowOn && !wasOn) {
        showResetAlert();
    }
}

static void addFloatingButton(UIWindow *window) {
    if (toggleButton) return;

    CGFloat size = 48.0;
    CGFloat margin = 12.0;
    CGFloat screenW = window.bounds.size.width;
    CGFloat screenH = window.bounds.size.height;

    toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    toggleButton.frame = CGRectMake(screenW - size - margin,
                                     (screenH - size) / 2.0,
                                     size, size);
    toggleButton.layer.cornerRadius = size / 2.0;
    toggleButton.layer.shadowColor = [UIColor blackColor].CGColor;
    toggleButton.layer.shadowOffset = CGSizeMake(0, 2);
    toggleButton.layer.shadowRadius = 6;
    toggleButton.layer.shadowOpacity = 0.45;
    toggleButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [toggleButton addTarget:toggleButton action:@selector(wk_tapped:) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:toggleButton action:@selector(wk_panned:)];
    [toggleButton addGestureRecognizer:pan];

    updateButtonAppearance();
    [window addSubview:toggleButton];
}

// UIButton category for floating button actions

@interface UIButton (WinkCrack)
- (void)wk_tapped:(id)sender;
- (void)wk_panned:(UIPanGestureRecognizer *)pan;
@end

@implementation UIButton (WinkCrack)

- (void)wk_tapped:(id)sender {
    onButtonTap();
}

- (void)wk_panned:(UIPanGestureRecognizer *)pan {
    CGPoint t = [pan translationInView:self.superview];
    CGPoint c = CGPointMake(self.center.x + t.x, self.center.y + t.y);

    CGFloat half = self.bounds.size.width / 2.0;
    CGFloat pad = 8.0;
    CGFloat sw = self.superview.bounds.size.width;
    CGFloat sh = self.superview.bounds.size.height;

    c.x = MAX(half + pad, MIN(sw - half - pad, c.x));
    c.y = MAX(half + pad + self.superview.safeAreaInsets.top,
              MIN(sh - half - pad - self.superview.safeAreaInsets.bottom, c.y));

    self.center = c;
    [pan setTranslation:CGPointZero inView:self.superview];
}

@end

// Hook: Add floating button after window is visible

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    if (!toggleButton) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            addFloatingButton(self);
        });
    }
}

%end

// Hook: Intercept API response to inject VIP data

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
