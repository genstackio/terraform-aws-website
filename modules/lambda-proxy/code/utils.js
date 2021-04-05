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

const getHeaderFromCloudFrontEvent = (cfEvent, name, defaultValue = undefined) => {
    const headers = getHeadersFromCloudFrontEvent(cfEvent);
    const value = ((headers[name] || headers[(name || '').toLowerCase()] || [])[0] || {}).value;
    return (undefined === value) ? defaultValue : value;
}
const getHeadersFromCloudFrontEvent = cfEvent => cfEvent.request.headers || [];

const getUriFromCloudFrontEvent = (cfEvent, {refererMode = false} = {}) => {
    if (!refererMode) return cfEvent.request.uri;
    let host = getHeaderFromCloudFrontEvent(cfEvent, 'Host');
    let referer = getHeaderFromCloudFrontEvent(cfEvent, 'Referer');
    if (host && referer) return referer.split(host)[1];
    return cfEvent.request.uri;
}

const getComputedResultIfExistFromConfig = async (cfEvent, config) => {
    const context = {
        host: getHeaderFromCloudFrontEvent(cfEvent, 'Host'),
        uri: getUriFromCloudFrontEvent(cfEvent, config),
        country: getHeaderFromCloudFrontEvent(cfEvent, 'CloudFront-Viewer-Country'),
        headers: getHeadersFromCloudFrontEvent(cfEvent),
    };
    const found = ((config || {}).rules || []).find(
        rule => matchRuleAndOptionallyUpdateRule(rule, context, cfEvent, config)
    );
    let result;
    const x = {context, cfEvent, config};
    const c = config || {};
    if (!found) {
        result = c.origin || (c.proxy && await c.proxy(x)) || (c.custom && await c.custom(x));
    } else {
        result = found.origin || (found.proxy && await found.proxy(x)) || (found.custom && await found.custom(x));
    }
    const request = cfEvent.request;
    (request.origin && request.origin.custom && request.origin.custom.customHeaders && request.origin.custom.customHeaders['x-cloudfront-edge-next-debug']) && console.log(`uri: ${request.uri} =>`, JSON.stringify(result))
    if (!result) result = {};
    if (result.response) return result.response;
    result.uri && (request.uri = result.uri);
    result.origin && (request.origin = result.origin);
    (request.origin.custom && request.origin.custom.domainName) && (request.headers.host = [{key: 'Host', value: request.origin.custom.domainName}]);
    result.headers && (Object.assign(request.headers, result.headers))
    return request;
};

const getComputedResultIfExistForCloudFrontEvent = async cfEvent => {
    let config = require('./config');
    if ('function' === typeof config) config = await config(cfEvent.request, cfEvent);

    const result = await getComputedResultIfExistFromConfig(cfEvent, config);

    return result || (cfEvent ? cfEvent.request : buildDefaultResponse());
}
const processCloudFrontEvent = async cfEvent => getComputedResultIfExistForCloudFrontEvent(cfEvent);

module.exports = {
    buildDefaultResponse,
    processCloudFrontEvent,
}