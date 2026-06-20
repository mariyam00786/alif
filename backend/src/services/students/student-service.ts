import { BaseResourceService } from '../shared/base-resource-service';

export class StudentService extends BaseResourceService {
  constructor() {
    super('students', 'student');
  }
}