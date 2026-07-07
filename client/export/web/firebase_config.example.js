/**
 * Firebase bootstrap for the Web export shell.
 *
 * This must run and call initializeApp() BEFORE
 * features/authentication/infrastructure/web/firebase_auth_shim.js
 * loads, since that shim calls getAuth() against the default app.
 *
 * SETUP:
 *   1. Copy this file to firebase_config.js (gitignored — never
 *      commit real Firebase keys) in this same folder.
 *   2. Firebase console → Project settings → General → "Your apps" →
 *      Web app → copy the config object into firebaseConfig below.
 *   3. Reference both scripts (this one, then firebase_auth_shim.js)
 *      from your custom HTML export shell — see this folder's
 *      README.md for exactly where.
 */

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.13.0/firebase-app.js";

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
};

initializeApp(firebaseConfig);
