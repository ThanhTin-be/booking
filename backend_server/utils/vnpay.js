const crypto = require('crypto');
const qs = require('qs');

/**
 * Sắp xếp object theo key + encode values
 * Copy CHÍNH XÁC từ demo VNPay NodeJS
 */
function sortObject(obj) {
    let sorted = {};
    let str = [];
    let key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) {
            str.push(encodeURIComponent(key));
        }
    }
    str.sort();
    for (key = 0; key < str.length; key++) {
        sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, '+');
    }
    return sorted;
}

/**
 * Tạo URL thanh toán VNPay
 */
function createPaymentUrl({ amount, orderId, orderInfo, ipAddr, bankCode, returnUrl }) {
    const tmnCode = process.env.VNP_TMN_CODE;
    const secretKey = process.env.VNP_HASH_SECRET;
    const vnpUrl = process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

    if (!tmnCode || !secretKey) {
        throw new Error('VNPay chưa được cấu hình. Vui lòng kiểm tra VNP_TMN_CODE và VNP_HASH_SECRET trong .env và restart server.');
    }

    const date = new Date();
    const createDate = formatDate(date);

    // Expire sau 15 phút
    const expireDate = new Date(date.getTime() + 15 * 60 * 1000);

    var vnp_Params = {};
    vnp_Params['vnp_Version'] = '2.1.0';
    vnp_Params['vnp_Command'] = 'pay';
    vnp_Params['vnp_TmnCode'] = tmnCode;
    vnp_Params['vnp_Locale'] = 'vn';
    vnp_Params['vnp_CurrCode'] = 'VND';
    vnp_Params['vnp_TxnRef'] = orderId;
    vnp_Params['vnp_OrderInfo'] = orderInfo;
    vnp_Params['vnp_OrderType'] = 'other';
    vnp_Params['vnp_Amount'] = amount * 100;
    vnp_Params['vnp_ReturnUrl'] = returnUrl;
    vnp_Params['vnp_IpAddr'] = ipAddr || '127.0.0.1';
    vnp_Params['vnp_CreateDate'] = createDate;
    vnp_Params['vnp_ExpireDate'] = formatDate(expireDate);

    if (bankCode && bankCode !== '') {
        vnp_Params['vnp_BankCode'] = bankCode;
    }

    // Sort + encode (giống demo VNPay chính thức)
    vnp_Params = sortObject(vnp_Params);

    // Tạo signData từ sorted params
    var signData = qs.stringify(vnp_Params, { encode: false });

    // HMAC SHA512
    var hmac = crypto.createHmac('sha512', secretKey);
    var signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest('hex');

    vnp_Params['vnp_SecureHash'] = signed;

    var paymentUrl = vnpUrl + '?' + qs.stringify(vnp_Params, { encode: false });

    console.log('VNPay signData:', signData);
    console.log('VNPay hash:', signed);
    console.log('VNPay URL:', paymentUrl);

    return paymentUrl;
}

/**
 * Xác thực checksum từ VNPay callback (IPN / Return URL)
 */
function verifyChecksum(query) {
    const secretKey = process.env.VNP_HASH_SECRET;

    var vnp_Params = {};
    // Copy tất cả params vnp_
    for (var key in query) {
        if (key.startsWith('vnp_')) {
            vnp_Params[key] = query[key];
        }
    }

    var secureHash = vnp_Params['vnp_SecureHash'];

    delete vnp_Params['vnp_SecureHash'];
    delete vnp_Params['vnp_SecureHashType'];

    vnp_Params = sortObject(vnp_Params);

    var signData = qs.stringify(vnp_Params, { encode: false });
    var hmac = crypto.createHmac('sha512', secretKey);
    var signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest('hex');

    return secureHash === signed;
}

/**
 * Format date thành yyyyMMddHHmmss (timezone Asia/Ho_Chi_Minh)
 */
function formatDate(date) {
    // Convert to Vietnam timezone (UTC+7)
    const pad = (n) => String(n).padStart(2, '0');

    // Sử dụng Intl.DateTimeFormat để lấy chính xác giờ VN
    const formatter = new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Asia/Ho_Chi_Minh',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
    });
    const parts = formatter.formatToParts(date);
    const get = (type) => parts.find(p => p.type === type)?.value || '00';

    return `${get('year')}${get('month')}${get('day')}${get('hour')}${get('minute')}${get('second')}`;
}

module.exports = {
    sortObject,
    createPaymentUrl,
    verifyChecksum,
    formatDate
};
