import { importPKCS8, SignJWT } from "jose";

interface Env {
  FIREBASE_SERVICE_ACCOUNT: string;
  FIREBASE_API_KEY: string;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

async function getGoogleAccessToken(env: Env): Promise<string> {
  const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);

  const privateKeyPem = String(serviceAccount.private_key)
  .replace(/\\n/g, "\n")
  .replace(/\r\n/g, "\n")
  .trim();

  if (!privateKeyPem.includes("-----BEGIN PRIVATE KEY-----")) {
    throw new Error(
      "Firebase service account private key is not valid PKCS8 format.",
    );
  }

  if (!privateKeyPem.includes("-----END PRIVATE KEY-----")) {
    throw new Error(
      "Firebase service account private key is incomplete.",
    );
  }

  const privateKey = await importPKCS8(
    privateKeyPem,
    "RS256",
  );

  const now = Math.floor(Date.now() / 1000);

  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/cloud-platform",
  })
    .setProtectedHeader({
      alg: "RS256",
      typ: "JWT",
    })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type:
          "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    },
  );

  if (!response.ok) {
    throw new Error(
      `Google authentication failed: ${await response.text()}`,
    );
  }

  const data = await response.json() as {
    access_token: string;
  };

  return data.access_token;
}

export default {
  async fetch(
    request: Request,
    env: Env,
  ): Promise<Response> {
    try {
      if (request.method === "OPTIONS") {
        return new Response(null, {
          status: 204,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers":
              "Content-Type, Authorization",
          },
        });
      }

      const url = new URL(request.url);

      if (url.pathname === "/" && request.method === "GET") {
        return json({
          success: true,
          service: "Smart Clinic Staff API",
        });
      }

      if (request.method !== "POST") {
        return json(
          { error: "Method not allowed" },
          405,
        );
      }

      const authorization =
        request.headers.get("Authorization");

      if (!authorization?.startsWith("Bearer ")) {
        return json(
          { error: "Missing authorization token" },
          401,
        );
      }

      const idToken =
        authorization.substring("Bearer ".length);

      const serviceAccount =
        JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);

      const projectId = serviceAccount.project_id;

      // Verify Firebase ID token.
      const verifyResponse = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${env.FIREBASE_API_KEY}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            idToken,
          }),
        },
      );

      if (!verifyResponse.ok) {
        return json(
          {
            error: "Invalid Firebase authentication token",
          },
          401,
        );
      }

      const verified =
        await verifyResponse.json() as {
          users?: Array<{
            localId: string;
          }>;
        };

      if (!verified.users?.length) {
        return json(
          {
            error: "Authenticated user not found",
          },
          401,
        );
      }

      const adminUid = verified.users[0].localId;

      // Get Google access token for Firestore REST API.
      const accessToken =
        await getGoogleAccessToken(env);

      // Check admin role in users/{uid}.
      const adminDocResponse = await fetch(
        `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${adminUid}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        },
      );

      if (!adminDocResponse.ok) {
        return json(
          {
            error: "Admin user record not found",
          },
          403,
        );
      }

      const adminDoc =
        await adminDocResponse.json() as {
          fields?: {
            role?: {
              stringValue?: string;
            };
          };
        };

      const role =
        adminDoc.fields?.role?.stringValue;

      if (role !== "admin") {
        return json(
          {
            error: "Admin access required",
          },
          403,
        );
      }

      const body = await request.json() as {
        name?: string;
        age?: number;
        occupation?: string;
        email?: string;
        password?: string;
        profileImageUrl?: string;
        uid?: string;
      };

      // CREATE STAFF
      if (url.pathname === "/createStaffMember") {
        if (
          !body.name ||
          body.age == null ||
          !body.occupation ||
          !body.email ||
          !body.password ||
          !body.profileImageUrl
        ) {
          return json(
            {
              error:
                "name, age, occupation, email, password and profileImageUrl are required",
            },
            400,
          );
        }

        const createUserResponse = await fetch(
          `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${env.FIREBASE_API_KEY}`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              email: body.email,
              password: body.password,
              returnSecureToken: false,
            }),
          },
        );

        if (!createUserResponse.ok) {
          return json(
            {
              error:
                `Firebase user creation failed: ${await createUserResponse.text()}`,
            },
            400,
          );
        }

        const createdUser =
          await createUserResponse.json() as {
            localId: string;
          };

        const uid = createdUser.localId;

        const staffResponse = await fetch(
          `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/staff?documentId=${uid}`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              fields: {
                uid: {
                  stringValue: uid,
                },
                name: {
                  stringValue: body.name,
                },
                age: {
                  integerValue: String(body.age),
                },
                occupation: {
                  stringValue: body.occupation,
                },
                email: {
                  stringValue: body.email,
                },
                profileImageUrl: {
                  stringValue: body.profileImageUrl,
                },
                status: {
                  stringValue: "active",
                },
              },
            }),
          },
        );

        if (!staffResponse.ok) {
          await fetch(
            `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${env.FIREBASE_API_KEY}`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                localId: uid,
                disableUser: true,
                returnSecureToken: false,
              }),
            },
          );

          return json(
            {
              error:
                `Staff Firestore record creation failed: ${await staffResponse.text()}`,
            },
            500,
          );
        }

        return json({
          success: true,
          uid,
          message: "Staff account created successfully",
        });
      }

      // DEACTIVATE STAFF
      if (url.pathname === "/deactivateStaffMember") {
        if (!body.uid) {
          return json(
            {
              error: "uid is required",
            },
            400,
          );
        }

        const updateResponse = await fetch(
          `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${env.FIREBASE_API_KEY}`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              localId: body.uid,
              disableUser: true,
              returnSecureToken: false,
            }),
          },
        );

        if (!updateResponse.ok) {
          return json(
            {
              error:
                `Failed to disable staff: ${await updateResponse.text()}`,
            },
            400,
          );
        }

        const deactivateResponse = await fetch(
          `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/staff/${body.uid}?updateMask.fieldPaths=status`,
          {
            method: "PATCH",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              fields: {
                status: {
                  stringValue: "inactive",
                },
              },
            }),
          },
        );

        if (!deactivateResponse.ok) {
          return json(
            {
              error:
                `Staff account disabled, but Firestore update failed: ${await deactivateResponse.text()}`,
            },
            500,
          );
        }

        return json({
          success: true,
          uid: body.uid,
          message:
            "Staff member deactivated successfully",
        });
      }

      return json(
        {
          error: "Endpoint not found",
        },
        404,
      );
    } catch (error) {
      console.error(error);

      return json(
        {
          success: false,
          error:
            error instanceof Error
              ? error.message
              : "Internal server error",
        },
        500,
      );
    }
  },
} satisfies ExportedHandler<Env>;
