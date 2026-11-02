import { applyD1Migrations, env } from 'cloudflare:test';

// Apply migrations once per test file. workerd gives each file its own
// isolated D1, so files cannot interfere with each other.
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
