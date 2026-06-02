#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    if ([request.URL.absoluteString containsString:@"api-sub.meitu.com/v2/user/vip_info_by_group.json"]) {
        void (^customCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            // Allow bypassing hack if toggled via User Defaults (assuming you inject a settings bundle later, default is false)
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults boolForKey:@"WinkCrack_Disable"]) {
                if (completionHandler) {
                    completionHandler(data, response, error);
                }
                return;
            }

            if (data && !error) {
                NSError *jsonError;
                NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                
                if (!jsonError && json) {
                    NSMutableDictionary *dataDict = json[@"data"];
                    if (!dataDict || [dataDict isKindOfClass:[NSNull class]]) {
                        dataDict = [NSMutableDictionary dictionary];
                        json[@"data"] = dataDict;
                    }
                    
                    dataDict[@"active_sub_type"] = @2;
                    dataDict[@"account_type"] = @1;
                    dataDict[@"sub_type_name"] = @"续期";
                    dataDict[@"active_sub_order_id"] = @"7069961436604422668";
                    dataDict[@"current_order_invalid_time"] = @"32495508000000";
                    dataDict[@"active_order_id"] = @"7069961436340181123";
                    dataDict[@"use_vip"] = @YES;
                    dataDict[@"have_valid_contract"] = @YES;
                    dataDict[@"derive_type_name"] = @"普通会员";
                    dataDict[@"derive_type"] = @1;
                    dataDict[@"is_vip"] = @YES;
                    dataDict[@"membership"] = @{
                        @"id": @"4",
                        @"display_name": @"Wink会员",
                        @"level": @1,
                        @"level_name": @"普通会员"
                    };
                    dataDict[@"active_promotion_status_list"] = @[@2];
                    dataDict[@"sub_type"] = @2;
                    dataDict[@"invalid_time"] = @"32495529599000";
                    dataDict[@"valid_time"] = @"1569664800000";
                    dataDict[@"active_product_id"] = @"0";
                    dataDict[@"active_promotion_status"] = @2;
                    dataDict[@"show_renew_flag"] = @YES;
                    
                    NSData *newData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (completionHandler) {
                        completionHandler(newData, response, error);
                    }
                    return;
                }
            }
            if (completionHandler) {
                completionHandler(data, response, error);
            }
        };
        
        return %orig(request, customCompletion);
    }
    
    return %orig;
}

%end
