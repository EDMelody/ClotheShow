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

test('3D viewer deduplicates loads and releases GPU resources', async () => {
  const source = await read('web-src/viewer.js');
  assert.match(source, /payload\.url === loadingURL/);
  assert.match(source, /generation !== loadGeneration/);
  assert.match(source, /disposeModel\(model\)/);
  assert.match(source, /material\.dispose\(\)/);
  assert.doesNotMatch(source, /material\.clone\(\)/);
  assert.match(source, /Math\.min\(devicePixelRatio, 1\.5\)/);
});

test('3D viewer frames each garment using its measured bounds', async () => {
  const source = await read('web-src/viewer.js');
  assert.match(source, /function frameModel\(root\)/);
  assert.match(source, /verticalDistance/);
  assert.match(source, /horizontalDistance/);
  assert.match(source, /controls\.target\.set\(0, 0, 0\)/);
});
