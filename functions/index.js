/**
 * Cloud Functions for Link Manager App
 *
 * Functions:
 * - sendVerificationEmail: Send verification code to email
 * - verifyCode: Verify the 6-digit code
 * - updateUserPassword: Update user password (admin)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();

// Configure email transporter
// TODO: Replace with your SMTP configuration or use Firebase Extensions (Trigger Email)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'your-email@gmail.com',
    pass: process.env.EMAIL_PASSWORD || 'your-app-password',
  },
});

/**
 * Generate a random 6-digit verification code
 */
function generateSixDigitCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Send verification email
 * @param {Object} data - { email: string, purpose: 'signup' | 'find_id' | 'find_password' }
 * @returns {Object} - { success: boolean }
 */
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const { email, purpose } = data;

  if (!email || !purpose) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '이메일과 용도를 입력해 주세요.'
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '유효한 이메일 주소를 입력해 주세요.'
    );
  }

  // Generate verification code
  const code = generateSixDigitCode();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 5 * 60 * 1000) // 5 minutes expiration
  );

  try {
    // Save verification code to Firestore
    await db.collection('verification_codes').doc(email).set({
      code,
      expiresAt,
      purpose,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Prepare email content
    let subject, text;
    switch (purpose) {
      case 'signup':
        subject = '[Link Manager] 회원가입 인증번호';
        text = `회원가입을 위한 인증번호입니다.\n\n인증번호: ${code}\n\n이 인증번호는 5분간 유효합니다.`;
        break;
      case 'find_id':
        subject = '[Link Manager] 아이디 찾기 인증번호';
        text = `아이디 찾기를 위한 인증번호입니다.\n\n인증번호: ${code}\n\n이 인증번호는 5분간 유효합니다.`;
        break;
      case 'find_password':
        subject = '[Link Manager] 비밀번호 재설정 인증번호';
        text = `비밀번호 재설정을 위한 인증번호입니다.\n\n인증번호: ${code}\n\n이 인증번호는 5분간 유효합니다.`;
        break;
      default:
        subject = '[Link Manager] 인증번호';
        text = `인증번호: ${code}\n\n이 인증번호는 5분간 유효합니다.`;
    }

    // Send email
    await transporter.sendMail({
      from: '"Link Manager" <noreply@linkmanager.com>',
      to: email,
      subject,
      text,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #6750A4;">Link Manager</h2>
          <p>${text.replace(/\n/g, '<br>')}</p>
          <div style="background-color: #EADDFF; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h1 style="color: #21005D; letter-spacing: 8px; margin: 0;">${code}</h1>
          </div>
          <p style="color: #666; font-size: 12px;">이 이메일은 Link Manager 앱에서 발송되었습니다.</p>
        </div>
      `,
    });

    console.log(`Verification email sent to ${email} for ${purpose}`);
    return { success: true };
  } catch (error) {
    console.error('Error sending verification email:', error);
    throw new functions.https.HttpsError(
      'internal',
      '이메일 발송에 실패했습니다. 다시 시도해 주세요.'
    );
  }
});

/**
 * Verify the code
 * @param {Object} data - { email: string, code: string }
 * @returns {Object} - { success: boolean, purpose: string }
 */
exports.verifyCode = functions.https.onCall(async (data, context) => {
  const { email, code } = data;

  if (!email || !code) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '이메일과 인증번호를 입력해 주세요.'
    );
  }

  try {
    const doc = await db.collection('verification_codes').doc(email).get();

    if (!doc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        '인증번호를 찾을 수 없습니다. 다시 요청해 주세요.'
      );
    }

    const verificationData = doc.data();

    // Check if code matches
    if (verificationData.code !== code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        '인증번호가 일치하지 않습니다.'
      );
    }

    // Check if code has expired
    const now = admin.firestore.Timestamp.now();
    if (verificationData.expiresAt.toMillis() < now.toMillis()) {
      // Delete expired code
      await db.collection('verification_codes').doc(email).delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        '인증번호가 만료되었습니다. 다시 요청해 주세요.'
      );
    }

    // Delete the verification code after successful verification
    await db.collection('verification_codes').doc(email).delete();

    console.log(`Code verified for ${email}`);
    return { success: true, purpose: verificationData.purpose };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('Error verifying code:', error);
    throw new functions.https.HttpsError(
      'internal',
      '인증에 실패했습니다. 다시 시도해 주세요.'
    );
  }
});

/**
 * Update user password (admin function)
 * This requires the user to be authenticated or the code to be verified
 * @param {Object} data - { email: string, newPassword: string }
 * @returns {Object} - { success: boolean }
 */
exports.updateUserPassword = functions.https.onCall(async (data, context) => {
  const { email, newPassword } = data;

  if (!email || !newPassword) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '이메일과 새 비밀번호를 입력해 주세요.'
    );
  }

  // Validate password format (alphanumeric, 1-20 characters)
  const passwordRegex = /^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{1,20}$/;
  if (!passwordRegex.test(newPassword)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '비밀번호는 영문 숫자 조합 20자 이내여야 합니다.'
    );
  }

  try {
    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // Update password
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    console.log(`Password updated for user ${email}`);
    return { success: true };
  } catch (error) {
    console.error('Error updating password:', error);

    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError(
        'not-found',
        '사용자를 찾을 수 없습니다.'
      );
    }

    throw new functions.https.HttpsError(
      'internal',
      '비밀번호 변경에 실패했습니다. 다시 시도해 주세요.'
    );
  }
});

/**
 * Cleanup expired verification codes (scheduled function)
 * Runs every hour to clean up expired codes
 */
exports.cleanupExpiredCodes = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      const snapshot = await db
        .collection('verification_codes')
        .where('expiresAt', '<', now)
        .get();

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Cleaned up ${snapshot.size} expired verification codes`);
    } catch (error) {
      console.error('Error cleaning up expired codes:', error);
    }

    return null;
  });
