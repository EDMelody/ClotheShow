import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const stage = document.querySelector('#stage');
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(35, 1, 0.01, 100);
camera.position.set(0, 0.25, 3.2);
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
stage.appendChild(renderer.domElement);

scene.add(new THREE.HemisphereLight(0xffffff, 0x887766, 2.6));
const key = new THREE.DirectionalLight(0xffffff, 3.2); key.position.set(3, 4, 5); scene.add(key);
const rim = new THREE.DirectionalLight(0xffddcc, 1.6); rim.position.set(-4, 2, -3); scene.add(rim);
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true; controls.enablePan = false; controls.minDistance = 1.7; controls.maxDistance = 5; controls.target.set(0, 0.15, 0);
let model; let autoRotate = true; let lastURL = '';

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
    object.material = object.material.clone(); object.material.color.set(hex); object.material.roughness = 0.78;
  });
}

window.loadProduct = async payload => {
  if (!payload || !/^file:/i.test(payload.url) || !/^[a-z0-9-]+$/i.test(payload.productId)) {
    bridge('modelLoadFailed', { reason: 'invalidPayload' }); return;
  }
  autoRotate = Boolean(payload.autoRotate);
  if (payload.url === lastURL && model) { applyColor(payload.color); bridge('modelLoadSucceeded'); return; }
  bridge('modelLoadStarted');
  try {
    const gltf = await new GLTFLoader().loadAsync(payload.url);
    if (model) scene.remove(model);
    model = gltf.scene; lastURL = payload.url;
    const box = new THREE.Box3().setFromObject(model); const size = box.getSize(new THREE.Vector3()); const center = box.getCenter(new THREE.Vector3());
    model.position.sub(center); model.position.y += size.y * 0.08;
    const scale = 2.15 / Math.max(size.x, size.y, size.z); model.scale.setScalar(scale);
    applyColor(payload.color); scene.add(model); bridge('modelLoadSucceeded');
  } catch (error) { bridge('modelLoadFailed', { reason: String(error).slice(0, 120) }); }
};

function animate() {
  requestAnimationFrame(animate);
  if (model && autoRotate && !controls.state) model.rotation.y += 0.004;
  controls.update(); renderer.render(scene, camera);
}
animate(); bridge('viewerReady');
