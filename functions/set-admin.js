'use strict';

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const defaultKeyPath =
  '/Users/aravind_appadurai/personal-projects/secrets/ServiceAccountsFirebase/cape-finance-firebase-adminsdk-fbsvc-65c4623ab3.json';

function keyPath() {
  return path.resolve(
    process.env.GOOGLE_APPLICATION_CREDENTIALS || defaultKeyPath,
  );
}

function promptUid() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question('Firebase Auth UID: ', (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function main() {
  const resolvedKeyPath = keyPath();
  if (!fs.existsSync(resolvedKeyPath)) {
    console.error(`Service account JSON not found: ${resolvedKeyPath}`);
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS to the key file path.');
    process.exit(1);
  }

  const serviceAccount = require(resolvedKeyPath);
  initializeApp({
    credential: cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });

  const uid = await promptUid();
  if (!uid) {
    console.error('UID is required.');
    process.exit(1);
  }

  const auth = getAuth();
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, { admin: true });

  const label = user.email || user.displayName || 'no email';
  console.log(`Set admin: true for ${uid} (${label}) in ${serviceAccount.project_id}.`);
  console.log('Sign out and sign in again in the app to refresh the ID token.');
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
