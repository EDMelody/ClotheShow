import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const stage = document.querySelector('#stage');
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(35, 1, 0.01, 100);
camera.position.set(0, 0, 3.2);
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'default' });
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
renderer.outputColorSpace = THREE.SRGBColorSpace;
stage.appendChild(renderer.domElement);

scene.add(new THREE.HemisphereLight(0xffffff, 0x887766, 2.6));
const key = new THREE.DirectionalLight(0xffffff, 3.2); key.position.set(3, 4, 5); scene.add(key);
const rim = new THREE.DirectionalLight(0xffddcc, 1.6); rim.position.set(-4, 2, -3); scene.add(rim);
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true; controls.enablePan = false; controls.autoRotate = true; controls.autoRotateSpeed = 0.8;
controls.target.set(0, 0, 0);
const loader = new GLTFLoader();
let model; let lastURL = ''; let loadingURL = ''; let desiredPayload; let loadGeneration = 0;

const bridge = (event, detail = {}) => window.webkit?.messageHandlers?.viewer?.postMessage({ event, ...detail });
function resize() {
  const width = stage.clientWidth || 1, height = stage.clientHeight || 1;
  renderer.setSize(width, height, false); camera.aspect = width / height; camera.updateProjectionMatrix();
}
new ResizeObserver(resize).observe(stage); resize();

function applyColor(hex) {
  if (!model || !/^#[0-9A-F]{6}$/i.test(hex)) return;
  model.traverse(object => {
    if (!object.isMesh) return;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    for (const material of materials) {
      material.color?.set(hex);
      if ('roughness' in material) material.roughness = 0.78;
      material.needsUpdate = true;
    }
  });
}

function disposeModel(root) {
  const geometries = new Set(), materials = new Set(), textures = new Set();
  root?.traverse(object => {
    if (!object.isMesh) return;
    if (object.geometry) geometries.add(object.geometry);
    const list = Array.isArray(object.material) ? object.material : [object.material];
    for (const material of list) {
      if (!material) continue;
      materials.add(material);
      for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    }
  });
  for (const texture of textures) texture.dispose();
  for (const material of materials) material.dispose();
  for (const geometry of geometries) geometry.dispose();
}

function frameModel(root) {
  root.position.set(0, 0, 0);
  root.updateMatrixWorld(true);
  const initialBox = new THREE.Box3().setFromObject(root);
  root.position.sub(initialBox.getCenter(new THREE.Vector3()));
  root.updateMatrixWorld(true);
  const size = new THREE.Box3().setFromObject(root).getSize(new THREE.Vector3());
  const halfFov = THREE.MathUtils.degToRad(camera.fov * 0.5);
  const verticalDistance = size.y / (2 * Math.tan(halfFov));
  const horizontalDistance = size.x / (2 * Math.tan(halfFov) * Math.max(camera.aspect, 0.1));
  const distance = Math.max(verticalDistance, horizontalDistance, size.z * 2, 0.5) * 1.18;
  camera.position.set(0, 0, distance + size.z * 0.5);
  camera.near = Math.max(distance / 100, 0.01);
  camera.far = Math.max(distance * 20, 20);
  camera.updateProjectionMatrix();
  controls.target.set(0, 0, 0);
  controls.minDistance = distance * 0.65;
  controls.maxDistance = distance * 2.4;
  controls.update();
}

window.loadProduct = async payload => {
  if (!payload || !/^file:/i.test(payload.url) || !/^[a-z0-9-]+$/i.test(payload.productId)) {
    bridge('modelLoadFailed', { reason: 'invalidPayload' }); return;
  }
  desiredPayload = payload;
  controls.autoRotate = Boolean(payload.autoRotate);
  if (payload.url === lastURL && model) { applyColor(payload.color); return; }
  if (payload.url === loadingURL) return;
  const generation = ++loadGeneration;
  loadingURL = payload.url;
  bridge('modelLoadStarted');
  try {
    const gltf = await loader.loadAsync(payload.url);
    if (generation !== loadGeneration || desiredPayload?.url !== payload.url) { disposeModel(gltf.scene); return; }
    if (model) { scene.remove(model); disposeModel(model); }
    model = gltf.scene; lastURL = payload.url; loadingURL = '';
    frameModel(model);
    applyColor(desiredPayload.color);
    controls.autoRotate = Boolean(desiredPayload.autoRotate);
    scene.add(model);
    bridge('modelLoadSucceeded');
  } catch (error) {
    if (generation !== loadGeneration) return;
    loadingURL = '';
    bridge('modelLoadFailed', { reason: String(error).slice(0, 120) });
  }
};

function animate() {
  requestAnimationFrame(animate);
  controls.update(); renderer.render(scene, camera);
}
animate(); bridge('viewerReady');
