import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { readFile } from "node:fs/promises";

const settings = JSON.parse(await readFile(new URL("../config/purchase-settings.json", import.meta.url), "utf8"));

const uid = process.argv[2];
const revoke = process.argv.includes("--revoke");
if (!uid) throw new Error("Usage: node scripts/set-super-admin.mjs <firebase-auth-uid> [--revoke]");

const projectId = process.env.GCLOUD_PROJECT || "devmarketplace-5e82d";
initializeApp({ credential: applicationDefault(), projectId });
const auth = getAuth();
const user = await auth.getUser(uid);
if (user.email?.toLowerCase() !== settings.superAdminEmail.toLowerCase()) {
  throw new Error("The requested account must match the configured super-admin email.");
}

const claims = { ...user.customClaims };
if (revoke) {
  delete claims.superAdmin;
} else {
  claims.superAdmin = true;
}
await auth.setCustomUserClaims(uid, claims);
await auth.revokeRefreshTokens(uid);
console.log(`superAdmin ${revoke ? "revoked from" : "granted to"} ${uid}. The user must sign in again.`);
