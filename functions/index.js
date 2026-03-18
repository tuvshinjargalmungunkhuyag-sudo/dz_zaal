const { setGlobalOptions } = require('firebase-functions');
const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const Anthropic = require('@anthropic-ai/sdk');

setGlobalOptions({ maxInstances: 10 });

const claudeApiKey = defineSecret('CLAUDE_API_KEY');

const SYSTEM_PROMPT = `Та бол "Говийн Спорт" аппликейшний туслах ажилтан юм.
Даланзадгад хотын спорт заалнуудын захиалга хийхэд тусалдаг.

Манай заалнууд:
- Говийн Аренa (Сагсан бөмбөг) — 15,000₮/цаг, 1-р хороо
- Өмнөговь Фитнес — 10,000₮/цаг, 2-р хороо
- Говийн Теннис Клуб — 20,000₮/цаг, Голомт
- Хурдан Хөл Бөмбөг — 25,000₮/цаг, Стадион
- Говийн Бөхийн Танхим — 12,000₮/цаг, 3-р хороо

Цагийн хуваарь: 08:00–20:00 (1 цагийн слот)
Захиалгын процесс: Заал сонгох → Өдөр сонгох → Цаг сонгох → Баталгаажуулах

Монгол хэлээр товч, хэрэгтэй мэдээллийг өгнө үү.
Говийн амьдрал: 🐪 тэмээ, 🦅 ёл шувуу, 🐻 мазаалай — манай бэлэгдэл!`;

exports.chat = onCall(
  { secrets: [claudeApiKey] },
  async (request) => {
    const { messages } = request.data;
    if (!messages || !Array.isArray(messages)) {
      throw new Error('messages талбар шаардлагатай');
    }

    const client = new Anthropic({ apiKey: claudeApiKey.value() });
    const response = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages,
    });
    return { content: response.content[0].text };
  }
);
