/*
Node.js script to bulk upload badge images to Firebase Storage and update Firestore 'estaciones/{placeId}.imagenes' array.

Usage:
1. Place your images in a folder, and provide a mapping JSON (see mapping.example.json) that maps placeId -> filename.
2. Create a service account key JSON and set GOOGLE_APPLICATION_CREDENTIALS env var, or modify the script to load the key file.
3. Install deps:
   npm init -y
   npm install firebase-admin
4. Run:
   node upload_badges.js mapping.json ./images_folder

The script uploads each file to 'estaciones/{placeId}/img_<timestamp>.jpg' and appends an object { url, alt: '', path } to the 'imagenes' array of the estacion document.
*/

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

if (process.argv.length < 4) {
  console.error('Usage: node upload_badges.js <mapping.json> <images_folder>');
  process.exit(1);
}

const mappingFile = process.argv[2];
const imagesFolder = process.argv[3];

// Initialize Firebase Admin SDK. Expects GOOGLE_APPLICATION_CREDENTIALS env var or default credentials.
admin.initializeApp({
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || undefined,
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

async function uploadAndAttach(placeId, filename) {
  const localPath = path.join(imagesFolder, filename);
  if (!fs.existsSync(localPath)) {
    console.warn(`File not found: ${localPath}`);
    return;
  }

  const timestamp = Date.now();
  const remotePath = `estaciones/${placeId}/img_${timestamp}${path.extname(filename)}`;

  console.log(`Uploading ${filename} -> ${remotePath}`);
  await bucket.upload(localPath, {
    destination: remotePath,
    metadata: { contentType: 'image/jpeg' },
  });

  // Make the file public URL (optional) - recommended to keep Storage rules private and use authenticated access in app.
  // const file = bucket.file(remotePath);
  // await file.makePublic();
  // const url = file.publicUrl();

  // Prefer signed URLs or getDownloadURL from client; here we obtain a signed URL valid for 1 year.
  const file = bucket.file(remotePath);
  const [signedUrl] = await file.getSignedUrl({ action: 'read', expires: Date.now() + 365 * 24 * 60 * 60 * 1000 });

  // Append to Firestore array
  const imageObj = { url: signedUrl, alt: '', path: remotePath };

  await db.collection('estaciones').doc(placeId).set({
    imagenes: admin.firestore.FieldValue.arrayUnion(imageObj),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Uploaded and linked ${filename} to place ${placeId}`);
}

(async () => {
  try {
    const mapping = JSON.parse(fs.readFileSync(mappingFile, 'utf8'));
    // mapping is expected as: { "placeId1": "file1.jpg", "placeId2": "file2.jpg" }
    for (const [placeId, filename] of Object.entries(mapping)) {
      await uploadAndAttach(placeId, filename);
    }
    console.log('All done');
  } catch (e) {
    console.error('Error:', e);
    process.exit(1);
  }
})();
