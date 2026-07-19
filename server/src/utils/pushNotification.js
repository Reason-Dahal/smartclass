const { getMessaging } = require('firebase-admin/messaging');
require('../config/firebase'); // ensures the Firebase app is initialized

// Sends a real push notification to a single user's registered device.
// Silently does nothing if the user has no fcmToken — e.g. they've
// never logged in on a device with the app installed, or push
// permission was never granted. This must never throw in a way that
// blocks the calling code, since a push failure should never prevent
// the underlying action (assignment created, note uploaded, etc.)
// from completing successfully.
const sendPushToUser = async (user, { title, body, data = {} }) => {
  if (!user || !user.fcmToken) return;

  try {
    await getMessaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data: {
        // FCM data payload values must all be strings
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
      android: {
        priority: 'high',
      },
    });
  } catch (error) {
    // Fire-and-forget from the caller's perspective — a bad/expired
    // token, or any other delivery failure, is logged but never
    // thrown further up.
    console.error(`Push notification failed for user ${user._id}:`, error.message);
  }
};

module.exports = { sendPushToUser };