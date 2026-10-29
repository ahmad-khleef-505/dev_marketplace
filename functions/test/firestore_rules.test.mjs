import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

const projectId = "demo-marketplace-purchase-rules";
const buyerUid = "buyer-uid";
const sellerUid = "seller-uid";
const adminUid = "super-admin-uid";
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: await readFile(new URL("../../firestore.rules", import.meta.url), "utf8"),
    },
  });
});

after(async () => {
  await environment.cleanup();
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "projects/project-1"), {
      title: "Project One",
      description: "Test project description",
      developerId: sellerUid,
      developerName: "Seller",
      price: 99,
      status: "approved",
    });
    await setDoc(doc(db, "projectPrivateContacts/project-1"), {
      developerId: sellerUid,
      phone: "+963900000001",
    });
  });
});

function orderData(overrides = {}) {
  return {
    clientUid: buyerUid,
    projectId: "project-1",
    projectTitle: "Project One",
    developerId: sellerUid,
    developerName: "Seller",
    amount: 99,
    currency: "USD",
    createdAt: serverTimestamp(),
    status: "pending_payment",
    ...overrides,
  };
}

test("buyer can create an order at the database project price", async () => {
  const db = environment.authenticatedContext(buyerUid).firestore();
  await assertSucceeds(setDoc(doc(db, "purchaseOrders/order-1"), orderData()));
});

test("unauthenticated users cannot create purchase orders", async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db, "purchaseOrders/anonymous"), orderData()));
});

test("users can read and update only their own profile fields", async () => {
  const db = environment.authenticatedContext(buyerUid, {
    email: "buyer@example.com",
  }).firestore();
  const ownProfile = doc(db, `users/${buyerUid}`);

  await assertSucceeds(setDoc(ownProfile, {
    uid: buyerUid,
    email: "buyer@example.com",
    role: "client",
    userType: "client",
    name: "Buyer",
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(ownProfile));
  await assertSucceeds(updateDoc(ownProfile, { name: "Updated Buyer" }));
  await assertFails(updateDoc(ownProfile, { userType: "superAdmin" }));
  await assertFails(getDoc(doc(db, `users/${sellerUid}`)));
  await assertFails(updateDoc(doc(db, `users/${sellerUid}`), {
    name: "Unauthorized",
  }));
});

test("onboarding is owner-only and can be created only once", async () => {
  const buyerDb = environment.authenticatedContext(buyerUid).firestore();
  const onboardingRef = doc(buyerDb, `userOnboarding/${buyerUid}`);
  await assertSucceeds(
    setDoc(onboardingRef, {
      interests: ["تطبيقات"],
      initialRating: 4,
      completedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(onboardingRef, { initialRating: 5 }));

  const otherDb = environment.authenticatedContext("other-user").firestore();
  await assertFails(
    setDoc(doc(otherDb, `userOnboarding/${buyerUid}`), {
      interests: ["مواقع"],
      initialRating: 3,
      completedAt: serverTimestamp(),
    }),
  );
});

test("project creation accepts only App or Website types", async () => {
  await environment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), `users/${sellerUid}`), {
      uid: sellerUid,
      role: "developer",
    });
  });

  const sellerDb = environment.authenticatedContext(sellerUid).firestore();
  const appBatch = writeBatch(sellerDb);
  appBatch.set(doc(sellerDb, "projects/app-project"), {
    developerId: sellerUid,
    developerName: "Seller",
    projectType: "app",
    title: "App Project",
    description: "Test app",
    category: "تطبيق جوال",
    price: 20,
    demoLink: "",
    imageUrl: "https://example.com/image.png",
    techStack: ["Flutter"],
    rating: 5,
    isEscrow: true,
    status: "pending",
    createdAt: serverTimestamp(),
    views: 0,
    inquiries: 0,
  });
  appBatch.set(doc(sellerDb, "projectPrivateContacts/app-project"), {
    developerId: sellerUid,
    phone: "+963900000001",
    updatedAt: serverTimestamp(),
  });
  await assertSucceeds(appBatch.commit());

  const invalidBatch = writeBatch(sellerDb);
  invalidBatch.set(doc(sellerDb, "projects/invalid-project"), {
    developerId: sellerUid,
    developerName: "Seller",
    projectType: "plugin",
    title: "Invalid Project",
    description: "Invalid type",
    category: "خادم/API",
    price: 20,
    demoLink: "",
    imageUrl: "https://example.com/image.png",
    techStack: ["Flutter"],
    rating: 5,
    isEscrow: true,
    status: "pending",
    createdAt: serverTimestamp(),
    views: 0,
    inquiries: 0,
  });
  invalidBatch.set(doc(sellerDb, "projectPrivateContacts/invalid-project"), {
    developerId: sellerUid,
    phone: "+963900000001",
    updatedAt: serverTimestamp(),
  });
  await assertFails(invalidBatch.commit());
});

test("project owners cannot delete projects and only a super admin can change status", async () => {
  const sellerDb = environment.authenticatedContext(sellerUid).firestore();
  const adminDb = environment.authenticatedContext(adminUid, {
    superAdmin: true,
  }).firestore();
  const sellerProject = doc(sellerDb, "projects/project-1");

  await assertFails(deleteDoc(sellerProject));
  await assertFails(updateDoc(sellerProject, { status: "rejected" }));
  await assertSucceeds(updateDoc(doc(adminDb, "projects/project-1"), {
    status: "rejected",
  }));
});

test("buyer cannot create an order with a modified amount", async () => {
  const db = environment.authenticatedContext(buyerUid).firestore();
  await assertFails(
    setDoc(doc(db, "purchaseOrders/order-1"), orderData({ amount: 1 })),
  );
});

test("unfiltered purchaseOrders listing is available only to a claimed admin", async () => {
  await environment.withSecurityRulesDisabled(async (adminContext) => {
    const db = adminContext.firestore();
    await setDoc(doc(db, "purchaseOrders/order-1"), {
      ...orderData({ createdAt: new Date() }),
    });
    await setDoc(doc(db, "purchaseOrders/order-2"), {
      ...orderData({ clientUid: "another-buyer", createdAt: new Date() }),
    });
  });

  const buyerDb = environment.authenticatedContext(buyerUid).firestore();
  await assertFails(getDocs(collection(buyerDb, "purchaseOrders")));

  const adminDb = environment.authenticatedContext(adminUid, { superAdmin: true }).firestore();
  const result = await assertSucceeds(getDocs(collection(adminDb, "purchaseOrders")));
  assert.equal(result.size, 2);
});

test("buyer cannot create an order for another user or their own project", async (context) => {
  const db = environment.authenticatedContext(buyerUid).firestore();
  await assertFails(
    setDoc(doc(db, "purchaseOrders/wrong-owner"), orderData({ clientUid: "other-user" })),
  );

  await environment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), "projects/self-project"), {
      title: "Seller project",
      developerId: buyerUid,
      developerName: "Buyer",
      price: 20,
      status: "approved",
    });
    await setDoc(doc(adminContext.firestore(), "projectPrivateContacts/self-project"), {
      developerId: buyerUid,
      phone: "+963900000002",
    });
  });
  await assertFails(
    setDoc(
      doc(db, "purchaseOrders/self-purchase"),
      orderData({
        projectId: "self-project",
        projectTitle: "Seller project",
        developerId: buyerUid,
        developerName: "Buyer",
        amount: 20,
      }),
    ),
  );
});

test("buyer can report transfer but cannot change amount or approve", async () => {
  const db = environment.authenticatedContext(buyerUid).firestore();
  const orderRef = doc(db, "purchaseOrders/order-1");
  await assertSucceeds(setDoc(orderRef, orderData()));
  await assertSucceeds(
    updateDoc(orderRef, {
      status: "pending_admin_review",
      transferNoticeSubmittedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(orderRef, { amount: 1 }));
  await assertFails(
    updateDoc(orderRef, {
      status: "approved",
      reviewedBy: buyerUid,
      reviewedAt: serverTimestamp(),
      reviewReason: null,
      developerPhone: "+963900000001",
    }),
  );
});

test("only a claimed admin can approve and reveal the developer phone", async () => {
  await environment.withSecurityRulesDisabled(async (adminContext) => {
    await setDoc(doc(adminContext.firestore(), "purchaseOrders/order-1"), {
      ...orderData({ createdAt: new Date() }),
      status: "pending_admin_review",
      transferNoticeSubmittedAt: new Date(),
    });
  });

  const adminDb = environment.authenticatedContext(adminUid, { superAdmin: true }).firestore();
  await assertSucceeds(
    updateDoc(doc(adminDb, "purchaseOrders/order-1"), {
      status: "approved",
      reviewedBy: adminUid,
      reviewedAt: serverTimestamp(),
      reviewReason: null,
      developerPhone: "+963900000001",
    }),
  );

  const buyerDb = environment.authenticatedContext(buyerUid).firestore();
  const approvedOrder = await assertSucceeds(getDoc(doc(buyerDb, "purchaseOrders/order-1")));
  assert.equal(approvedOrder.data().developerPhone, "+963900000001");

  const otherDb = environment.authenticatedContext("other-buyer").firestore();
  await assertFails(getDoc(doc(otherDb, "purchaseOrders/order-1")));
});

test("admin approval succeeds when developer contact is unavailable", async () => {
  await environment.withSecurityRulesDisabled(async (adminContext) => {
    const db = adminContext.firestore();
    await setDoc(doc(db, "purchaseOrders/order-no-contact"), {
      ...orderData({ createdAt: new Date() }),
      status: "pending_admin_review",
      transferNoticeSubmittedAt: new Date(),
    });
    await deleteDoc(doc(db, "projectPrivateContacts/project-1"));
  });

  const adminDb = environment.authenticatedContext(adminUid, { superAdmin: true }).firestore();
  await assertSucceeds(
    updateDoc(doc(adminDb, "purchaseOrders/order-no-contact"), {
      status: "approved",
      reviewedBy: adminUid,
      reviewedAt: serverTimestamp(),
      reviewReason: null,
    }),
  );

  const buyerDb = environment.authenticatedContext(buyerUid).firestore();
  const approvedOrder = await assertSucceeds(
    getDoc(doc(buyerDb, "purchaseOrders/order-no-contact")),
  );
  assert.equal(approvedOrder.data().status, "approved");
  assert.equal("developerPhone" in approvedOrder.data(), false);
});
