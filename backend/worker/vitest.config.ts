import { defineConfig } from 'vitest/config';
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-plugin';

/**
 * Tests run inside workerd with a real, isolated D1 instance — the same engine
 * that runs in production. A mocked database would let broken SQL pass, which
 * is the one class of bug that hurts most at 9am on a Saturday.
 */
export default defineConfig(async () => {
  const migrations = await readD1Migrations('./migrations');

  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: './wrangler.toml' },
        miniflare: {
          bindings: {
            JWT_SECRET: 'test-secret-not-used-anywhere-real-000000000000',
            TEST_MIGRATIONS: migrations,
          },
        },
      }),
    ],
    test: {
      setupFiles: ['./test/setup.ts'],
    },
  };
});
