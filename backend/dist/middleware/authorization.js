"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRoles = requireRoles;
const http_error_1 = require("../errors/http-error");
function requireRoles(...roles) {
    return (req, _res, next) => {
        if (!req.user) {
            return next(new http_error_1.HttpError(401, 'Authentication is required.'));
        }
        if (!roles.includes(req.user.role)) {
            return next(new http_error_1.HttpError(403, 'You do not have access to this resource.'));
        }
        return next();
    };
}
//# sourceMappingURL=authorization.js.map