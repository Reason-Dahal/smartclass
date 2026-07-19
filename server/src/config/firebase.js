const { initializeApp, cert } = require('firebase-admin/app');
const path = require('path');
const fs = require('fs');

// Locally: reads the gitignored JSON file directly.
// In production (Render): reads the same JSON content from an
// environment variable instead, since the file itself is never
// deployed (correctly excluded from git).
const getServiceAccount = () => {
  const envValue = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (envValue) {
    return JSON.parse(envValue);
  }

  const localPath = path.join(__dirname, 'firebase-service-account.json');
  if (fs.existsSync(localPath)) {
    return require(localPath);
  }

  throw new Error(
    'Firebase service account not found. Set FIREBASE_SERVICE_ACCOUNT ' +
    'env var in production, or place firebase-service-account.json ' +
    'locally at server/src/config/.'
  );
};

const firebaseApp = initializeApp({
  credential: cert(getServiceAccount()),
});

module.exports = firebaseApp;