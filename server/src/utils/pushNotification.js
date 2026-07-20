const { getMessaging } = require('firebase-admin/messaging');
const Notification = require('../models/Notification');
require('../config/firebase'); // ensures the Firebase app is initialized

/*LOW-LEVEL: actually sends one push, never throws upward
 Silently does nothing if the user has no fcmToken. On a confirmed
 dead/invalid token (app uninstalled, token expired), clears it
 from the user record so future pushes to this user don't keep
 silently failing against a token that will never work again.*/
const sendPushToUser = async (user, { title, body, data = {} }) => {
  if (!user || !user.fcmToken) return;

  try {
    await getMessaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data: {
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
      android: { priority: 'high' },
    });
  } catch (error) {
    if (error.code === 'messaging/registration-token-not-registered') {
      // This device is gone for good (uninstalled, token expired) —
      // clear it so we stop trying, rather than failing silently
      // on every future push to this user forever.
      const User = require('../models/User');
      await User.findByIdAndUpdate(user._id, { fcmToken: null }).catch(() => {});
    } else {
      console.error(`Push notification failed for user ${user._id}:`, error.message);
    }
  }
};

/*notifyUser — single recipient 
 Creates the in-app Notification document AND attempts the push,
 together, in one call. There is no longer a path where a
 controller creates a Notification without also notifying the
 device, or vice versa — the two cannot drift apart.*/
const notifyUser = async (user, { type, message, relatedId, pushTitle, pushBody }) => {
  await Notification.create({ userId: user._id, type, message, relatedId });
  await sendPushToUser(user, {
    title: pushTitle,
    body: pushBody,
    data: { type, relatedId: relatedId.toString() },
  });
};

// notifyUsers — batch recipients
// Same guarantee as notifyUser, for the "notify every enrolled
// student" shape used by assignment and note creation.
const notifyUsers = async (users, { type, message, relatedId, pushTitle, pushBody }) => {
  const validUsers = users.filter((u) => u != null);

  const notifications = validUsers.map((u) => ({
    userId: u._id, type, message, relatedId,
  }));
  if (notifications.length > 0) {
    await Notification.insertMany(notifications, { ordered: false }).catch(() => {});
  }

  // Fire-and-forget, one push per user — a slow or failing push to
  // one student must never delay or block pushes to the others.
  validUsers.forEach((u) => {
    sendPushToUser(u, {
      title: pushTitle,
      body: pushBody,
      data: { type, relatedId: relatedId.toString() },
    });
  });
};

module.exports = { notifyUser, notifyUsers };