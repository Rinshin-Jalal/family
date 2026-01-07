// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================
//
// Shared error handling functions to eliminate duplication across route files.
// Provides consistent error responses for database errors, validation errors,
// and common HTTP status codes.
//
// Usage:
//   import { handleDbError, handleNotFound, handleUnauthorized } from '../utils/errors'
//
// ============================================================================

import type { Context } from 'hono'

// ============================================================================
// ERROR TYPES
// ============================================================================

export interface AppError {
  message: string
  code?: string
  details?: Record<string, unknown>
}

export interface DbError extends AppError {
  table: string
  operation: 'select' | 'insert' | 'update' | 'delete'
  originalError: unknown
}

// ============================================================================
// HTTP STATUS HELPERS
// ============================================================================

/**
 * Returns 200 OK response
 */
export function ok<T>(c: Context, data: T): Response {
  return c.json(data, 200)
}

/**
 * Returns 201 Created response
 */
export function created<T>(c: Context, data: T): Response {
  return c.json(data, 201)
}

/**
 * Returns 204 No Content response
 */
export function noContent(c: Context): Response {
  return c.body(null, 204)
}

// ============================================================================
// CLIENT ERROR HANDLERS (4xx)
// ============================================================================

/**
 * Returns 400 Bad Request response
 */
export function badRequest(c: Context, message: string, details?: Record<string, unknown>): Response {
  return c.json({
    error: message,
    code: 'BAD_REQUEST',
    details,
  }, 400)
}

/**
 * Returns 401 Unauthorized response
 */
export function unauthorized(c: Context, message: string = 'Unauthorized'): Response {
  return c.json({
    error: message,
    code: 'UNAUTHORIZED',
  }, 401)
}

/**
 * Returns 403 Forbidden response
 */
export function forbidden(c: Context, message: string = 'Forbidden'): Response {
  return c.json({
    error: message,
    code: 'FORBIDDEN',
  }, 403)
}

/**
 * Returns 404 Not Found response
 */
export function notFound(c: Context, resource: string): Response {
  return c.json({
    error: `${resource} not found`,
    code: 'NOT_FOUND',
  }, 404)
}

/**
 * Returns 409 Conflict response
 */
export function conflict(c: Context, message: string): Response {
  return c.json({
    error: message,
    code: 'CONFLICT',
  }, 409)
}

/**
 * Returns 422 Unprocessable Entity response
 */
export function unprocessable(c: Context, message: string, details?: Record<string, unknown>): Response {
  return c.json({
    error: message,
    code: 'UNPROCESSABLE_ENTITY',
    details,
  }, 422)
}

// ============================================================================
// SERVER ERROR HANDLERS (5xx)
// ============================================================================

/**
 * Returns 500 Internal Server Error response
 */
export function serverError(c: Context, message: string = 'Internal server error'): Response {
  return c.json({
    error: message,
    code: 'INTERNAL_ERROR',
  }, 500)
}

/**
 * Returns 503 Service Unavailable response
 */
export function serviceUnavailable(c: Context, message: string = 'Service temporarily unavailable'): Response {
  return c.json({
    error: message,
    code: 'SERVICE_UNAVAILABLE',
  }, 503)
}

// ============================================================================
// DATABASE ERROR HANDLERS
// ============================================================================

/**
 * Handles Supabase database errors and returns appropriate HTTP response.
 *
 * @param c - Hono context
 * @param error - Supabase error object
 * @param table - Name of the table being queried
 * @param operation - Type of database operation
 * @returns HTTP response with appropriate status code
 */
export function handleDbError(
  c: Context,
  error: unknown,
  table: string,
  operation: 'select' | 'insert' | 'update' | 'delete'
): Response {
  const dbError = error as { message?: string; code?: string; details?: unknown }

  // Log the error for debugging
  console.error(`Database ${operation} error on ${table}:`, dbError)

  // Handle specific error codes
  if (dbError.code === 'PGRST301') {
    // Row Level Security policy violation
    return forbidden(c, 'You do not have permission to access this resource')
  }

  if (dbError.code === '23505') {
    // Unique constraint violation
    return conflict(c, 'A record with this value already exists')
  }

  if (dbError.code === '23503') {
    // Foreign key constraint violation
    return badRequest(c, 'Referenced resource does not exist', {
      table,
      operation,
    })
  }

  if (dbError.code === '23502') {
    // Not null constraint violation
    return badRequest(c, 'Required field is missing', {
      table,
      operation,
    })
  }

  // Check for "not found" in the error message
  const message = dbError.message?.toLowerCase() || ''
  if (message.includes('row') && message.includes('not found') || message.includes('pgrst301')) {
    return notFound(c, table)
  }

  // Default to 500 for unknown database errors
  return serverError(c, `Database error during ${operation}`)
}

/**
 * Safe database query wrapper that handles common errors.
 *
 * @param c - Hono context
 * @param queryFn - Async function that performs the database query
 * @param table - Name of the table being queried
 * @returns Result of the query or error response
 */
export async function safeDbQuery<T>(
  c: Context,
  queryFn: () => Promise<{ data: T | null; error: unknown }>,
  table: string
): Promise<T | Response> {
  const { data, error } = await queryFn()

  if (error) {
    return handleDbError(c, error, table, 'select')
  }

  if (!data) {
    return notFound(c, table)
  }

  return data
}

/**
 * Safe database insert wrapper that handles common errors.
 *
 * @param c - Hono context
 * @param insertFn - Async function that performs the insert
 * @param table - Name of the table being inserted into
 * @returns Created record or error response
 */
export async function safeDbInsert<T>(
  c: Context,
  insertFn: () => Promise<{ data: T | null; error: unknown }>,
  table: string
): Promise<T | Response> {
  const { data, error } = await insertFn()

  if (error) {
    return handleDbError(c, error, table, 'insert')
  }

  if (!data) {
    return serverError(c, 'Failed to create resource')
  }

  return data
}

/**
 * Safe database update wrapper that handles common errors.
 *
 * @param c - Hono context
 * @param updateFn - Async function that performs the update
 * @param table - Name of the table being updated
 * @returns Updated record or error response
 */
export async function safeDbUpdate<T>(
  c: Context,
  updateFn: () => Promise<{ data: T | null; error: unknown }>,
  table: string
): Promise<T | Response> {
  const { data, error } = await updateFn()

  if (error) {
    return handleDbError(c, error, table, 'update')
  }

  if (!data) {
    return notFound(c, table)
  }

  return data
}

/**
 * Safe database delete wrapper that handles common errors.
 *
 * @param c - Hono context
 * @param deleteFn - Async function that performs the delete
 * @param table - Name of the table being deleted from
 * @returns Success response or error response
 */
export async function safeDbDelete(
  c: Context,
  deleteFn: () => Promise<{ error: unknown }>,
  table: string
): Promise<Response> {
  const { error } = await deleteFn()

  if (error) {
    return handleDbError(c, error, table, 'delete')
  }

  return noContent(c)
}

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

/**
 * Validates required fields in a request body.
 *
 * @param body - Request body object
 * @param requiredFields - Array of field names that are required
 * @returns { valid: boolean, missingFields: string[] }
 */
export function validateRequired(
  body: Record<string, unknown>,
  requiredFields: string[]
): { valid: boolean; missingFields: string[] } {
  const missingFields = requiredFields.filter(field => {
    const value = body[field]
    return value === undefined || value === null || value === ''
  })

  return {
    valid: missingFields.length === 0,
    missingFields,
  }
}

/**
 * Validates request body and returns 400 response if invalid.
 *
 * @param c - Hono context
 * @param body - Request body object
 * @param requiredFields - Array of field names that are required
 * @returns Response if validation fails, null if valid
 */
export function requireFields(
  c: Context,
  body: Record<string, unknown>,
  requiredFields: string[]
): Response | null {
  const { valid, missingFields } = validateRequired(body, requiredFields)

  if (!valid) {
    return badRequest(c, 'Missing required fields', {
      missingFields,
    })
  }

  return null
}

/**
 * Validates UUID format.
 */
export function isValidUUID(value: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(value)
}

/**
 * Validates UUID and returns 400 response if invalid.
 */
export function requireUUID(c: Context, value: string, paramName: string): Response | null {
  if (!isValidUUID(value)) {
    return badRequest(c, `Invalid ${paramName}`, {
      [paramName]: value,
    })
  }
  return null
}

// ============================================================================
// AUTH HELPERS
// ============================================================================

/**
 * Extracts and validates Authorization header.
 */
export function getAuthToken(c: Context): string | null {
  const authHeader = c.req.header('Authorization')
  
  if (!authHeader) {
    return null
  }

  if (!authHeader.startsWith('Bearer ')) {
    return null
  }

  return authHeader.replace('Bearer ', '')
}

/**
 * Validates authorization and returns 401 response if invalid.
 */
export function requireAuth(c: Context): string | Response {
  const token = getAuthToken(c)

  if (!token) {
    return unauthorized(c, 'Missing or invalid authorization header')
  }

  return token
}

// ============================================================================
// API RESPONSE BUILDERS
// ============================================================================

/**
 * Creates a paginated response.
 */
export function paginated<T>(
  c: Context,
  items: T[],
  total: number,
  page: number,
  pageSize: number
): Response {
  const totalPages = Math.ceil(total / pageSize)

  return c.json({
    data: items,
    pagination: {
      page,
      pageSize,
      total,
      totalPages,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    },
  }, 200)
}

/**
 * Creates a success response with message.
 */
export function success<T>(
  c: Context,
  message: string,
  data?: T,
  status: number = 200
): Response {
  const response: Record<string, unknown> = { message }
  
  if (data !== undefined) {
    response.data = data
  }

  return c.json(response, status)
}

/**
 * Creates an empty success response.
 */
export function emptySuccess(c: Context, message: string): Response {
  return c.json({ message }, 200)
}

// ============================================================================
// ERROR RESPONSE BUILDERS (for compatibility)
// ============================================================================

/**
 * Creates an error response object (for returning in handlers).
 */
export function errorResponse(message: string, code: string = 'ERROR', status: number = 500): AppError {
  return {
    message,
    code,
  }
}

/**
 * Creates a not found error response.
 */
export function notFoundError(resource: string): AppError {
  return {
    message: `${resource} not found`,
    code: 'NOT_FOUND',
  }
}

/**
 * Creates a validation error response.
 */
export function validationError(message: string, details?: Record<string, unknown>): AppError {
  return {
    message,
    code: 'VALIDATION_ERROR',
    details,
  }
}
