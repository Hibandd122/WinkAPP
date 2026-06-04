/**
 * Wink Forever VIP Crack — Clean Version
 * Quantumult X MITM Script
 *
 * Intercepts: api-sub.meitu.com/v2/user/vip_info_by_group.json
 * Toggle: $prefs.valueForKey("WinkCrack_Enable") === "false" → bypass
 */

// Bảo vệ: nếu chạy ngoài QX (web browser) thì không lỗi
if (typeof $response === "undefined" || typeof $done === "undefined") {
    // Không chạy trong môi trường MITM — thoát an toàn
    console.log("[WinkCrack] Không phải môi trường Quantumult X, bỏ qua.");
    if (typeof $done === "function") $done({});
}

var headers = $response.headers || {};
// Vô hiệu hóa cache để app lấy data mới nhất mỗi lần pull-to-refresh
headers["Cache-Control"] = "no-store, no-cache, must-revalidate, proxy-revalidate";
headers["Pragma"] = "no-cache";
headers["Expires"] = "0";

// Kiểm tra toggle từ Persistent Store
if (typeof $prefs !== "undefined" && $prefs.valueForKey("WinkCrack_Enable") === "false") {
    // Toggle OFF — cho request đi qua nhưng cập nhật headers
    $done({ headers: headers });
} else {
    // Toggle ON — inject VIP data
    try {
        var body = $response.body;
        var obj  = JSON.parse(body);

        obj["data"] = {
            "active_sub_type":              2,
            "account_type":                  1,
            "sub_type_name":                 "续期",
            "active_sub_order_id":           "7069961436604422668",
            "trial_period_invalid_time":     "",
            "current_order_invalid_time":    "32495508000000",
            "active_order_id":               "7069961436340181123",
            "limit_type":                    0,
            "active_sub_type_name":          "续期",
            "use_vip":                       true,
            "have_valid_contract":           true,
            "derive_type_name":              "普通会员",
            "derive_type":                   1,
            "in_trial_period":               false,
            "is_vip":                        true,
            "membership": {
                "id":              "4",
                "display_name":    "Wink会员",
                "level":           1,
                "level_name":      "普通会员"
            },
            "active_promotion_status_list":  [2],
            "sub_type":                      2,
            "account_id":                    "1230010086",
            "invalid_time":                  "32495529599000",
            "valid_time":                    "1569664800000",
            "active_product_id":             "0",
            "active_promotion_status":       2,
            "show_renew_flag":               true
        };

        $done({ body: JSON.stringify(obj), headers: headers });
    } catch (e) {
        // Parse lỗi → cho đi qua
        console.log("[WinkCrack] Lỗi parse: " + e);
        $done({ headers: headers });
    }
}
