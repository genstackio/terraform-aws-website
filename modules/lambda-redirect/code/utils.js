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

const isHostMatching = (a, b) => a === b;
const isUriMatching = (a, b) => a === b;

const isMatchingRule = (rule, context) => {
    let r = undefined;
    // noinspection PointlessBooleanExpressionJS
    rule.host && (r = ((undefined !== r) ? r : true) && isHostMatching(rule.host, context.host));
    rule.uri && (r = ((undefined !== r) ? r : true) && isUriMatching(rule.uri, context.uri));
    return r;
}

const getHostFromRequest = request => (((request.headers || [])['host'] || [])[0] || {}).value;

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
    };
    return ((config || {}).redirects || []).find(
        rule => isMatchingRule(rule, context, request)
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