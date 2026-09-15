import fs from 'node:fs/promises';
import path from 'node:path';
import * as THREE from 'three';
import { GLTFExporter } from 'three/examples/jsm/exporters/GLTFExporter.js';
import { USDZExporter } from 'three/examples/jsm/exporters/USDZExporter.js';

// GLTFExporter targets browsers and only needs this small FileReader subset
// when exporting texture-free binary scenes under Node.js.
globalThis.FileReader = class FileReader {
  async readAsArrayBuffer(blob) {
    this.result = await blob.arrayBuffer();
    this.onloadend?.({ target: this });
  }
};

const output = path.resolve('TongShang/Resources/Models');
await fs.mkdir(output, { recursive: true });
const products = [
  ['coat-001', 0x7fa5bd, 'coat'], ['dress-002', 0xc2686d, 'dress'], ['sweatshirt-003', 0x7f9270, 'top'],
  ['overall-004', 0xd7a64f, 'overall'], ['stripe-005', 0x4f7c99, 'top'], ['pants-006', 0xb87855, 'pants']
];

function mesh(geometry, material, x, y, z = 0, rx = 0, rz = 0) {
  const item = new THREE.Mesh(geometry, material); item.position.set(x, y, z); item.rotation.set(rx, 0, rz); item.castShadow = true; return item;
}
function garment(color, type) {
  const group = new THREE.Group(); group.name = 'Garment';
  const fabric = new THREE.MeshStandardMaterial({ color, roughness: 0.82, metalness: 0 });
  if (type === 'pants') {
    group.add(mesh(new THREE.BoxGeometry(.48, 1.35, .18), fabric, -.27, -.18, 0, 0, -.04));
    group.add(mesh(new THREE.BoxGeometry(.48, 1.35, .18), fabric, .27, -.18, 0, 0, .04));
    group.add(mesh(new THREE.BoxGeometry(1.02, .42, .2), fabric, 0, .55));
  } else {
    const bodyHeight = type === 'dress' ? 1.55 : 1.1;
    const bodyWidth = type === 'dress' ? 1.35 : 1.15;
    group.add(mesh(new THREE.BoxGeometry(bodyWidth, bodyHeight, .2), fabric, 0, 0));
    group.add(mesh(new THREE.BoxGeometry(.38, .95, .18), fabric, -.77, .22, 0, 0, -.62));
    group.add(mesh(new THREE.BoxGeometry(.38, .95, .18), fabric, .77, .22, 0, 0, .62));
    if (type === 'coat' || type === 'overall') {
      const seam = new THREE.MeshStandardMaterial({ color: 0xf4eee4, roughness: .8 });
      group.add(mesh(new THREE.BoxGeometry(.025, bodyHeight * .92, .225), seam, 0, 0, .005));
    }
  }
  group.rotation.y = -.08;
  return group;
}

for (const [id, color, type] of products) {
  const scene = new THREE.Scene(); scene.add(garment(color, type));
  const glb = await new GLTFExporter().parseAsync(scene, { binary: true });
  await fs.writeFile(path.join(output, `${id}.v1.glb`), Buffer.from(glb));
  const usdz = await new USDZExporter().parseAsync(scene, { quickLookCompatible: true });
  await fs.writeFile(path.join(output, `${id}.v1.usdz`), Buffer.from(usdz));
}
console.log(`Generated ${products.length} GLB/USDZ model pairs in ${output}`);
