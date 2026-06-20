"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ClassService = exports.BatchService = void 0;
const base_resource_service_1 = require("../shared/base-resource-service");
class BatchService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('batches', 'batch');
    }
}
exports.BatchService = BatchService;
class ClassService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('classes', 'class');
    }
}
exports.ClassService = ClassService;
//# sourceMappingURL=academic-service.js.map