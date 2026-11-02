import type { D1Migration } from '@cloudflare/vitest-plugin';

/**
 * The `cloudflare:test` module types `env` as `Cloudflare.Env`, so bindings are
 * declared here rather than on a local interface. Keep this list in step with
 * `Env` in src/types.ts — a missing binding shows up as a type error in tests,
 * which is better than a 500 in production.
 */
declare global {
  namespace Cloudflare {
    interface Env {
      DB: D1Database;
      JWT_SECRET: string;
      MIN_APP_VERSION: string;
      ENVIRONMENT: string;
      TEST_MIGRATIONS: D1Migration[];
    }
  }
}

export {};
