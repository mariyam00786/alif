import { BaseResourceService } from '../shared/base-resource-service';

export class BatchService extends BaseResourceService {
  constructor() {
    super('batches', 'batch');
  }
}

export class ClassService extends BaseResourceService {
  constructor() {
    super('classes', 'class');
  }
}