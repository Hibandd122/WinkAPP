/*
 * Shadowrocket / Loon / Quantumult X Script: Comprehensive Quota & VIP Bypass for Wink (Meitu)
 * 
 * 1. Chặn lệnh trừ lượt tiêu hao Cloud Render:
 *    - /v2/function/user/consume.json
 *    - /v1/virtual/account/record/consume.json
 * 2. Giả lập còn 999 lượt dùng thử miễn phí và quyền VIP:
 *    - /v2/function/user/check.json & /v2/function/strategy/free.json
 * 3. Mở khóa gói chức năng dùng thử:
 *    - /v2/entrance/products_by_function.json
 * 4. Mở khóa thông tin VIP và Hợp đồng VIP vĩnh viễn:
 *    - /v2/user/vip_info.json & /v2/contract/sub/get_valid_contract.json
 *    - /v2/transaction/permission_check.json
 *    - /v2/user/login_vip_check.json
 *    - /v2/user/login_limit_check.json
 */

const url = $request.url;

// TRƯỜNG HỢP 1: Chặn Request trừ lượt (REQUEST INTERCEPTION - Trả về thành công ngay lập tức)
if (typeof $response === "undefined") {
    if (url.includes("/v2/function/user/consume.json") || url.includes("/v1/virtual/account/record/consume.json")) {
        console.log("[WinkQuota] [BLOCKED] Request consume quota: " + url);
        $done({
            response: {
                status: 200,
                headers: { 
                    "Content-Type": "application/json; charset=utf-8",
                    "Access-Control-Allow-Origin": "*"
                },
                body: JSON.stringify({
                    code: 0,
                    error_code: "00000",
                    message: "success",
                    data: { consume_status: 1 },
                    success: true
                })
            }
        });
    } else {
        $done({});
    }
} 
// TRƯỜNG HỢP 2: Giả lập Quota & VIP trong Response (RESPONSE MODIFICATION)
else {
    let body = $response.body;
    if (body) {
        try {
            let obj = JSON.parse(body);

            // 1. Quota Check & Strategy Free (AI Repair, Super Resolution, Old Photo Repair)
            if (url.includes("/v2/function/user/check.json") || url.includes("/v2/function/strategy/free.json")) {
                obj.code = 0;
                obj.error_code = "00000";
                obj.message = "success";
                obj.success = true;

                if (!obj.data) obj.data = {};
                obj.data.is_free = true;
                obj.data.is_vip = true;
                obj.data.free_count = 999;
                obj.data.right_count = 999;
                obj.data.consume_count = 0;
                obj.data.limit_val = 999;
                obj.data.have_permission = true;

                if (Array.isArray(obj.data.function_list)) {
                    obj.data.function_list.forEach(f => {
                        f.is_free = true;
                        f.is_vip = true;
                        f.free_count = 999;
                        f.right_count = 999;
                        f.consume_count = 0;
                        f.limit_val = 999;
                    });
                }
                console.log("[WinkQuota] [MOCKED] Quota set to 999 for: " + url);
            }

            // 2. Products by function (Mở khóa cửa vào tính năng)
            else if (url.includes("/v2/entrance/products_by_function.json")) {
                obj.code = 0;
                obj.message = "success";
                obj.success = true;
                if (obj.data) {
                    obj.data.is_free = true;
                    obj.data.free_count = 999;
                    obj.data.have_permission = true;
                }
                console.log("[WinkQuota] [MOCKED] Products by function for: " + url);
            }

            // 3. User VIP Info & Login VIP Check (Bypass VIP tổng)
            else if (url.includes("/v2/user/vip_info.json") || url.includes("/v2/user/login_vip_check.json")) {
                obj.code = 0;
                obj.message = "success";
                obj.success = true;
                obj.data = {
                    is_vip: true,
                    type: 2,
                    type_name: "SVIP",
                    valid_time: 4102444800,
                    invalid_time: 4102444800,
                    have_valid_contract: true,
                    use_vip: true,
                    in_trial_period: false,
                    expire_days: 99999,
                    limit_type: 0
                };
                console.log("[WinkQuota] [MOCKED] VIP Info for: " + url);
            }

            // 4. Valid contracts
            else if (url.includes("/v2/contract/sub/get_valid_contract.json")) {
                obj.code = 0;
                obj.message = "success";
                obj.success = true;
                obj.data = [{
                    product_id: "com.meitu.wink.vip.year",
                    order_id: "999999999999999",
                    status: 1,
                    start_time: 1700000000,
                    end_time: 4102444800,
                    is_valid: true
                }];
                console.log("[WinkQuota] [MOCKED] Contract for: " + url);
            }

            // 5. Permission Check & Login Limit Check
            else if (url.includes("/v2/transaction/permission_check.json")) {
                obj.code = 0;
                obj.message = "success";
                obj.success = true;
                obj.data = { has_permission: true };
                console.log("[WinkQuota] [MOCKED] Permission check for: " + url);
            }
            else if (url.includes("/v2/user/login_limit_check.json")) {
                obj.code = 0;
                obj.message = "success";
                obj.success = true;
                obj.data = { is_limit: false };
                console.log("[WinkQuota] [MOCKED] Login limit check for: " + url);
            }

            $done({ body: JSON.stringify(obj) });
        } catch (e) {
            $done({});
        }
    } else {
        $done({});
    }
}
