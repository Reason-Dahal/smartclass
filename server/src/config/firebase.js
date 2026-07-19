const { initializeApp, cert } = require('firebase-admin/app');
const path = require('path');

// Service account key is never committed — see .gitignore.
// Locally it must exist at server/src/config/firebase-service-account.json.
const serviceAccount = require(
  path.join(__dirname, 'firebase-service-account.json')
);

const firebaseApp = initializeApp({
  credential: cert(serviceAccount),
});

module.exports = firebaseApp;