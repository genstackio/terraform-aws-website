const buildDefaultResponse = () => ({
    status: '404',
    statusDescription: 'Not Found',
    headers: {
        'cache-control': [{
            key: 'Cache-Control',
            value: 'no-cache'
        }],
        'content-type': [{
            key: 'Content-Type',
            value: 'text/plain'
        }]
    },
    body: 'Not Found',
});

const enrichResponse = response => {
    response.headers = response.headers || {};
    const headers = response.headers;

    headers['strict-transport-security'] = [{key: 'Strict-Transport-Security', value: 'max-age= 63072000; includeSubdomains; preload'}];
    // headers['content-security-policy'] = [{key: 'Content-Security-Policy-Report-Only', value: "default-src 'self'; img-src * 'self'; script-src 'self'; style-src * 'self'"}];
    headers['x-content-type-options'] = [{key: 'X-Content-Type-Options', value: 'nosniff'}];
    headers['x-frame-options'] = [{key: 'X-Frame-Options', value: 'SAMEORIGIN'}];
    headers['x-xss-protection'] = [{key: 'X-XSS-Protection', value: '1; mode=block'}];
    headers['referrer-policy'] = [{key: 'Referrer-Policy', value: 'same-origin'}];
    headers['x-download-options'] = [{key: 'X-Download-Options', value: 'noopen'}];

    return response;
}

module.exports = {
    buildDefaultResponse,
    enrichResponse,
}