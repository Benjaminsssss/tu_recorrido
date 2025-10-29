/*
 Script de migración: Añade el campo `insigniaID: null` a todos los documentos de la colección `estaciones`

 Uso:
 1) Instalar dependencias: npm install firebase-admin
 2) Ejecutar export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json" (o en Windows PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json")
 3) node migrate_add_insigniaID.js

 Nota: el script usa las credenciales por defecto (GOOGLE_APPLICATION_CREDENTIALS) o la credencial del entorno de ejecución.
*/

const admin = require('firebase-admin');

try {
  admin.initializeApp();
} catch (e) {
  // ignore if already initialized
}

const db = admin.firestore();

async function migrate() {
  console.log('Iniciando migración: agregar insigniaID:null a estaciones (si no existe)');
  const snapshot = await db.collection('estaciones').get();
  console.log(`Documentos encontrados: ${snapshot.size}`);

  let updated = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!Object.prototype.hasOwnProperty.call(data, 'insigniaID')) {
      await doc.ref.set({ insigniaID: null }, { merge: true });
      updated++;
      console.log(`Actualizado ${doc.id}`);
    }
  }

  console.log(`Migración finalizada. Documentos actualizados: ${updated}`);
}

migrate().catch(err => {
  console.error('Error en migración:', err);
  process.exit(1);
});
