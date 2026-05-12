import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

admin.initializeApp();
const db = admin.firestore();

/**
 * Bootstrap allowlist — the very first admin(s) must be in this list. Once an
 * account holds the admin claim it can promote others via setAdminClaim.
 *
 * Replace with your own Firebase Auth UIDs (from Firebase Console → Authentication).
 */
const BOOTSTRAP_ADMIN_UIDS = new Set<string>([
  '1vUGw5E72bZD0m8t2k69S2Zy8G72',
]);

// ---------------------------------------------------------------------------
// placeBid — single source of truth for bid integrity. Direct client writes
// to the bids subcollection are denied by Firestore rules; everything flows
// through here.
// ---------------------------------------------------------------------------
export const placeBid = onCall(
  { region: 'us-central1' },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to bid.');

    const auctionId = req.data?.auctionId as string | undefined;
    const amount = Number(req.data?.amount);
    if (!auctionId) throw new HttpsError('invalid-argument', 'auctionId missing.');
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new HttpsError('invalid-argument', 'amount must be a positive number.');
    }

    const auctionRef = db.collection('auctions').doc(auctionId);
    const bidRef = auctionRef.collection('bids').doc();

    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(auctionRef);
      if (!snap.exists) {
        throw new HttpsError('not-found', 'Auction not found.');
      }
      const data = snap.data()!;
      if (data.status !== 'approved') {
        throw new HttpsError('failed-precondition', 'This auction is not live.');
      }
      const endTime = (data.endTime as admin.firestore.Timestamp).toDate();
      if (endTime.getTime() <= Date.now()) {
        throw new HttpsError('failed-precondition', 'This auction has ended.');
      }
      if (data.sellerId === uid) {
        throw new HttpsError('failed-precondition', 'You cannot bid on your own item.');
      }

      const currentBid = Number(data.currentBid) || 0;
      const startingBid = Number(data.startingBid) || 0;
      const minIncrement = Number(data.minBidIncrement) || 0;
      const totalBids = Number(data.totalBids) || 0;
      const minNext = totalBids === 0
        ? startingBid
        : currentBid + (minIncrement > 0 ? minIncrement : 1);
      if (amount < minNext) {
        throw new HttpsError(
          'failed-precondition',
          `Bid must be at least UGX ${minNext.toFixed(0)}.`,
        );
      }

      // Look up bidder display name (cheap, single read outside of hot path).
      const userSnap = await tx.get(db.collection('users').doc(uid));
      const userName = (userSnap.data()?.name as string) ?? 'Bidder';

      // Mark all prior bids non-winning, then create the new winning one.
      // (We do this via a write — for high-traffic auctions, switch to a
      // single winningBidId pointer on the auction doc.)
      tx.set(bidRef, {
        userId: uid,
        userName,
        amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isWinning: true,
      });

      tx.update(auctionRef, {
        currentBid: amount,
        totalBids: admin.firestore.FieldValue.increment(1),
        winningBidId: bidRef.id,
        winningBidder: uid,
      });

      return { bidId: bidRef.id, currentBid: amount };
    });

    return result;
  },
);

// ---------------------------------------------------------------------------
// approveSubmission — admin-only. Approves or rejects a pending listing.
// ---------------------------------------------------------------------------
export const approveSubmission = onCall(
  { region: 'us-central1' },
  async (req) => {
    const uid = req.auth?.uid;
    const isAdmin = req.auth?.token?.admin === true;
    if (!uid || !isAdmin) {
      throw new HttpsError('permission-denied', 'Admin only.');
    }

    const auctionId = req.data?.auctionId as string | undefined;
    const decision = req.data?.decision as string | undefined; // approve | reject
    const reason = req.data?.reason as string | undefined;
    if (!auctionId) throw new HttpsError('invalid-argument', 'auctionId missing.');
    if (decision !== 'approve' && decision !== 'reject') {
      throw new HttpsError('invalid-argument', 'decision must be approve|reject.');
    }

    const ref = db.collection('auctions').doc(auctionId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Auction not found.');
    if (snap.data()?.status !== 'pending') {
      throw new HttpsError('failed-precondition', 'Submission is no longer pending.');
    }

    const update: admin.firestore.UpdateData<admin.firestore.DocumentData> = {
      status: decision === 'approve' ? 'approved' : 'rejected',
      approvedBy: uid,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (decision === 'reject') update.rejectionReason = reason ?? '';

    await ref.update(update);

    // TODO: send FCM notification to seller.

    return { ok: true };
  },
);

// ---------------------------------------------------------------------------
// setAdminClaim — grants the admin custom claim to another user. The caller
// must already be an admin OR appear in BOOTSTRAP_ADMIN_UIDS. Use this once
// to promote your first admin from the Firebase Console, then later admins
// can be promoted from the app itself.
// ---------------------------------------------------------------------------
export const setAdminClaim = onCall(
  { region: 'us-central1' },
  async (req) => {
    const callerUid = req.auth?.uid;
    if (!callerUid) throw new HttpsError('unauthenticated', 'Sign in.');

    const isAdmin = req.auth?.token?.admin === true;
    const isBootstrap = BOOTSTRAP_ADMIN_UIDS.has(callerUid);
    if (!isAdmin && !isBootstrap) {
      throw new HttpsError(
        'permission-denied',
        'Only admins (or bootstrap UIDs) can grant the admin claim.',
      );
    }

    const targetUid = req.data?.uid as string | undefined;
    const grant = req.data?.grant !== false; // default true
    if (!targetUid) throw new HttpsError('invalid-argument', 'uid required.');

    await admin.auth().setCustomUserClaims(targetUid, { admin: grant });
    await db.collection('users').doc(targetUid).set(
      { role: grant ? 'admin' : 'user' },
      { merge: true },
    );

    return { ok: true, targetUid, admin: grant };
  },
);

// ---------------------------------------------------------------------------
// onUserCreate — ensure a users/{uid} doc exists immediately on sign-up so
// subsequent reads in placeBid don't race the client-side write.
// ---------------------------------------------------------------------------
export const onUserCreate = functions.identity.beforeUserCreated(async (event) => {
  const user = event.data;
  if (!user) return;
  await db.collection('users').doc(user.uid).set(
    {
      name: user.displayName ?? user.email?.split('@')[0] ?? 'New bidder',
      email: user.email ?? null,
      photoUrl: user.photoURL ?? null,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
      role: 'user',
    },
    { merge: true },
  );
});
