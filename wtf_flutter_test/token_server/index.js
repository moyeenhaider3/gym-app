require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const uuid4 = require('uuid4');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const HMS_ACCESS_KEY = process.env.HMS_ACCESS_KEY;
const HMS_SECRET = process.env.HMS_SECRET;
const HMS_ROOM_ID = process.env.HMS_ROOM_ID;

// ─── In-Memory Stores ──────────────────────────────────────────────────────────

const users = [];
const messages = [];
const callRequests = [];
const sessionLogs = [];

// ─── Helpers ────────────────────────────────────────────────────────────────────

function genId() { return uuid4().replace(/-/g, '').substring(0, 16); }

// ─── 100ms Token Generation ────────────────────────────────────────────────────

app.get('/api/token', (req, res) => {
  const { userId, role, roomId } = req.query;
  if (!userId || !role) {
    return res.status(400).json({ error: 'userId and role required' });
  }

  const payload = {
    access_key: HMS_ACCESS_KEY,
    room_id: roomId || HMS_ROOM_ID,
    user_id: userId,
    role: role,
    type: 'app',
    version: 2,
    iat: Math.floor(Date.now() / 1000),
    nbf: Math.floor(Date.now() / 1000),
  };

  jwt.sign(
    payload,
    HMS_SECRET,
    { algorithm: 'HS256', expiresIn: '24h', jwtid: uuid4() },
    (err, token) => {
      if (err) return res.status(500).json({ error: 'Token generation failed', details: err.message });
      res.json({ token });
    }
  );
});

// ─── Auth ───────────────────────────────────────────────────────────────────────

app.post('/api/auth/login', (req, res) => {
  const { userId, role, name, email, avatarUrl } = req.body;
  if (!userId || !role || !name) {
    return res.status(400).json({ error: 'userId, role, name required' });
  }

  let user = users.find(u => u.id === userId);
  if (!user) {
    user = {
      id: userId,
      role,
      name,
      email: email || '',
      avatarUrl: avatarUrl || '',
      assignedTrainerId: null,
      createdAt: new Date().toISOString(),
    };
    users.push(user);
  } else {
    Object.assign(user, { role, name, email: email || user.email });
  }
  res.json({ user });
});

app.patch('/api/auth/assign-trainer', (req, res) => {
  const { memberId, trainerId } = req.body;
  const member = users.find(u => u.id === memberId);
  if (!member) return res.status(404).json({ error: 'Member not found' });
  member.assignedTrainerId = trainerId;
  res.json({ user: member });
});

app.get('/api/users', (req, res) => {
  const { role } = req.query;
  if (role) {
    return res.json({ users: users.filter(u => u.role === role) });
  }
  res.json({ users });
});

// ─── Chat Messages ──────────────────────────────────────────────────────────────

app.post('/api/messages', (req, res) => {
  const { senderId, receiverId, text } = req.body;
  if (!senderId || !receiverId || !text) {
    return res.status(400).json({ error: 'senderId, receiverId, text required' });
  }

  // chatId = sorted pair of user IDs
  const chatId = [senderId, receiverId].sort().join('_');

  const message = {
    id: genId(),
    chatId,
    senderId,
    receiverId,
    text,
    createdAt: new Date().toISOString(),
    status: 'sent', // sent | read
  };
  messages.push(message);
  res.json({ message });
});

app.get('/api/messages', (req, res) => {
  const { chatId, after, senderId, receiverId } = req.query;

  let filtered = messages;

  if (chatId) {
    filtered = filtered.filter(m => m.chatId === chatId);
  } else if (senderId && receiverId) {
    const cid = [senderId, receiverId].sort().join('_');
    filtered = filtered.filter(m => m.chatId === cid);
  }

  if (after) {
    const afterDate = new Date(after);
    filtered = filtered.filter(m => new Date(m.createdAt) > afterDate);
  }

  res.json({ messages: filtered });
});

app.patch('/api/messages/:id/read', (req, res) => {
  const msg = messages.find(m => m.id === req.params.id);
  if (!msg) return res.status(404).json({ error: 'Message not found' });
  msg.status = 'read';
  res.json({ message: msg });
});

// Batch mark as read
app.patch('/api/messages/read', (req, res) => {
  const { chatId, readerId } = req.body;
  if (!chatId || !readerId) {
    return res.status(400).json({ error: 'chatId, readerId required' });
  }
  const updated = [];
  messages.forEach(m => {
    if (m.chatId === chatId && m.receiverId === readerId && m.status !== 'read') {
      m.status = 'read';
      updated.push(m);
    }
  });
  res.json({ updated: updated.length });
});

// Get chat list for a user
app.get('/api/chats', (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: 'userId required' });

  // Group messages by chatId
  const chatMap = {};
  messages.forEach(m => {
    if (m.senderId === userId || m.receiverId === userId) {
      if (!chatMap[m.chatId] || new Date(m.createdAt) > new Date(chatMap[m.chatId].lastMessage.createdAt)) {
        const otherUserId = m.senderId === userId ? m.receiverId : m.senderId;
        const otherUser = users.find(u => u.id === otherUserId);
        const unreadCount = messages.filter(
          msg => msg.chatId === m.chatId && msg.receiverId === userId && msg.status !== 'read'
        ).length;

        chatMap[m.chatId] = {
          chatId: m.chatId,
          otherUser: otherUser || { id: otherUserId, name: 'Unknown' },
          lastMessage: m,
          unreadCount,
        };
      }
    }
  });

  const chats = Object.values(chatMap).sort(
    (a, b) => new Date(b.lastMessage.createdAt) - new Date(a.lastMessage.createdAt)
  );
  res.json({ chats });
});

// ─── Call Requests ───────────────────────────────────────────────────────────────

app.post('/api/call-requests', (req, res) => {
  const { memberId, trainerId, scheduledFor, note } = req.body;
  if (!memberId || !trainerId || !scheduledFor) {
    return res.status(400).json({ error: 'memberId, trainerId, scheduledFor required' });
  }

  // Check past time
  if (new Date(scheduledFor) < new Date()) {
    return res.status(400).json({ error: 'Cannot schedule in the past' });
  }

  // Conflict check — same time already approved
  const conflict = callRequests.find(
    cr => cr.trainerId === trainerId &&
          cr.scheduledFor === scheduledFor &&
          cr.status === 'approved'
  );
  if (conflict) {
    return res.status(409).json({ error: 'Time slot already has an approved call' });
  }

  const callRequest = {
    id: genId(),
    memberId,
    trainerId,
    requestedAt: new Date().toISOString(),
    scheduledFor,
    note: note || '',
    status: 'pending', // pending | approved | declined | cancelled
    declineReason: null,
    roomMeta: null,
  };
  callRequests.push(callRequest);
  res.json({ callRequest });
});

app.get('/api/call-requests', (req, res) => {
  const { trainerId, memberId, status } = req.query;
  let filtered = callRequests;
  if (trainerId) filtered = filtered.filter(cr => cr.trainerId === trainerId);
  if (memberId) filtered = filtered.filter(cr => cr.memberId === memberId);
  if (status) filtered = filtered.filter(cr => cr.status === status);
  res.json({ callRequests: filtered });
});

app.patch('/api/call-requests/:id', (req, res) => {
  const cr = callRequests.find(c => c.id === req.params.id);
  if (!cr) return res.status(404).json({ error: 'Call request not found' });

  const { status, declineReason } = req.body;

  if (status === 'approved') {
    // Conflict check again
    const conflict = callRequests.find(
      c => c.id !== cr.id &&
           c.trainerId === cr.trainerId &&
           c.scheduledFor === cr.scheduledFor &&
           c.status === 'approved'
    );
    if (conflict) {
      return res.status(409).json({ error: 'Time slot conflict' });
    }

    cr.status = 'approved';
    cr.roomMeta = {
      id: genId(),
      callRequestId: cr.id,
      hmsRoomId: HMS_ROOM_ID,
      hmsRoleMember: process.env.HMS_ROLE_MEMBER || 'guest',
      hmsRoleTrainer: process.env.HMS_ROLE_TRAINER || 'host',
    };

    // Send system chat message
    const chatId = [cr.memberId, cr.trainerId].sort().join('_');
    const scheduledDate = new Date(cr.scheduledFor);
    const timeStr = scheduledDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    const dateStr = scheduledDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    messages.push({
      id: genId(),
      chatId,
      senderId: 'system',
      receiverId: 'all',
      text: `Call approved for ${dateStr} ${timeStr}.`,
      createdAt: new Date().toISOString(),
      status: 'sent',
    });
  } else if (status === 'declined') {
    cr.status = 'declined';
    cr.declineReason = declineReason || '';

    // Send system chat message
    const chatId = [cr.memberId, cr.trainerId].sort().join('_');
    messages.push({
      id: genId(),
      chatId,
      senderId: 'system',
      receiverId: 'all',
      text: `Call request declined. Reason: ${cr.declineReason || 'No reason given'}.`,
      createdAt: new Date().toISOString(),
      status: 'sent',
    });
  } else if (status === 'cancelled') {
    cr.status = 'cancelled';
  }

  res.json({ callRequest: cr });
});

// ─── Session Logs ───────────────────────────────────────────────────────────────

app.post('/api/session-logs', (req, res) => {
  const { memberId, trainerId, startedAt, endedAt } = req.body;
  if (!memberId || !trainerId || !startedAt || !endedAt) {
    return res.status(400).json({ error: 'memberId, trainerId, startedAt, endedAt required' });
  }

  const start = new Date(startedAt);
  const end = new Date(endedAt);
  const durationSec = Math.floor((end - start) / 1000);

  const log = {
    id: genId(),
    memberId,
    trainerId,
    startedAt,
    endedAt,
    durationSec,
    rating: null,
    trainerNotes: null,
    memberNotes: null,
    createdAt: new Date().toISOString(),
  };
  sessionLogs.push(log);
  res.json({ sessionLog: log });
});

app.get('/api/session-logs', (req, res) => {
  const { userId } = req.query;
  let filtered = sessionLogs;
  if (userId) {
    filtered = filtered.filter(l => l.memberId === userId || l.trainerId === userId);
  }
  filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  res.json({ sessionLogs: filtered });
});

app.patch('/api/session-logs/:id', (req, res) => {
  const log = sessionLogs.find(l => l.id === req.params.id);
  if (!log) return res.status(404).json({ error: 'Session log not found' });

  const { rating, trainerNotes, memberNotes } = req.body;
  if (rating !== undefined) log.rating = rating;
  if (trainerNotes !== undefined) log.trainerNotes = trainerNotes;
  if (memberNotes !== undefined) log.memberNotes = memberNotes;

  res.json({ sessionLog: log });
});

// ─── Polling Endpoint ───────────────────────────────────────────────────────────

app.get('/api/poll', (req, res) => {
  const { userId, since } = req.query;
  if (!userId) return res.status(400).json({ error: 'userId required' });

  const sinceDate = since ? new Date(since) : new Date(0);

  // New messages for this user
  const newMessages = messages.filter(
    m => (m.receiverId === userId || m.receiverId === 'all') &&
         new Date(m.createdAt) > sinceDate &&
         // Include messages in chats this user is part of
         (m.chatId.includes(userId) || m.senderId === 'system')
  );

  // Call request updates
  const requestUpdates = callRequests.filter(
    cr => (cr.memberId === userId || cr.trainerId === userId)
  );

  // Read status updates — messages this user sent that got read
  const readUpdates = messages.filter(
    m => m.senderId === userId &&
         m.status === 'read' &&
         new Date(m.createdAt) > sinceDate
  );

  res.json({
    newMessages,
    callRequests: requestUpdates,
    readUpdates,
    serverTime: new Date().toISOString(),
  });
});

// ─── Health ─────────────────────────────────────────────────────────────────────

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    stores: {
      users: users.length,
      messages: messages.length,
      callRequests: callRequests.length,
      sessionLogs: sessionLogs.length,
    },
  });
});

// ─── Start ──────────────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Token server running on http://0.0.0.0:${PORT}`);
  console.log(`   HMS Room ID: ${HMS_ROOM_ID}`);
  console.log(`   Access Key: ${HMS_ACCESS_KEY?.substring(0, 8)}...`);
  console.log(`\n   Endpoints:`);
  console.log(`   GET  /api/health`);
  console.log(`   GET  /api/token?userId=X&role=X`);
  console.log(`   POST /api/auth/login`);
  console.log(`   POST /api/messages`);
  console.log(`   GET  /api/messages?chatId=X`);
  console.log(`   GET  /api/chats?userId=X`);
  console.log(`   POST /api/call-requests`);
  console.log(`   GET  /api/call-requests?trainerId=X`);
  console.log(`   PATCH /api/call-requests/:id`);
  console.log(`   POST /api/session-logs`);
  console.log(`   GET  /api/session-logs?userId=X`);
  console.log(`   GET  /api/poll?userId=X&since=X`);
});
