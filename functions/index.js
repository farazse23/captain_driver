const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Function to send notification to all drivers
exports.driverSendNotificationToAllDrivers = functions.https.onCall(async (data, context) => {
  // Verify admin authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { title, message, type = 'admin_announcement', priority = 'normal' } = data;

  if (!title || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Title and message are required');
  }

  try {
    // Get all drivers
    const driversSnapshot = await db.collection('drivers').get();
    const batch = db.batch();
    const tokens = [];

    driversSnapshot.forEach((driverDoc) => {
      const driverData = driverDoc.data();
      
      // Create notification document
      const notificationRef = driverDoc.ref.collection('notifications').doc();
      batch.set(notificationRef, {
        title,
        message,
        type,
        priority,
        senderId: context.auth.uid,
        senderName: 'System Administrator',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        isRead: false
      });

      // Collect FCM tokens for this driver
      driverDoc.ref.collection('tokens').get().then((tokensSnapshot) => {
        tokensSnapshot.forEach((tokenDoc) => {
          tokens.push(tokenDoc.data().token);
        });
      });
    });

    // Commit the batch
    await batch.commit();

    // Send FCM notifications if tokens exist
    if (tokens.length > 0) {
      const message = {
        notification: {
          title,
          body: message,
        },
        data: {
          type,
          priority,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
      };

      const response = await messaging.sendMulticast(message);
      console.log('Successfully sent messages:', response.successCount);
      console.log('Failed to send messages:', response.failureCount);
    }

    return { success: true, message: 'Notification sent to all drivers' };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Function to send notification to specific driver
exports.driverSendNotificationToDriver = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { driverId, title, message, type = 'admin_announcement', priority = 'normal' } = data;

  if (!driverId || !title || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Driver ID, title and message are required');
  }

  try {
    const driverRef = db.collection('drivers').doc(driverId);
    const driverDoc = await driverRef.get();

    if (!driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver not found');
    }

    // Create notification document
    const notificationRef = driverRef.collection('notifications').doc();
    await notificationRef.set({
      title,
      message,
      type,
      priority,
      senderId: context.auth.uid,
      senderName: 'System Administrator',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      isRead: false
    });

    // Get driver's FCM tokens
    const tokensSnapshot = await driverRef.collection('tokens').get();
    const tokens = [];
    tokensSnapshot.forEach((tokenDoc) => {
      tokens.push(tokenDoc.data().token);
    });

    // Send FCM notification if tokens exist
    if (tokens.length > 0) {
      const message = {
        notification: {
          title,
          body: message,
        },
        data: {
          type,
          priority,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
      };

      const response = await messaging.sendMulticast(message);
      console.log('Successfully sent messages:', response.successCount);
    }

    return { success: true, message: 'Notification sent to driver' };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Function triggered when admin creates an announcement
exports.driverOnAdminAnnouncement = functions.firestore
  .document('admin_announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const announcementData = snap.data();
    const { title, message, type = 'admin_announcement', priority = 'normal' } = announcementData;

    try {
      // Get all drivers
      const driversSnapshot = await db.collection('drivers').get();
      const batch = db.batch();
      const tokens = [];

      driversSnapshot.forEach((driverDoc) => {
        const driverData = driverDoc.data();
        
        // Create notification document
        const notificationRef = driverDoc.ref.collection('notifications').doc();
        batch.set(notificationRef, {
          title,
          message,
          type,
          priority,
          senderId: 'admin_001',
          senderName: 'System Administrator',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          isRead: false
        });

        // Collect FCM tokens for this driver
        driverDoc.ref.collection('tokens').get().then((tokensSnapshot) => {
          tokensSnapshot.forEach((tokenDoc) => {
            tokens.push(tokenDoc.data().token);
          });
        });
      });

      // Commit the batch
      await batch.commit();

      // Send FCM notifications if tokens exist
      if (tokens.length > 0) {
        const message = {
          notification: {
            title,
            body: message,
          },
          data: {
            type,
            priority,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          tokens: tokens,
        };

        const response = await messaging.sendMulticast(message);
        console.log('Successfully sent messages:', response.successCount);
        console.log('Failed to send messages:', response.failureCount);
      }

      return { success: true };
    } catch (error) {
      console.error('Error processing announcement:', error);
      throw error;
    }
  });

// Function triggered when a new notification is created for any driver
exports.driverOnNotificationCreated = functions.firestore
  .document('drivers/{driverId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const driverId = context.params.driverId;
    const { title, message, type = 'admin_message', priority = 'normal' } = notificationData;

    console.log(`New notification created for driver ${driverId}: ${title}`);

    try {
      // Get driver's FCM tokens
      const driverRef = db.collection('drivers').doc(driverId);
      const tokensSnapshot = await driverRef.collection('tokens').get();
      
      if (tokensSnapshot.empty) {
        console.log(`No FCM tokens found for driver ${driverId}`);
        return { success: true, message: 'No FCM tokens found' };
      }

      const tokens = [];
      tokensSnapshot.forEach((tokenDoc) => {
        const tokenData = tokenDoc.data();
        if (tokenData.token) {
          tokens.push(tokenData.token);
        }
      });

      if (tokens.length === 0) {
        console.log(`No valid FCM tokens found for driver ${driverId}`);
        return { success: true, message: 'No valid FCM tokens found' };
      }

      console.log(`Attempting to send notification to ${tokens.length} tokens for driver ${driverId}`);
      console.log(`Tokens: ${tokens.slice(0, 2).map(t => t.substring(0, 20) + '...').join(', ')}`);

      // Send FCM notification to each token individually to avoid batch issues
      const results = [];
      for (const token of tokens) {
        try {
          const messagePayload = {
            token: token,
            notification: {
              title,
              body: message,
            },
            data: {
              type: type || 'admin_message',
              priority: priority || 'normal',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
              driverId: driverId,
              notificationId: context.params.notificationId,
            },
            android: {
              notification: {
                icon: 'truck_icon',
                color: '#FF6B35',
                channel_id: 'driver_notifications',
                sound: 'default',
                priority: 'high',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  'content-available': 1,
                },
              },
            },
          };

          const response = await messaging.send(messagePayload);
          console.log(`Successfully sent to token ${token.substring(0, 20)}...: ${response}`);
          results.push({ success: true, token: token.substring(0, 20) + '...', messageId: response });
        } catch (error) {
          console.log(`Failed to send to token ${token.substring(0, 20)}...:`, error.code, error.message);
          results.push({ success: false, token: token.substring(0, 20) + '...', error: error.code });
          
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            // Delete invalid token
            driverRef.collection('tokens')
              .where('token', '==', token)
              .get()
              .then((tokenQuery) => {
                tokenQuery.forEach((tokenDoc) => {
                  tokenDoc.ref.delete().then(() => {
                    console.log(`Deleted invalid token: ${token.substring(0, 20)}...`);
                  });
                });
              });
          }
        }
      }

      const successCount = results.filter(r => r.success).length;
      const failureCount = results.filter(r => !r.success).length;
      
      console.log(`FCM Individual Send Results - Success: ${successCount}, Failures: ${failureCount}`);
      
      if (successCount > 0) {
        return { success: true, message: `Notification sent to ${successCount}/${tokens.length} devices`, results };
      } else {
        return { success: false, message: 'Failed to send to any devices', results };
      }
    } catch (error) {
      console.error(`Error sending notification for driver ${driverId}:`, error);
      throw error;
    }
  });

// Test FCM configuration
exports.driverTestFCM = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    // Simple test message
    const testMessage = {
      notification: {
        title: 'FCM Test',
        body: 'This is a test notification',
      },
      data: {
        test: 'true',
      },
      topic: 'test_topic', // Send to a topic instead of specific tokens
    };

    const response = await messaging.send(testMessage);
    console.log('Test FCM message sent successfully:', response);
    return { success: true, message: 'Test notification sent', messageId: response };
  } catch (error) {
    console.error('Test FCM error:', error);
    return { success: false, error: error.message, code: error.code };
  }
});

// Clean up invalid tokens periodically
exports.driverCleanupInvalidTokens = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    const driversSnapshot = await db.collection('drivers').get();
    
    for (const driverDoc of driversSnapshot.docs) {
      const tokensSnapshot = await driverDoc.ref.collection('tokens').get();
      
      for (const tokenDoc of tokensSnapshot.docs) {
        const tokenData = tokenDoc.data();
        
        // Test if token is still valid by sending a test message
        try {
          await messaging.send({
            token: tokenData.token,
            data: { test: 'true' }
          });
        } catch (error) {
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            // Delete invalid token
            await tokenDoc.ref.delete();
            console.log(`Deleted invalid token: ${tokenData.token}`);
          }
        }
      }
    }
    
    return { success: true };
  } catch (error) {
    console.error('Error cleaning up tokens:', error);
    throw error;
  }
});
