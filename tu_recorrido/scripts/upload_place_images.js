#!/usr/bin/env node
/**
 * Script minimalista para subir imágenes a Firebase Storage y añadirlas
 * al array `imagenes` del documento `estaciones/{placeId}` en Firestore.
 *
 * Uso:
 * node upload_place_images.js --serviceAccount ./serviceAccountKey.json --bucket your-bucket.appspot.com --placeId YOUR_PLACE_ID ./img1.jpg ./img2.jpg
 *
 * Requiere instalar:
 * npm install firebase-admin mime
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const mime = require('mime');

function usage() {
  console.log('Usage: node upload_place_images.js --serviceAccount <path> --bucket <bucket> --placeId <id> <file1> [file2 ...]');
  process.exit(1);
}

const argv = process.argv.slice(2);
if (argv.length < 4) usage();

let saPath = null;
let bucketName = null;
let placeId = null;
const files = [];

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--serviceAccount' || a === '--sa') {
    saPath = argv[++i];
  } else if (a === '--bucket') {
    bucketName = argv[++i];
  } else if (a === '--placeId') {
    placeId = argv[++i];
  } else if (a.startsWith('--')) {
    console.error('Unknown flag', a);
    usage();
  } else {
    files.push(a);
  }
}

if (!saPath || !bucketName || !placeId || files.length === 0) usage();

if (!fs.existsSync(saPath)) {
  console.error('serviceAccount file not found:', saPath);
  process.exit(1);
}

const serviceAccount = require(path.resolve(saPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: bucketName,
});

const bucket = admin.storage().bucket();
const db = admin.firestore();

(async () => {
  console.log('Uploading', files.length, 'files to', `estaciones/${placeId}/`);
  const uploaded = [];

  for (let i = 0; i < files.length; i++) {
    const filePath = files[i];
    if (!fs.existsSync(filePath)) {
      console.warn('File not found, skipping:', filePath);
      continue;
    }

    const ext = path.extname(filePath) || '.jpg';
  const dest = `estaciones/${placeId}/img_${Date.now()}_${i}${ext}`;
    const contentType = mime.getType(filePath) || 'image/jpeg';

    console.log('Uploading', filePath, '->', dest);
    await bucket.upload(filePath, { destination: dest, metadata: { contentType } });

    const file = bucket.file(dest);
    // Generar URL firmada de larga duración (expira en 31-12-2499)
    const [url] = await file.getSignedUrl({ action: 'read', expires: '2499-12-31' });

    uploaded.push({ url, path: dest, alt: path.basename(filePath) });
    // Añadir al documento en Firestore (arrayUnion)
    await db.collection('estaciones').doc(placeId).set({
      imagenes: admin.firestore.FieldValue.arrayUnion(uploaded[uploaded.length - 1]),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log('Uploaded and added to Firestore:', url);
  }

  console.log('Done. Uploaded', uploaded.length, 'files.');
  process.exit(0);
})().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
