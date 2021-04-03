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

const getComputedResultIfExistFromConfig = (cfEvent, config) => {
    const context = {
        host: getHeaderFromCloudFrontEvent(cfEvent, 'Host'),
        uri: getUriFromCloudFrontEvent(cfEvent, config),
        country: getHeaderFromCloudFrontEvent(cfEvent, 'CloudFront-Viewer-Country'),
        headers: getHeadersFromCloudFrontEvent(cfEvent),
    };
    const found = ((config || {}).rules || []).find(
        rule => matchRuleAndOptionallyUpdateRule(rule, context, request)
    );
    let result;
    const x = {context, cfEvent, config};
    if (!found && ((config || {}).proxy)) result = (config || {}).proxy(x);
    else result = found(x);
    if (result) {
        result = Object.assign(cfEvent.request, {origin: result});
    } else {
        result = (config || {}).custom ? (config || {}).custom(x) : undefined;
    }
    return result;
};

const getComputedResultIfExistForCloudFrontEvent = cfEvent => {
    let config = require('./config');
    if ('function' === typeof config) config = config(cfEvent.request, cfEvent);

    const result = getComputedResultIfExistFromConfig(cfEvent, config);

    return result || (cfEvent ? cfEvent.request : buildDefaultResponse());
}
const processCloudFrontEvent = cfEvent => getComputedResultIfExistForCloudFrontEvent(cfEvent);

module.exports = {
    buildDefaultResponse,
    processCloudFrontEvent,
}