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

const getHeaderFromRequest = (request, name, defaultValue = undefined) => {
    const headers = getHeadersFromRequest(request);
    const value = ((headers[name] || headers[(name || '').toLowerCase()] || [])[0] || {}).value;
    return (undefined === value) ? defaultValue : value;
}
const getHeadersFromRequest = request => request.headers || [];

const getUriFromRequest = (request, {refererMode = false} = {}) => {
    if (!refererMode) return request.uri;
    let host = getHeaderFromRequest(request, 'Host');
    let referer = getHeaderFromRequest(request, 'Referer');
    if (host && referer) return referer.split(host)[1];
    return request.uri;
}

const getRedirectResponseIfExistFromConfig = (request, config) => {
    const context = {
        host: getHeaderFromRequest(request, 'Host'),
        uri: getUriFromRequest(request, config),
        country: getHeaderFromRequest(request, 'CloudFront-Viewer-Country'),
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