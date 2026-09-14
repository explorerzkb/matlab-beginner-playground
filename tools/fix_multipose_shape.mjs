// Fix only the public input shape of the pinned official MultiPose model.
// No Python/converter/runtime dependency. TensorFlow v2.15 schema field ids:
// Model.subgraphs=2; SubGraph.tensors=0,inputs=1; Tensor.shape=0,signature=7.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import path from 'node:path';
const [source, destination] = process.argv.slice(2);
assert(source && destination, 'Usage: node fix_multipose_shape.mjs source.tflite output.tflite');
assert(path.resolve(source) !== path.resolve(destination), 'Keep the original model');
const input = fs.readFileSync(source);
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
assert.equal(hash(input), 'd4489f89e6bd6777a8b9a1a16189832131f84ff90d82fae729e670b84d7948dd');
assert.equal(input.toString('ascii', 4, 8), 'TFL3');
const field = (table, index) => {
  const vt = table - input.readInt32LE(table);
  assert(4 + 2 * index < input.readUInt16LE(vt));
  const offset = input.readUInt16LE(vt + 4 + 2 * index);
  assert(offset, `Absent field ${index}`);
  return table + offset;
};
const vector = pos => pos + input.readUInt32LE(pos);
const entry = (vec, i) => {
  assert(i < input.readUInt32LE(vec));
  return vector(vec + 4 + i * 4);
};
const model = input.readUInt32LE(0);
assert.equal(input.readUInt32LE(field(model, 0)), 3);
const graph = entry(vector(field(model, 2)), 0);
const inputs = vector(field(graph, 1));
assert.equal(input.readUInt32LE(inputs), 1);
const tensor = entry(vector(field(graph, 0)), input.readInt32LE(inputs + 4));
const shapeField = field(tensor, 0), signatureField = field(tensor, 7);
const dims = vec => Array.from({ length: input.readUInt32LE(vec) }, (_, i) => input.readInt32LE(vec + 4 + i * 4));
assert.deepEqual(dims(vector(shapeField)), [1, 1, 1, 3]);
assert.deepEqual(dims(vector(signatureField)), [1, -1, -1, 3]);
// Append distinct vectors: FlatBuffers may share original vectors, so never
// edit their contents in place. All weights/operators remain byte-identical.
const offset = Math.ceil(input.length / 4) * 4;
const output = Buffer.alloc(offset + 40);
input.copy(output);
for (const [i, target] of [shapeField, signatureField].entries()) {
  const start = offset + i * 20;
  output.writeUInt32LE(start - target, target);
  [4, 1, 160, 256, 3].forEach((v, j) => output.writeInt32LE(v, start + j * 4));
}
const changed = [];
for (let i = 0; i < input.length; i++) {
  if (input[i] !== output[i]) {
    assert([shapeField, signatureField].some(p => i >= p && i < p + 4));
    changed.push(i);
  }
}
fs.writeFileSync(destination, output, { flag: 'wx' });
const manifest = { sourceHash: hash(input), outputHash: hash(output), inputShape: [1,160,256,3],
  changedOffsetsInOriginal: changed, appendedBytes: output.length - input.length,
  source: 'https://www.kaggle.com/models/google/movenet/tfLite/multipose-lightning-tflite-float16/1',
  schema: 'https://github.com/tensorflow/tensorflow/blob/v2.15.0/tensorflow/lite/schema/schema.fbs' };
fs.writeFileSync(destination + '.json', JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
console.log(JSON.stringify(manifest, null, 2));
