const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const auth = getAuth();

async function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const user = await db.collection("users").doc(request.auth.uid).get();
  if (!user.exists || user.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
}

function requiredString(data, field) {
  const value = data[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return value.trim();
}

exports.createStaffMember = onCall(async (request) => {
  await requireAdmin(request);

  const name = requiredString(request.data, "name");
  const occupation = requiredString(request.data, "occupation");
  const email = requiredString(request.data, "email").toLowerCase();
  const password = requiredString(request.data, "password");
  const profileImageUrl = requiredString(request.data, "profileImageUrl");
  const age = Number(request.data.age);

  if (!Number.isInteger(age) || age <= 0 || age > 130) {
    throw new HttpsError("invalid-argument", "A valid age is required.");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "Password must be at least 6 characters.");
  }

  let user;
  try {
    user = await auth.createUser({email, password, displayName: name});
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "A user with this email already exists.");
    }
    throw new HttpsError("internal", "Unable to create the staff account.");
  }

  const staffData = {
    uid: user.uid,
    name,
    age,
    occupation,
    email,
    profileImageUrl,
    status: "active",
    role: "staff",
    createdAt: FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
  };

  try {
    await db.runTransaction(async (transaction) => {
      transaction.set(db.collection("staff").doc(user.uid), staffData);
      transaction.set(db.collection("users").doc(user.uid), {
        role: "staff",
        name,
        email,
        status: "active",
      }, {merge: true});
    });
  } catch (error) {
    await auth.deleteUser(user.uid);
    throw new HttpsError("internal", "Unable to save the staff account.");
  }

  return {uid: user.uid};
});

exports.deactivateStaffMember = onCall(async (request) => {
  await requireAdmin(request);
  const uid = requiredString(request.data, "uid");
  const staffRef = db.collection("staff").doc(uid);
  const staff = await staffRef.get();

  if (!staff.exists || staff.data().role !== "staff") {
    throw new HttpsError("not-found", "Staff account not found.");
  }

  await auth.updateUser(uid, {disabled: true});
  await db.runTransaction(async (transaction) => {
    transaction.update(staffRef, {status: "inactive"});
    transaction.set(db.collection("users").doc(uid), {status: "inactive"}, {merge: true});
  });

  return {uid};
});
