"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StudentService = void 0;
const base_resource_service_1 = require("../shared/base-resource-service");
class StudentService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('students', 'student');
    }
}
exports.StudentService = StudentService;
//# sourceMappingURL=student-service.js.map