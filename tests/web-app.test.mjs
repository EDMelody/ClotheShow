import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const read = file => readFile(new URL(`../${file}`, import.meta.url), 'utf8');

test('PWA declares install metadata and offline shell', async () => {
  const [html, manifest, worker] = await Promise.all([read('demo/index.html'), read('demo/manifest.webmanifest'), read('demo/service-worker.js')]);
  const metadata = JSON.parse(manifest);
  assert.match(html, /rel="manifest"/);
  assert.match(html, /apple-mobile-web-app-capable/);
  assert.equal(metadata.display, 'standalone');
  assert.ok(metadata.icons.some(icon => icon.sizes === '180x180'));
  assert.match(worker, /cache\.addAll\(APP_SHELL\)/);
});

test('favorites persist locally and camera simulation never uploads frames', async () => {
  const html = await read('demo/index.html');
  assert.match(html, /localStorage\.setItem\('tongshang-favorites'/);
  assert.doesNotMatch(html, /fetch\(|XMLHttpRequest|WebSocket/);
});
