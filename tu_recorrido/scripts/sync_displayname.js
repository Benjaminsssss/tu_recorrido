/**
 * Script para sincronizar displayName con nombre en todos los usuarios
 * 
 * Este script actualiza todos los documentos de usuarios en Firestore
 * para que displayName y nombre estén sincronizados.
 * 
 * Uso:
 * 1. Asegúrate de tener configurado GOOGLE_APPLICATION_CREDENTIALS
 * 2. node sync_displayname.js
 */

const admin = require('firebase-admin');

// Inicializar con el projectId explícito
admin.initializeApp({
  projectId: 'tu-recorrido-dev'
});

const db = admin.firestore();

async function syncDisplayNames() {
  try {
    console.log('🔄 Iniciando sincronización de displayName...\n');
    
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    
    if (snapshot.empty) {
      console.log('⚠️  No se encontraron usuarios');
      return;
    }
    
    let updated = 0;
    let skipped = 0;
    const batch = db.batch();
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const uid = doc.id;
      const displayName = data.displayName;
      const nombre = data.nombre;
      
      console.log(`\n📝 Usuario: ${uid}`);
      console.log(`   - displayName actual: "${displayName || '(vacío)'}"`);
      console.log(`   - nombre actual: "${nombre || '(vacío)'}"`);
      
      // Si displayName está vacío o es diferente de nombre, actualizar
      if (!displayName || displayName !== nombre) {
        const newDisplayName = nombre || displayName || 'Usuario';
        console.log(`   ✅ Actualizando displayName a: "${newDisplayName}"`);
        
        batch.update(doc.ref, {
          displayName: newDisplayName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updated++;
      } else {
        console.log(`   ⏭️  Ya está sincronizado, omitiendo...`);
        skipped++;
      }
    });
    
    if (updated > 0) {
      console.log(`\n💾 Guardando cambios en ${updated} usuarios...`);
      await batch.commit();
      console.log('✅ ¡Sincronización completada!');
    } else {
      console.log('\n✅ Todos los usuarios ya estaban sincronizados');
    }
    
    console.log(`\n📊 Resumen:`);
    console.log(`   - Actualizados: ${updated}`);
    console.log(`   - Omitidos: ${skipped}`);
    console.log(`   - Total: ${snapshot.size}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Ejecutar
syncDisplayNames()
  .then(() => {
    console.log('\n🎉 Script finalizado exitosamente');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error fatal:', error);
    process.exit(1);
  });
