"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticateRequest = authenticateRequest;
const auth_service_1 = require("../services/auth/auth-service");
const http_error_1 = require("../errors/http-error");
const authService = new auth_service_1.AuthService();
async function authenticateRequest(req, _res, next) {
    try {
        const authorizationHeader = req.header('authorization');
        if (!authorizationHeader?.startsWith('Bearer ')) {
            throw new http_error_1.HttpError(401, 'Missing Bearer access token.');
        }
        const accessToken = authorizationHeader.slice('Bearer '.length).trim();
        if (!accessToken) {
            throw new http_error_1.HttpError(401, 'Missing Bearer access token.');
        }
        const session = await authService.getSessionFromAccessToken(accessToken);
        req.accessToken = accessToken;
        req.user = session.user;
        req.profile = session.profile;
        next();
    }
    catch (error) {
        next(error);
    }
}
//# sourceMappingURL=authentication.js.map