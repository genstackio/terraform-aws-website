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

const isHostMatching = (a, b) => !a ? false : (('string' === typeof a) ? (a === b) : !!b.match(a));
const isUriMatching = (a, b) => !a ? false : (('string' === typeof a) ? (a === b) : !!b.match(a));
const applyTest = (a, b) => !a ? false : (('function' === typeof a) ? !!a(b) : false);
const isCountryMatching = (a, b) => !a ? false : (Array.isArray(a) ? a.includes(b) : (a === b));

const matchRuleAndOptionallyUpdateRule = (rule, context) => {
    let r = undefined;
    // noinspection PointlessBooleanExpressionJS
    rule.host && (r = ((undefined !== r) ? r : true) && isHostMatching(rule.host, context.host));
    rule.uri && (r = ((undefined !== r) ? r : true) && isUriMatching(rule.uri, context.uri));
    rule.country && (r = ((undefined !== r) ? r : true) && isCountryMatching(rule.country, context.country));
    if (rule.test) {
        r = ((undefined !== r) ? r : true);
        const testResult = applyTest(rule.test, context);
        if (!!testResult && ('string' === typeof testResult)) {
            rule.location = testResult;
        }
        r = r && !!testResult;
    }

    return r;
}

const getHostFromRequest = request => (((request.headers || [])['host'] || [])[0] || {}).value;
const getCountryFromRequest = request => (((request.headers || [])['cloudfront-viewer-country'] || [])[0] || {}).value;
const getHeadersFromRequest = request => request.headers || [];

const getUriFromRequest = (request, {refererMode = false} = {}) => {
    if (!refererMode) return request.uri;
    let host = getHostFromRequest(request);
    let referer = (((request.headers || [])["referer"] || [])[0] || {}).value;
    if (host && referer) return referer.split(host)[1];
    return request.uri;
}

const getRedirectResponseIfExistFromConfig = (request, config) => {
    const context = {
        host: getHostFromRequest(request),
        uri: getUriFromRequest(request, config),
        country: getCountryFromRequest(request),
        headers: getHeadersFromRequest(request),
    };
    return ((config || {}).redirects || []).find(
        rule => matchRuleAndOptionallyUpdateRule(rule, context, request)
    );
};

const getRedirectResponseIfExistForRequest = request => {
    let config = require('./config');
    if ('function' === typeof config) config = config(request);

    const rule = getRedirectResponseIfExistFromConfig(request, config);

    return !rule ? undefined : {
        status: rule.status || '302',
        statusDescription: 'Found',
        headers: {
            ...(rule.headers || {}),
            location: [{
                key: 'Location',
                value: rule.location,
            }],
        },
    };
}
const getResponseForRequest = request => getRedirectResponseIfExistForRequest(request) || request;

module.exports = {
    buildDefaultResponse,
    getResponseForRequest,
}