const i18next = require('../config/i18n');
const middleware = require('i18next-http-middleware');

module.exports = middleware.handle(i18next);
