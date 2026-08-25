"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TeacherService = void 0;
const base_resource_service_1 = require("../shared/base-resource-service");
class TeacherService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('teachers', 'teacher');
    }
}
exports.TeacherService = TeacherService;
//# sourceMappingURL=teacher-service.js.map