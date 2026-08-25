# Contributing to Alif Online Moral School

Thank you for your interest in contributing to the Alif Online Moral School project! This document provides guidelines for contributing.

## Getting Started

1. **Fork the Repository**
   ```bash
   git clone <your-fork-url>
   cd alifschool
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or for fixes:
   git checkout -b fix/issue-description
   ```

3. **Install Dependencies**
   ```bash
   npm run install-all
   ```

## Development Guidelines

### Code Quality

- Write clean, readable code
- Use TypeScript with strict mode
- Add meaningful comments for complex logic
- Follow the established naming conventions
- Keep functions small and focused

### Commit Messages

Use the following format:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

Example:
```
feat(student): add daily activity tracking

Implement activity logging functionality for students
to track daily Islamic practices.

Closes #123
```

### Testing

- Write tests for new features
- Ensure tests pass before submitting PR
- Maintain >70% code coverage
- Use descriptive test names

```bash
cd backend
npm test
npm run test:watch
```

### Linting

Before submitting, run linting:

```bash
npm run lint
```

Fix any issues reported.

## Pull Request Process

1. **Update Documentation**
   - Update README if needed
   - Add comments to complex code
   - Update type definitions

2. **Test Your Changes**
   ```bash
   npm test
   npm run lint
   npm run build
   ```

3. **Create Pull Request**
   - Use descriptive title
   - Link related issues
   - Add description of changes
   - Add screenshots for UI changes

4. **Code Review**
   - Address feedback promptly
   - Request re-review after changes
   - Be respectful and professional

## Coding Standards

### TypeScript

```typescript
// ✅ Good
interface Student {
  id: string;
  name: string;
  email: string;
}

async function getStudent(id: string): Promise<Student> {
  const student = await db.query(id);
  return student;
}

// ❌ Avoid
const getStudent = (id) => {
  return db.query(id); // No types, unclear return
};
```

### Error Handling

```typescript
// ✅ Good
try {
  const student = await studentService.create(data);
  return { success: true, data: student };
} catch (error) {
  logger.error('Failed to create student', error);
  return { success: false, error: 'Internal server error' };
}

// ❌ Avoid
const student = await studentService.create(data);
return { data: student }; // No error handling
```

### Comments

```typescript
// ✅ Good - explains why, not what
// Students with inactive status shouldn't appear in leaderboard
const activeStudents = students.filter(s => s.status === 'active');

// ❌ Avoid - obvious from code
// Filter to only active students
const activeStudents = students.filter(s => s.status === 'active');
```

## Design System Usage

Always use design system tokens:

```typescript
// ✅ Good
import { AlifTheme } from '@alif-school/design-system';

const backgroundColor = AlifTheme.colors.primary[700];
const padding = AlifTheme.spacing.lg;

// ❌ Avoid
const backgroundColor = '#2E7D32'; // Hard-coded color
const padding = '16px'; // Hard-coded value
```

## File Structure

```
src/
├── config/           # Configuration
├── controllers/      # Request handlers
├── routes/          # API routes
├── middleware/      # Custom middleware
├── services/        # Business logic
├── database/        # DB queries
└── types/          # TypeScript definitions
```

## Database Changes

For any database schema changes:

1. Create migration file:
   ```bash
   npm run supabase:migration:new feature_name
   ```

2. Write SQL in the migration
3. Push migration:
   ```bash
   npm run supabase:db:push
   ```

4. Update `src/types/database.ts` with new types
5. Update services and controllers

## Documentation

- Add JSDoc comments to exported functions
- Update README.md if needed
- Add inline comments for complex logic
- Document API endpoints

```typescript
/**
 * Create a new student
 * 
 * @param data - Student information
 * @returns Created student with ID
 * @throws StudentValidationError if data is invalid
 * @throws DatabaseError if database operation fails
 * 
 * @example
 * const student = await createStudent({
 *   name: 'Ahmed',
 *   email: 'ahmed@example.com'
 * });
 */
export async function createStudent(data: CreateStudentInput): Promise<Student>
```

## Common Issues

### TypeScript Errors

Make sure types are properly imported:
```typescript
import { Student } from '@/types/database';
```

### Database Connection Issues

Check `.env` file has correct Supabase credentials:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-key
```

### Test Failures

Run tests locally before pushing:
```bash
npm run test:watch
```

## Performance Considerations

- Use database indexes on frequently queried columns
- Implement pagination for large datasets
- Cache static data where appropriate
- Optimize images and assets
- Profile before optimizing

## Accessibility

- Ensure color contrast meets WCAG AA standards
- Add alt text to images
- Use semantic HTML
- Support keyboard navigation
- Test with screen readers

## Security

Never:
- Commit secrets to repository
- Use hard-coded API keys
- Store passwords in plain text
- Skip input validation
- Disable security features

Always:
- Use environment variables for secrets
- Validate all inputs
- Sanitize data before storing
- Use parameterized queries
- Enable HTTPS
- Keep dependencies updated

## Getting Help

- Check existing documentation
- Search closed GitHub issues
- Ask in discussions
- Request help on PR
- Email the team

## Reporting Issues

Create GitHub issues for:
- Bug reports with reproduction steps
- Feature requests with use cases
- Documentation improvements
- Performance problems

Include:
- Clear description
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Environment information
- Screenshots/logs if applicable

## Code of Conduct

- Be respectful and professional
- Help others learn
- No harassment or discrimination
- Assume good intentions
- Focus on code, not people

## Questions?

Feel free to ask:
- Comment on issues
- Use discussions
- Email: development@alifschool.com
- Check documentation

---

Thank you for contributing! 🎉
