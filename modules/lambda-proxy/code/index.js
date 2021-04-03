const {buildDefaultResponse, processCloudFrontEvent} = require('./utils');

const handler = async event => {
    const records = ((event || {})['Records'] || []);
    if (!records.length) return buildDefaultResponse();
    const cfEvent = ((records[0] || {})['cf'] || {});
    if (!cfEvent) return buildDefaultResponse();

    return processCloudFrontEvent(cfEvent);
};

module.exports = {handler}