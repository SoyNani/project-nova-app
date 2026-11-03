// Prueba las reglas de firestore.rules contra el emulador replicando las
// escrituras reales de la app. Uso (desde la raíz del proyecto):
//   firebase emulators:exec --only firestore --project demo-nova "node scripts/firestore_rules_check.mjs"
const PROJECT = 'demo-nova';
const DB = `projects/${PROJECT}/databases/(default)/documents`;
const BASE = `http://127.0.0.1:8080/v1/${DB}`;

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const token = (uid) =>
  `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    sub: uid, user_id: uid, aud: PROJECT,
    iss: `https://securetoken.google.com/${PROJECT}`,
    iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: { sign_in_provider: 'google.com' },
  })}.`;

const enc = (v) => {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  return { stringValue: String(v) };
};
const fields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, enc(v)]));

async function call(auth, method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${auth}` },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { ok: res.ok, status: res.status, json: await res.json().catch(() => ({})) };
}

const commit = (auth, writes) => call(auth, 'POST', ':commit', { writes });
const docName = (p) => `${DB}/${p}`;
const setWrite = (p, data, transforms = []) => ({
  update: { name: docName(p), fields: fields(data) },
  ...(transforms.length ? { updateTransforms: transforms } : {}),
});
const patchWrite = (p, data, transforms = []) => ({
  update: { name: docName(p), fields: fields(data) },
  updateMask: { fieldPaths: Object.keys(data) },
  currentDocument: { exists: true },
  ...(transforms.length ? { updateTransforms: transforms } : {}),
});
const serverTime = (f) => ({ fieldPath: f, setToServerValue: 'REQUEST_TIME' });
const inc = (n) => ({ fieldPath: 'eventsCount', increment: { integerValue: String(n) } });

let failures = 0;
async function expect(label, shouldAllow, promise) {
  const r = await promise;
  const pass = r.ok === shouldAllow;
  if (!pass) failures++;
  console.log(`${pass ? 'OK  ' : 'FAIL'} ${shouldAllow ? 'permite' : 'bloquea'} · ${label}` +
    (pass ? '' : `  → HTTP ${r.status} ${JSON.stringify(r.json).slice(0, 160)}`));
  return r;
}

const U1 = token('u1');
const start = new Date('2026-10-12T15:00:00Z');
const end = new Date('2026-10-12T16:30:00Z');
const event = (over = {}) => ({
  name: 'Innovación educativa', description: '', date: start, endDate: end,
  organizationId: 'org-1', organizationName: 'Colegio', city: 'Bucaramanga', address: '',
  speakerIds: ['sp-1'], speakerNames: ['Laura'], createdBy: 'u1', status: 'scheduled', ...over,
});

console.log('\n── Sin sesión');
await expect('leer organizaciones sin sesión', false, call('none', 'GET', '/organizations'));

console.log('\n── users');
await expect('crear su propio usuario con rol "usuario"', true,
  commit(U1, [setWrite('users/u1', { email: 'a@b.co', displayName: 'Laura', photoUrl: null, role: 'usuario' })]));
await expect('crearse a sí mismo como admin', false,
  commit(token('u2'), [setWrite('users/u2', { email: 'x', displayName: 'X', photoUrl: null, role: 'admin' })]));
await expect('subirse de rol a admin', false,
  commit(U1, [patchWrite('users/u1', { role: 'admin' })]));
await expect('leer el usuario de otra persona', false, call(U1, 'GET', '/users/u2'));

console.log('\n── organizations');
await expect('crear organización (eventsCount = 0)', true,
  commit(U1, [setWrite('organizations/org-1', { name: 'Colegio', city: 'Bucaramanga', department: 'Santander', address: 'Cra 27', lat: 7.1, lng: -73.1, eventsCount: 0 })]));
await expect('crear organización con contador inflado', false,
  commit(U1, [setWrite('organizations/org-x', { name: 'X', eventsCount: 5 })]));
await expect('editar datos de la organización', true,
  commit(U1, [patchWrite('organizations/org-1', { name: 'Colegio San Pedro', city: 'Bucaramanga', department: 'Santander', address: 'Cra 27', lat: 7.1, lng: -73.1 })]));
await expect('saltar el contador en +5', false,
  commit(U1, [{ ...patchWrite('organizations/org-1', {}), updateMask: { fieldPaths: [] }, updateTransforms: [inc(5)] }]));

console.log('\n── speakers');
await expect('crear speaker', true,
  commit(U1, [setWrite('speakers/sp-1', { name: 'Laura', profession: 'Ingeniera', specialties: [], organizationIds: ['org-1'], photoUrl: null, instagram: null, linkedin: null, tiktok: null })]));
await expect('borrar speaker sin ser admin', false, call(U1, 'DELETE', '/speakers/sp-1'));

console.log('\n── conferences (eventos)');
await expect('crear evento + sumar 1 a la organización (batch de la app)', true,
  commit(U1, [
    setWrite('conferences/ev-1', event(), [serverTime('createdAt')]),
    { ...patchWrite('organizations/org-1', {}), updateMask: { fieldPaths: [] }, updateTransforms: [inc(1)] },
  ]));
const org = await call(U1, 'GET', '/organizations/org-1');
const count = org.json.fields?.eventsCount?.integerValue;
console.log(`${count === '1' ? 'OK  ' : 'FAIL'} contador de la organización = ${count}`);
if (count !== '1') failures++;

await expect('evento que termina antes de empezar', false,
  commit(U1, [setWrite('conferences/ev-2', event({ endDate: start, date: end }), [serverTime('createdAt')])]));
await expect('evento a nombre de otro usuario', false,
  commit(U1, [setWrite('conferences/ev-3', event({ createdBy: 'otro' }), [serverTime('createdAt')])]));
await expect('evento con organización inexistente', false,
  commit(U1, [setWrite('conferences/ev-4', event({ organizationId: 'nope' }), [serverTime('createdAt')])]));
await expect('evento creado ya cancelado', false,
  commit(U1, [setWrite('conferences/ev-5', event({ status: 'cancelled' }), [serverTime('createdAt')])]));

await expect('cancelar evento + restar 1 (batch de la app)', true,
  commit(U1, [
    { ...patchWrite('conferences/ev-1', { status: 'cancelled' }), updateMask: { fieldPaths: ['status', 'cancelledAt'] }, updateTransforms: [serverTime('cancelledAt')] },
    { ...patchWrite('organizations/org-1', {}), updateMask: { fieldPaths: [] }, updateTransforms: [inc(-1)] },
  ]));
await expect('restaurar evento + sumar 1 (batch de la app)', true,
  commit(U1, [
    patchWrite('conferences/ev-1', { status: 'scheduled', cancelledAt: null }),
    { ...patchWrite('organizations/org-1', {}), updateMask: { fieldPaths: [] }, updateTransforms: [inc(1)] },
  ]));
await expect('cambiar el nombre del evento', false,
  commit(U1, [patchWrite('conferences/ev-1', { name: 'Otro nombre' })]));
await expect('cancelar con una fecha inventada', false,
  commit(U1, [patchWrite('conferences/ev-1', { status: 'cancelled', cancelledAt: new Date('2020-01-01') })]));
await expect('borrar evento sin ser admin', false, call(U1, 'DELETE', '/conferences/ev-1'));
await expect('leer eventos con sesión', true, call(U1, 'GET', '/conferences'));

console.log('\n── Colecciones no previstas');
await expect('escribir en una colección desconocida', false,
  commit(U1, [setWrite('cualquier/doc', { a: 1 })]));

console.log(`\n${failures === 0 ? 'TODAS LAS PRUEBAS PASARON' : `${failures} PRUEBA(S) FALLARON`}`);
process.exit(failures === 0 ? 0 : 1);
