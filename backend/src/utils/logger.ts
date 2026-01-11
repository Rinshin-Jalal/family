/**
 * Structured logging utility for backend API
 * Provides consistent logging format with timestamps, context, and severity levels
 */

export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
}

export interface LogContext {
  userId?: string
  requestId?: string
  route?: string
  method?: string
  [key: string]: any
}

class Logger {
  private formatMessage(level: LogLevel, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString()
    const contextStr = context ? ` ${JSON.stringify(context)}` : ''
    return `[${timestamp}] [${level}] ${message}${contextStr}`
  }

  debug(message: string, context?: LogContext) {
    console.log(this.formatMessage(LogLevel.DEBUG, message, context))
  }

  info(message: string, context?: LogContext) {
    console.log(this.formatMessage(LogLevel.INFO, message, context))
  }

  warn(message: string, context?: LogContext) {
    console.warn(this.formatMessage(LogLevel.WARN, message, context))
  }

  error(message: string, error?: Error | unknown, context?: LogContext) {
    const errorContext = {
      ...context,
      error: error instanceof Error ? {
        name: error.name,
        message: error.message,
        stack: error.stack,
      } : error,
    }
    console.error(this.formatMessage(LogLevel.ERROR, message, errorContext))
  }

  // Request-specific logging helpers
  logRequest(route: string, method: string, userId?: string) {
    this.info(`${method} ${route}`, { route, method, userId })
  }

  logRequestError(route: string, method: string, error: Error | unknown, userId?: string) {
    this.error(`${method} ${route} failed`, error, { route, method, userId })
  }

  logDBError(operation: string, table: string, error: any, context?: LogContext) {
    this.error(`DB operation failed: ${operation} on ${table}`, error, {
      operation,
      table,
      ...context,
    })
  }

  logAuthError(operation: string, error: any, context?: LogContext) {
    this.error(`Auth operation failed: ${operation}`, error, {
      operation,
      ...context,
    })
  }
}

export const logger = new Logger()

// Helper to extract user ID from request context
export function getUserId(c: any): string | undefined {
  try {
    const user = c.get('user')
    return user?.id
  } catch {
    return undefined
  }
}

// Helper to generate request ID
export function generateRequestId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}
