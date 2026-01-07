// ============================================================================
// ERROR UTILITIES TESTS
// ============================================================================

import {
  handleDbError,
  handleNotFound,
  handleUnauthorized,
  handleServerError,
  safeDbQuery,
  safeDbInsert,
  validateRequired,
  requireFields,
  isValidUUID,
  requireUUID,
  getAuthToken,
  requireAuth,
  ok,
  created,
  badRequest,
  notFound,
  unauthorized,
  serverError,
} from '../utils/errors'

// Mock Hono Context
const createMockContext = (overrides = {}): any => ({
  json: jest.fn().mockReturnValue({}),
  req: {
    header: jest.fn(),
    param: jest.fn(),
    json: jest.fn(),
  },
  set: jest.fn(),
  get: jest.fn(),
  ...overrides,
})

describe('Error Handling Utilities', () => {
  describe('HTTP Status Helpers', () => {
    test('ok() returns 200 status', () => {
      const c = createMockContext()
      const data = { success: true }
      ok(c, data)
      expect(c.json).toHaveBeenCalledWith(data, 200)
    })

    test('created() returns 201 status', () => {
      const c = createMockContext()
      const data = { id: '123' }
      created(c, data)
      expect(c.json).toHaveBeenCalledWith(data, 201)
    })

    test('badRequest() returns 400 with error code', () => {
      const c = createMockContext()
      badRequest(c, 'Invalid input')
      expect(c.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Invalid input',
          code: 'BAD_REQUEST',
        }),
        400
      )
    })

    test('notFound() returns 404 with resource name', () => {
      const c = createMockContext()
      notFound(c, 'Story')
      expect(c.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Story not found',
          code: 'NOT_FOUND',
        }),
        404
      )
    })

    test('unauthorized() returns 401', () => {
      const c = createMockContext()
      unauthorized(c)
      expect(c.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Unauthorized',
          code: 'UNAUTHORIZED',
        }),
        401
      )
    })

    test('serverError() returns 500', () => {
      const c = createMockContext()
      serverError(c)
      expect(c.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Internal server error',
          code: 'INTERNAL_ERROR',
        }),
        500
      )
    })
  })

  describe('Database Error Handler', () => {
    test('handles RLS policy violation (PGRST301)', () => {
      const c = createMockContext()
      const error = { code: 'PGRST301', message: 'permission denied' }
      const result = handleDbError(c, error, 'stories', 'select')
      expect(result.status).toBe(403)
    })

    test('handles unique constraint violation (23505)', () => {
      const c = createMockContext()
      const error = { code: '23505', message: 'duplicate key' }
      const result = handleDbError(c, error, 'profiles', 'insert')
      expect(result.status).toBe(409)
    })

    test('handles foreign key violation (23503)', () => {
      const c = createMockContext()
      const error = { code: '23503', message: 'foreign key violation' }
      const result = handleDbError(c, error, 'responses', 'insert')
      expect(result.status).toBe(400)
    })

    test('handles not found errors', () => {
      const c = createMockContext()
      const error = { message: 'row not found' }
      const result = handleDbError(c, error, 'stories', 'select')
      expect(result.status).toBe(404)
    })

    test('returns 500 for unknown errors', () => {
      const c = createMockContext()
      const error = { message: 'connection timeout' }
      const result = handleDbError(c, error, 'stories', 'select')
      expect(result.status).toBe(500)
    })
  })

  describe('Safe DB Query Wrapper', () => {
    test('returns data on successful query', async () => {
      const c = createMockContext()
      const mockData = [{ id: '1' }, { id: '2' }]
      const queryFn = jest.fn().mockResolvedValue({ data: mockData, error: null })
      
      const result = await safeDbQuery(c, queryFn, 'stories')
      expect(result).toEqual(mockData)
    })

    test('returns error response on query failure', async () => {
      const c = createMockContext()
      const queryFn = jest.fn().mockResolvedValue({ data: null, error: { message: 'DB error' } })
      
      const result = await safeDbQuery(c, queryFn, 'stories')
      expect(result).toHaveProperty('status', 500)
    })

    test('returns 404 when data is null', async () => {
      const c = createMockContext()
      const queryFn = jest.fn().mockResolvedValue({ data: null, error: null })
      
      const result = await safeDbQuery(c, queryFn, 'stories')
      expect(result).toHaveProperty('status', 404)
    })
  })

  describe('Validation Helpers', () => {
    test('validateRequired() detects missing fields', () => {
      const body = { name: 'John', email: '' }
      const result = validateRequired(body, ['name', 'email', 'age'])
      expect(result.valid).toBe(false)
      expect(result.missingFields).toContain('email')
      expect(result.missingFields).toContain('age')
    })

    test('validateRequired() passes when all fields present', () => {
      const body = { name: 'John', email: 'john@example.com' }
      const result = validateRequired(body, ['name', 'email'])
      expect(result.valid).toBe(true)
      expect(result.missingFields).toHaveLength(0)
    })

    test('requireFields() returns error response for missing fields', () => {
      const c = createMockContext()
      const body = { name: 'John' }
      const result = requireFields(c, body, ['name', 'email'])
      expect(result).not.toBeNull()
      expect(result?.status).toBe(400)
    })

    test('requireFields() returns null when all fields present', () => {
      const c = createMockContext()
      const body = { name: 'John', email: 'john@example.com' }
      const result = requireFields(c, body, ['name', 'email'])
      expect(result).toBeNull()
    })

    test('isValidUUID() validates UUID format', () => {
      expect(isValidUUID('123e4567-e89b-12d3-a456-426614174000')).toBe(true)
      expect(isValidUUID('not-a-uuid')).toBe(false)
      expect(isValidUUID('')).toBe(false)
    })

    test('requireUUID() returns error for invalid UUID', () => {
      const c = createMockContext()
      const result = requireUUID(c, 'invalid-uuid', 'storyId')
      expect(result).not.toBeNull()
      expect(result?.status).toBe(400)
    })
  })

  describe('Auth Helpers', () => {
    test('getAuthToken() extracts Bearer token', () => {
      const c = createMockContext()
      c.req.header.mockReturnValue('Bearer abc123')
      const token = getAuthToken(c)
      expect(token).toBe('abc123')
    })

    test('getAuthToken() returns null for missing header', () => {
      const c = createMockContext()
      c.req.header.mockReturnValue(null)
      const token = getAuthToken(c)
      expect(token).toBeNull()
    })

    test('getAuthToken() returns null for non-Bearer token', () => {
      const c = createMockContext()
      c.req.header.mockReturnValue('Basic abc123')
      const token = getAuthToken(c)
      expect(token).toBeNull()
    })

    test('requireAuth() returns token when valid', () => {
      const c = createMockContext()
      c.req.header.mockReturnValue('Bearer abc123')
      const result = requireAuth(c)
      expect(result).toBe('abc123')
    })

    test('requireAuth() returns 401 for missing token', () => {
      const c = createMockContext()
      c.req.header.mockReturnValue(null)
      const result = requireAuth(c)
      expect(result).toHaveProperty('status', 401)
    })
  })
})
