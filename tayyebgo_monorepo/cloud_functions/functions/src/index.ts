import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Scheduled function: runs daily to create payouts for vendors with completed orders
 * in the previous period. Skeleton — logs intent only.
 */
export const processPayouts = functions.scheduler.onSchedule(
  '0 6 * * *',
  async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    console.log(`[processPayouts] Running payout cycle for ${yesterday.toISOString()} — ${today.toISOString()}`);

    // TODO: Query completed orders in date range, group by vendor,
    //       calculate commission, create payout docs in Firestore
    console.log('[processPayouts] Skeleton — no payouts created yet');
  },
);
