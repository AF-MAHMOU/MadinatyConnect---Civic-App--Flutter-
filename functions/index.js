const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Configuration, OpenAIApi } = require("openai");

admin.initializeApp();

const Configuration = new Configuration({
      apiKey: functions.config().openai.key,
});

const openai = new OpenAIApi(Configuration);

exports.moderateAndAddComment = functions.https.onCall(async (data, context) => {
  const { announcementId, content, isAnonymous } = data;

  if (!announcementId || !content) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing parameters.');
  }

  // Call OpenAI Moderation API
  try {
    const moderationResponse = await openai.createModeration({
      input: content,
    });

    const flagged = moderationResponse.data.results[0].flagged;

    if (flagged) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Comment contains offensive content.'
    )
}
  const commentRef = await admin.firestore()
      .collection('announcements')
      .doc(announcementId)
      .collection('comments')
      .add({
        content,
        isAnonymous,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { success: true, commentId: commentRef.id };

  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('Moderation function error:', error);
    throw new functions.https.HttpsError('internal', 'Internal server error.');
  }
});