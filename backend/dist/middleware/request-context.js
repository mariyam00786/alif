"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestContextMiddleware = requestContextMiddleware;
const crypto_1 = require("crypto");
function requestContextMiddleware(req, res, next) {
    const requestIdHeader = req.header('x-request-id');
    const requestId = requestIdHeader && requestIdHeader.trim().length > 0
        ? requestIdHeader
        : (0, crypto_1.randomUUID)();
    req.requestId = requestId;
    res.setHeader('x-request-id', requestId);
    next();
}
//# sourceMappingURL=request-context.js.map