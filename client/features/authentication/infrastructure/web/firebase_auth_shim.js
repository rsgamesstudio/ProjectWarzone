/**
 * Firebase Web SDK shim for Project Warzone's HTML5 export.
 *
 * ASSUMES the exported HTML page's shell already initializes Firebase
 * (firebase.initializeApp(firebaseConfig)) before this script runs —
 * that config is per-environment (dev/staging/prod) and does NOT
 * belong in version control as a hardcoded value here. See the HTML5
 * export documentation to be written alongside Phase 15 (Closed
 * Beta) for where that shell template will live.
 *
 * Loaded via <script type="module"> in the exported page, alongside
 * the Firebase Web SDK CDN modules:
 *   https://www.gstatic.com/firebasejs/10.x/firebase-app.js
 *   https://www.gstatic.com/firebasejs/10.x/firebase-auth.js
 *
 * Called from GDScript via JavaScriptBridge — see
 * ../firebase_web_identity_provider.gd for the calling convention
 * (window.warzone* callback properties).
 */

import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
} from "https://www.gstatic.com/firebasejs/10.13.0/firebase-auth.js";

window.WarzoneFirebaseAuth = {
  /**
   * @param {function(string): void} onSuccess - called with the Firebase ID token.
   * @param {function(string): void} onError - called with an error message.
   */
  signInWithGoogle: function (onSuccess, onError) {
    const auth = getAuth();
    const provider = new GoogleAuthProvider();
    signInWithPopup(auth, provider)
      .then((result) => result.user.getIdToken())
      .then((idToken) => onSuccess(idToken))
      .catch((error) => onError(error.message || String(error)));
  },

  /**
   * @param {string} email
   * @param {string} password
   * @param {boolean} createIfMissing - whether to create a new account on no-such-user.
   * @param {function(string): void} onSuccess - called with the Firebase ID token.
   * @param {function(string): void} onError - called with an error message.
   */
  signInWithEmail: function (email, password, createIfMissing, onSuccess, onError) {
    const auth = getAuth();
    const signIn = () => signInWithEmailAndPassword(auth, email, password);
    const signInOrCreate = () =>
      signIn().catch((error) => {
        if (createIfMissing && error.code === "auth/user-not-found") {
          return createUserWithEmailAndPassword(auth, email, password);
        }
        throw error;
      });

    signInOrCreate()
      .then((result) => result.user.getIdToken())
      .then((idToken) => onSuccess(idToken))
      .catch((error) => onError(error.message || String(error)));
  },
};
