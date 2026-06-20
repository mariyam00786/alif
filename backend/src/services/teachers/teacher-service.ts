import { BaseResourceService } from '../shared/base-resource-service';

export class TeacherService extends BaseResourceService {
  constructor() {
    super('teachers', 'teacher');
  }
}