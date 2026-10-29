import { applicationDefault, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const projectId = process.env.GCLOUD_PROJECT || "devmarketplace-5e82d";
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const apply = process.argv.includes("--apply");
const projects = await db.collection("projects").get();
let migrated = 0;

for (let offset = 0; offset < projects.docs.length; offset += 200) {
  const batch = db.batch();
  let batchOperations = 0;
  for (const project of projects.docs.slice(offset, offset + 200)) {
    const data = project.data();
    const phone = data.developerPhone;
    if (typeof phone !== "string" || phone.trim().length === 0) continue;

    const contactRef = db.collection("projectPrivateContacts").doc(project.id);
    batch.set(contactRef, {
      developerId: typeof data.developerId === "string" ? data.developerId : "legacy_unassigned",
      phone: phone.trim(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.update(project.ref, { developerPhone: FieldValue.delete() });
    migrated += 1;
    batchOperations += 2;
  }
  if (apply && batchOperations > 0) await batch.commit();
}

console.log(`${apply ? "Migrated" : "Dry run: found"} ${migrated} project contact(s).`);
if (!apply) console.log("Run with --apply using trusted Firebase Admin credentials to apply the migration.");
