// ============================================================================
// ROUTE BASE CLASS
// ============================================================================
//
// Abstract base class for Hono route modules to eliminate boilerplate.
// All route files should extend this class.
//
// Usage:
//
//   import { BaseRoute } from './base'
//
//   class StoriesRoute extends BaseRoute {
//     constructor() {
//       super({ auth: true })  // Enable auth middleware
//       this.setupRoutes()
//     }
//
//     protected setupRoutes(): void {
//       this.app.get('/api/stories', this.getStories.bind(this))
//       this.app.post('/api/stories', this.createStory.bind(this))
//     }
//
//     private async getStories(c: Context): Promise<Response> {
//       // Handler implementation
//     }
//   }
//
//   export default new StoriesRoute().mount()
//
// ============================================================================

import type { Context, Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

// ============================================================================
// BASE ROUTE CONFIG
// ============================================================================

export interface RouteConfig {
  /** Whether to apply auth middleware to all routes */
  auth?: boolean
  /** Base path for this route module */
  basePath?: string
}

// ============================================================================
// BASE ROUTE CLASS
// ============================================================================

export abstract class BaseRoute {
  protected app: Hono
  protected config: Required<RouteConfig>

  constructor(config: RouteConfig = {}) {
    this.app = new Hono()
    this.config = {
      auth: config.auth ?? false,
      basePath: config.basePath ?? '',
    }

    // Apply auth middleware if configured
    if (this.config.auth) {
      this.app.use('*', authMiddleware)
    }

    // Allow subclasses to set up routes
    this.setupRoutes()
  }

  /**
   * Subclasses must implement this to define their routes.
   */
  protected abstract setupRoutes(): void

  /**
   * Get the mounted Hono app.
   * Call this after construction to get the app instance.
   */
  public mount(): Hono {
    return this.app
  }

  /**
   * Get the base path for this route module.
   */
  public getBasePath(): string {
    return this.config.basePath
  }

  // ============================================================================
  // PROTECTED HELPER METHODS
  // ============================================================================

  /**
   * Get Supabase client from context.
   * Requires auth middleware to be enabled.
   */
  protected getSupabase(c: Context): unknown {
    return c.get('supabase')
  }

  /**
   * Get user profile from context.
   * Requires auth middleware to be enabled.
   */
  protected getProfile(c: Context): unknown {
    return c.get('profile')
  }

  /**
   * Get authenticated user from context.
   * Requires auth middleware to be enabled.
   */
  protected getUser(c: Context): unknown {
    return c.get('user')
  }
}

// ============================================================================
// ROUTE BUILDER (Functional Alternative)
// ============================================================================

/**
 * Functional alternative to BaseRoute for simpler route definitions.
 * Use this for routes that don't need class-based structure.
 *
 * Usage:
 *   export default createRoute({
 *     auth: true,
 *     routes: (app) => {
 *       app.get('/api/stories', getStories)
 *       app.post('/api/stories', createStory)
 *     }
 *   })
 */
export function createRoute(config: RouteConfig & {
  routes: (app: Hono) => void
}): Hono {
  const app = new Hono()

  if (config.auth) {
    app.use('*', authMiddleware)
  }

  config.routes(app)

  return app
}

// ============================================================================
// ROUTE FACTORY (For Common Patterns)
// ============================================================================

/**
 * Factory for creating CRUD route handlers with common patterns.
 */
export class CrudRouteFactory<T> {
  private tableName: string
  private selectQuery?: string

  constructor(tableName: string, selectQuery?: string) {
    this.tableName = tableName
    this.selectQuery = selectQuery
  }

  /**
   * Create a list handler
   */
  list(supabaseGetter: (c: Context) => unknown): (c: Context) => Promise<Response> {
    return async (c: Context) => {
      const supabase = supabaseGetter(c)
      const { data, error } = await (supabase as any)
        .from(this.tableName)
        .select(this.selectQuery ?? '*')
        .order('created_at', { ascending: false })

      if (error) {
        return c.json({ error: error.message }, 500)
      }

      return c.json(data)
    }
  }

  /**
   * Create a get-by-id handler
   */
  getById(supabaseGetter: (c: Context) => unknown): (c: Context) => Promise<Response> {
    return async (c: Context) => {
      const supabase = supabaseGetter(c)
      const id = c.req.param('id')

      const { data, error } = await (supabase as any)
        .from(this.tableName)
        .select(this.selectQuery ?? '*')
        .eq('id', id)
        .single()

      if (error || !data) {
        return c.json({ error: 'Not found' }, 404)
      }

      return c.json(data)
    }
  }

  /**
   * Create a create handler
   */
  create(supabaseGetter: (c: Context) => unknown): (c: Context) => Promise<Response> {
    return async (c: Context) => {
      const supabase = supabaseGetter(c)
      const body = await c.req.json()

      const { data, error } = await (supabase as any)
        .from(this.tableName)
        .insert(body)
        .select()
        .single()

      if (error) {
        return c.json({ error: error.message }, 500)
      }

      return c.json(data, 201)
    }
  }

  /**
   * Create an update handler
   */
  update(supabaseGetter: (c: Context) => unknown): (c: Context) => Promise<Response> {
    return async (c: Context) => {
      const supabase = supabaseGetter(c)
      const id = c.req.param('id')
      const body = await c.req.json()

      const { data, error } = await (supabase as any)
        .from(this.tableName)
        .update(body)
        .eq('id', id)
        .select()
        .single()

      if (error) {
        return c.json({ error: error.message }, 500)
      }

      if (!data) {
        return c.json({ error: 'Not found' }, 404)
      }

      return c.json(data)
    }
  }

  /**
   * Create a delete handler
   */
  delete(supabaseGetter: (c: Context) => unknown): (c: Context) => Promise<Response> {
    return async (c: Context) => {
      const supabase = supabaseGetter(c)
      const id = c.req.param('id')

      const { error } = await (supabase as any)
        .from(this.tableName)
        .delete()
        .eq('id', id)

      if (error) {
        return c.json({ error: error.message }, 500)
      }

      return c.body(null, 204)
    }
  }
}
