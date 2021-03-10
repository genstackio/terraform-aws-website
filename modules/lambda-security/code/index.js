const {buildDefaultResponse, enrichResponse} = require('./utils');

const handler = async event => {
    const records = ((event || {})['Records'] || []);
    if (!records.length) return buildDefaultResponse();
    const response = ((records[0] || {})['cf'] || {})['response'];
    if (!response) return buildDefaultResponse();

    return enrichResponse(response);
};

module.exports = {handler}