#!/usr/bin/env node
/**
 * Script para crear estaciones de prueba en Firestore (colección estaciones).
 * Esto soluciona el problema de "No hay lugares que coincidan con los filtros" en el home.
 *
 * Uso:
 * node create_test_estaciones.js --serviceAccount ./serviceAccountKey.json --bucket your-bucket.appspot.com
 *
 * Requiere:
 *   npm install firebase-admin
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: node create_test_estaciones.js --serviceAccount <path> --bucket <bucket>');
  process.exit(1);
}

const argv = process.argv.slice(2);
let saPath = null;
let bucketName = null;

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--serviceAccount' || a === '--sa') saPath = argv[++i];
  else if (a === '--bucket') bucketName = argv[++i];
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

// Estaciones de prueba
const testEstaciones = [
  {
    name: 'Plaza de Armas',
    lat: -33.4372,
    lng: -70.6506,
    category: 'historical',
    country: 'Chile',
    city: 'Santiago',
    comuna: 'Santiago Centro',
    descripcion: 'Plaza principal de Santiago, corazón histórico de la ciudad.',
    shortDesc: 'Plaza principal de Santiago, corazón histórico de la ciudad.',
    mejorMomento: 'Atardecer',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Plaza_de_Armas_Santiago_Chile.jpg/800px-Plaza_de_Armas_Santiago_Chile.jpg',
    imagenes: [
      {
        url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Plaza_de_Armas_Santiago_Chile.jpg/800px-Plaza_de_Armas_Santiago_Chile.jpg',
        path: 'estaciones/test1/plaza_armas.jpg',
        alt: 'Plaza de Armas Santiago'
      }
    ]
  },
  {
    name: 'Cerro San Cristóbal',
    lat: -33.4258,
    lng: -70.6344,
    category: 'nature',
    country: 'Chile',
    city: 'Santiago',
    comuna: 'Providencia',
    descripcion: 'Cerro icónico de Santiago con vistas panorámicas de la ciudad.',
    shortDesc: 'Cerro icónico con vistas panorámicas de Santiago.',
    mejorMomento: 'Atardecer',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Cerro_San_Cristobal_Santiago_Chile.jpg/800px-Cerro_San_Cristobal_Santiago_Chile.jpg',
    imagenes: [
      {
        url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Cerro_San_Cristobal_Santiago_Chile.jpg/800px-Cerro_San_Cristobal_Santiago_Chile.jpg',
        path: 'estaciones/test2/cerro_san_cristobal.jpg',
        alt: 'Cerro San Cristóbal'
      }
    ]
  },
  {
    name: 'La Moneda',
    lat: -33.4429,
    lng: -70.6541,
    category: 'government',
    country: 'Chile',
    city: 'Santiago',
    comuna: 'Santiago Centro',
    descripcion: 'Palacio presidencial de Chile, sede del poder ejecutivo.',
    shortDesc: 'Palacio presidencial de Chile.',
    mejorMomento: 'Mañana',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Palacio_de_La_Moneda_2.jpg/800px-Palacio_de_La_Moneda_2.jpg',
    imagenes: [
      {
        url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Palacio_de_La_Moneda_2.jpg/800px-Palacio_de_La_Moneda_2.jpg',
        path: 'estaciones/test3/la_moneda.jpg',
        alt: 'Palacio de La Moneda'
      }
    ]
  }
];

(async () => {
  try {
    console.log('Creating test estaciones in Firestore...');

    let created = 0;

    for (const estacion of testEstaciones) {
      // Add timestamp
      const estacionData = {
        ...estacion,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Create document
      const docRef = await db.collection('estaciones').add(estacionData);
      
      created++;
      console.log(`Created estacion "${estacion.name}" with ID: ${docRef.id}`);
    }

    console.log(`Successfully created ${created} test estaciones!`);
    console.log('Now your app should show places in the home screen.');
    process.exit(0);
  } catch (err) {
    console.error('Error creating test estaciones:', err);
    process.exit(2);
  }
})();