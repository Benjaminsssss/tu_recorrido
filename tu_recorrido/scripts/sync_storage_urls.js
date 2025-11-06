/**
 * Script para sincronizar las URLs de las imágenes de Storage a Firestore
 * Ejecutar con: node sync_storage_urls.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'tu-recorrido-dev.firebasestorage.app'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

async function syncUserImages(userId) {
  try {
    console.log(`\n🔍 Sincronizando imágenes para usuario: ${userId}`);
    
    const updates = {};
    
    // Verificar si existe profile.jpg
    const profileFile = bucket.file(`users/${userId}/profile.jpg`);
    const [profileExists] = await profileFile.exists();
    
    if (profileExists) {
      const [profileUrl] = await profileFile.getSignedUrl({
        action: 'read',
        expires: '03-01-2500' // Fecha muy lejana
      });
      // Obtener URL pública
      const profilePublicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(`users/${userId}/profile.jpg`)}?alt=media`;
      updates.photoURL = profilePublicUrl;
      console.log(`✅ Profile URL: ${profilePublicUrl}`);
    }
    
    // Verificar si existe background.jpg
    const backgroundFile = bucket.file(`users/${userId}/background.jpg`);
    const [backgroundExists] = await backgroundFile.exists();
    
    if (backgroundExists) {
      const backgroundPublicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(`users/${userId}/background.jpg`)}?alt=media`;
      updates.backgroundURL = backgroundPublicUrl;
      console.log(`✅ Background URL: ${backgroundPublicUrl}`);
    }
    
    // Actualizar Firestore si hay URLs
    if (Object.keys(updates).length > 0) {
      await db.collection('users').doc(userId).update(updates);
      console.log(`✅ URLs actualizadas en Firestore para usuario ${userId}`);
    } else {
      console.log(`⚠️ No se encontraron imágenes para el usuario ${userId}`);
    }
    
  } catch (error) {
    console.error(`❌ Error sincronizando imágenes:`, error);
  }
}

async function syncAllUsers() {
  try {
    // Listar todos los usuarios que tienen carpeta en Storage
    const [files] = await bucket.getFiles({ prefix: 'users/' });
    
    const userIds = new Set();
    files.forEach(file => {
      const match = file.name.match(/^users\/([^\/]+)\//);
      if (match) {
        userIds.add(match[1]);
      }
    });
    
    console.log(`📁 Encontrados ${userIds.size} usuarios con imágenes en Storage`);
    
    for (const userId of userIds) {
      await syncUserImages(userId);
    }
    
    console.log('\n✅ Sincronización completada');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Si se proporciona un userId como argumento, sincronizar solo ese usuario
const userId = process.argv[2];
if (userId) {
  syncUserImages(userId).then(() => process.exit(0));
} else {
  syncAllUsers();
}
