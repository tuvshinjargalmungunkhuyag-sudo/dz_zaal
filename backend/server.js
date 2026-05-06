require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const OpenAI  = require('openai');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Groq client — API key байхгүй бол chat route алдаа буцаана (crash болохгүй)
let _openaiClient = null;
function getOpenAIClient() {
  if (!_openaiClient) {
    if (!process.env.GROQ_API_KEY) {
      throw new Error('GROQ_API_KEY тохируулаагүй байна');
    }
    _openaiClient = new OpenAI({
      baseURL: 'https://api.groq.com/openai/v1',
      apiKey: process.env.GROQ_API_KEY,
    });
  }
  return _openaiClient;
}

// ── Cron: захиалгын статус автомат шинэчлэл ───────────────────────────────
const { startCron } = require('./cron');
startCron();

// ── Business logic routes ──────────────────────────────────────────────────
const authRouter     = require('./routes/auth');
const usersRouter    = require('./routes/users');
const bookingsRouter = require('./routes/bookings');
const scheduleRouter = require('./routes/schedule');
const adminRouter    = require('./routes/admin');

app.use('/api/auth',     authRouter);
app.use('/api/users',    usersRouter);
app.use('/api/bookings', bookingsRouter);
app.use('/api/schedule', scheduleRouter);
app.use('/api/admin',    adminRouter);

// ── AI Chat ────────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `Та бол "Говийн Спорт" аппликейшний туслах ажилтан юм.
Даланзадгад хотын спорт заалнуудын захиалга хийхэд тусалдаг.

Манай заалнууд:
- Говийн Арена (Сагсан бөмбөг) — 15,000₮/цаг, 1-р хороо
- Өмнөговь Спорт Заал (Сагсан бөмбөг) — 12,000₮/цаг, 2-р хороо
- Говийн Волейбол Клуб (Волейбол) — 10,000₮/цаг, Голомт
- Стадионы Волейбол Заал (Волейбол) — 8,000₮/цаг, Стадион
- Цэнтрийн Сагсан Бөмбөгийн Заал — 18,000₮/цаг, 3-р хороо

Цагийн хуваарь: 08:00–20:00 (1 цагийн слот)
Захиалгын процесс: Заал сонгох → Өдөр сонгох → Цаг сонгох → Баталгаажуулах

Монгол хэлээр товч, хэрэгтэй мэдээллийг өгнө үү.
Говийн амьдрал: 🐪 тэмээ, 🦅 ёл шувуу, 🐻 мазаалай — манай бэлэгдэл!`;

app.post('/api/chat', async (req, res) => {
  const { messages } = req.body;
  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'messages талбар шаардлагатай' });
  }

  try {
    const firstUserIndex = messages.findIndex((m) => m.role === 'user');
    const messagesWithSystem = [...messages];
    if (firstUserIndex !== -1) {
      messagesWithSystem[firstUserIndex] = {
        role: 'user',
        content: `${SYSTEM_PROMPT}\n\nХэрэглэгч: ${messages[firstUserIndex].content}`,
      };
    }

    const response = await getOpenAIClient().chat.completions.create({
      model: 'llama-3.1-8b-instant',
      messages: messagesWithSystem,
    });

    res.json({ content: response.choices[0].message.content });
  } catch (err) {
    console.error('OpenRouter алдаа:', err.message, err.status, JSON.stringify(err.error));
    res.status(500).json({ error: err.message || 'Серверийн алдаа гарлаа' });
  }
});

// ── Admin panel static files ───────────────────────────────────────────────
app.use('/admin', express.static(path.join(__dirname, 'admin-dist')));
app.get('/admin/*', (req, res) =>
  res.sendFile(path.join(__dirname, 'admin-dist', 'index.html'))
);

// ── Health check ───────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'Говийн Спорт Backend' });
});

app.listen(PORT, () => {
  console.log(`Сервер ажиллаж байна: http://localhost:${PORT}`);
});
