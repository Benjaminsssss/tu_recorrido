#!/usr/bin/env node
/**
 * Script para migrar documentos de Firestore de la colección `places` a `estaciones`.
 * Opcionalmente copia los archivos en Cloud Storage de `places/...` a `estaciones/...` y actualiza los paths y URLs.
 *
 * Uso:
 * node migrate_places_to_estaciones.js --serviceAccount ./serviceAccountKey.json --bucket your-bucket.appspot.com [--copyStorage true]
 *
 * Requiere:
 *   npm install firebase-admin
 *
 * Ejecutar localmente con una cuenta de servicio que tenga permisos de Firestore y Storage.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: node migrate_places_to_estaciones.js --serviceAccount <path> --bucket <bucket> [--copyStorage true]');
  process.exit(1);
}

const argv = process.argv.slice(2);
let saPath = null;
let bucketName = null;
let copyStorage = false;
let dryRun = false;
let limit = null;

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--serviceAccount' || a === '--sa') saPath = argv[++i];
  else if (a === '--bucket') bucketName = argv[++i];
  else if (a === '--copyStorage') copyStorage = argv[++i] === 'true';
  else if (a === '--dryRun') dryRun = argv[++i] === 'true';
  else if (a === '--limit') limit = parseInt(argv[++i], 10);
  else if (a.startsWith('--')) { console.error('Unknown flag', a); usage(); }
}

if (!saPath || !bucketName) usage();
if (!fs.existsSync(saPath)) { console.error('serviceAccount file not found:', saPath); process.exit(1); }

const serviceAccount = require(path.resolve(saPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: bucketName,
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

(async () => {
  try {
    console.log('Starting migration: places -> estaciones');

    let snapshot = await db.collection('places').get();
    console.log('Found', snapshot.size, 'documents in places');

    let docsToProcess = snapshot.docs;
    if (limit && Number.isInteger(limit) && limit > 0) {
      docsToProcess = docsToProcess.slice(0, limit);
      console.log('Limiting to first', docsToProcess.length, 'documents (limit=' + limit + ')');
    }

    let migrated = 0;

    for (const doc of docsToProcess) {
      const id = doc.id;
      const data = doc.data();

      // Clone the data so we can modify imagenes safely
      const newData = Object.assign({}, data);

      // Handle imagenes array if present
      if (Array.isArray(newData.imagenes) && newData.imagenes.length > 0) {
        const newImages = [];
        for (const img of newData.imagenes) {
          if (!img || typeof img !== 'object') { newImages.push(img); continue; }

          const originalPath = img.path || '';
          if (copyStorage && originalPath && originalPath.startsWith('places/')) {
            const destPath = originalPath.replace(/^places\//, 'estaciones/');
            try {
              console.log(`Copying storage file: ${originalPath} -> ${destPath}`);
              const [copied] = await bucket.file(originalPath).copy(destPath);
              // Obtener URL firmada larga (ajusta expiración si quieres)
              const [signedUrl] = await copied.getSignedUrl({ action: 'read', expires: '2499-12-31' });
              const newImg = Object.assign({}, img, { path: destPath, url: signedUrl });
              newImages.push(newImg);
            } catch (err) {
              console.warn('Warning: failed to copy file', originalPath, err.message || err);
              // Fallback: keep original image object
              newImages.push(img);
            }
          } else {
            // No copy requested or path doesn't match; just update path prefix if present
            if (originalPath && originalPath.startsWith('places/')) {
              const destPath = originalPath.replace(/^places\//, 'estaciones/');
              const newImg = Object.assign({}, img, { path: destPath });
              newImages.push(newImg);
            } else {
              newImages.push(img);
            }
          }
        }
        newData.imagenes = newImages;
      }

      // Write to estaciones with same doc id (so references remain predictable)
      if (dryRun) {
        console.log(`[dryRun] Would write document to estaciones/${id}`);
      } else {
        await db.collection('estaciones').doc(id).set(newData, { merge: true });
      }

      // Optional: mark original doc as migrated
      if (dryRun) {
        console.log(`[dryRun] Would mark original places/${id} with _migratedTo`);
      } else {
        await db.collection('places').doc(id).set({ _migratedTo: 'estaciones', migratedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      }

      migrated++;
      console.log(`Migrated doc ${id} (${migrated}/${docsToProcess.length})`);
    }

    console.log('Migration finished. Total migrated:', migrated);
    process.exit(0);
  } catch (err) {
    console.error('Migration error:', err);
    process.exit(2);
  }
})();
