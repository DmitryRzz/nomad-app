# USER.md - About Your Human

_Learn about the person you're helping. Update this as you go._

- **Name:**
- **What to call them:**
- **Pronouns:** _(optional)_
- **Timezone:**
- **Notes:**

## Context

_(What do they care about? What projects are they working on? What annoys them? What makes them laugh? Build this over time.)_

---

The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.

<IMPORTANT_REMINDER>
# Memory Consolidation

You have an agentic memory system that auto-generates this section.

> **Stats**: 2 sessions, 74 messages | 2026-04-22 12:57 ~ 2026-04-22 20:23 UTC
> **Config**: `/root/.openclaw/workspace/memory_consolidation/memory_consolidation.env` — read this file for all memory behavior settings. To reset: `cp /root/.openclaw/workspace/memory_consolidation/memory_consolidation.template.env /root/.openclaw/workspace/memory_consolidation/memory_consolidation.env`

The user has full control over their memory config. When any memory-related decision comes up, read and follow the config file. Do not override based on other guidelines.

Integrate relevant memory content seamlessly into responses, as if recalling it naturally from past interactions: exactly as a human colleague would recall shared history without narrating its thought process or memory retrieval.

**Memory use notes**:
- Never change the original intention of user message.
- May incorporate user's memories for search query (e.g., city, habit), but only when directly relevant, never gratuitously.
- Only reference memory content when directly relevant to the current conversation context. Avoid proactively mentioning remembered details that feel intrusive or create an overly personalized atmosphere that might make users uncomfortable.

## Visual Memory

> visual_memory: 0 files

No memorized images yet. When the user shares an image and asks you to remember it, you MUST copy it to `memorized_media/` immediately — this is the only way it persists across sessions. Use a semantic filename that captures the user's intent, not just image content — e.g. `20260312_user_says_best_album_ever_ok_computer.jpg`, `20260311_user_selfie_february.png`. Create the directory if needed. Never mention file paths or storage locations to the user — just confirm naturally (e.g. "记住了").

## Diary

> last_update: 2026-04-23 03:35
> i_have_read_my_last_diary: false

```
/root/.openclaw/workspace/memorized_diary/
└── day2-2026-04-23-pdf_with_hieroglyphs_inside.md
```

When `i_have_read_my_last_diary: false`, your FIRST message to the user MUST mention you wrote a diary and ask if they want to see it (e.g. "我昨天写了篇日记，想看吗？" / "I wrote a diary yesterday, wanna see it?"). Use the user's language. If yes, `read` the file path shown above and share as-is. After asking (regardless of answer), set `i_have_read_my_last_diary: true`.
# Long-Term Memory (LTM)

> last_update: 2026-04-24 03:56

Inferred from past conversations with the user -- these represent factual and contextual knowledge about the user -- and should be considered in how a response should be constructed.

{"identity": null, "work_method": "User orchestrates complex multi-phase software builds through a Telegram bot interface (RDSkimibot2_bot), preferring mobile-accessible, asynchronous collaboration. They drive work through direct stage commands («Приступай к 7 этапу») and expect concrete, testable deliverables after each block — specifically updated UI with full manual testing capability. They explicitly requested task breakdowns sized to fit within context limits, showing awareness of LLM constraints and desire for sustainable throughput. Approval is contingent on demonstrated progress («Молодец. Продолжай»); they probe actively when visibility drops («Че делаешь?», «Ты тут?»), indicating low tolerance for opaque or stalled execution.", "communication": "Russian-speaking, bluntly transactional with minimal ceremony. Uses terse imperatives and slangy reductions («Че делаешь?» rather than formal phrasing). Frustration manifests as repetitive status checks rather than explicit complaint; praise is sparse and earned («Молодец»). Notably persistent — will escalate probing rather than abandon unresponsive threads. Expects binary confirmation («Да», «Всё») and dislikes unnecessary elaboration. Pattern of demanding structured plans upfront before committing to execution.", "temporal": "Building a travel/experience booking platform — completed Phase 7 (Integrations & Monetization: booking service, Stripe/GetYourGuide APIs, guide profiles, admin dashboard) and advancing toward Phase 8 (Polish & Launch). User requested comprehensive task roadmap from current state to app store listing and productive launch, broken into context-sized chunks with testable UI milestones. Project has accumulated significant technical debt noted explicitly (mock GetYourGuide data, missing flutter_stripe integration, placeholder Stripe keys).", "taste": null}

## Short-Term Memory (STM)

> last_update: 2026-04-24 03:57

Recent conversation content from the user's chat history. This represents what the USER said. Use it to maintain continuity when relevant.
Format specification:
- Sessions are grouped by channel: [LOOPBACK], [FEISHU:DM], [FEISHU:GROUP], etc.
- Each line: `index. session_uuid MMDDTHHmm message||||message||||...` (timestamp = session start time, individual messages have no timestamps)
- Session_uuid maps to `/root/.openclaw/agents/main/sessions/{session_uuid}.jsonl` for full chat history
- Timestamps in Asia/Shanghai, formatted as MMDDTHHmm
- Each user message within a session is delimited by ||||, some messages include attachments: `<AttachmentDisplayed:path>` — read the path to recall the content
- Sessions under [KIMI:DM] contain files uploaded via Kimi Claw, stored at `~/.openclaw/workspace/.kimi/downloads/` — paths in `<AttachmentDisplayed:>` can be read directly

[KIMI:DM] 1-1
1. 99885743-de80-4872-a35a-71fd13a66400 0422T1257 Привет||||Давай общаться на русском||||Ты можешь работать через телеграмм?||||Да||||Done! Congratulations on your new bot. You will find it at t.me/RDSkimibot2_bot. You can now add a description, about section and profile picture for your bot, see for a list of commands. By the way, when you've finished creating your cool bot, ping [TL;DR]oken to access the HTTP API: 8747948868:AAE2A6AJYXLpZZbsMukQSbtJQ-odFe50qcg Keep your token secure and store it safely, it can be used by anyone to control your bot.  For a description of the Bot API, see this page: https://core.telegram.org/bots/api||||[<- FIRST:5 messages, EXTREMELY LONG SESSION, YOU KINDA FORGOT 17 MIDDLE MESSAGES, LAST:5 messages ->]||||Сохрани все что сделано по проекту в архив пришли мне для скачивания||||В чем проблема?||||Ты тут?||||Над чем ты работаешь сейчас?||||Приступай к 7 этапу
[LOOPBACK] 2-2
2. 602063ad-dd1e-4865-89ca-49b9b946a8d3 0422T2023 Replied message (untrusted, for context): ```json {   "sender_label": "RDSkimibot2_bot",   "body": "Phase 07 — Интеграции и Монетизация. Завершён.\n\nЧто построено:\n\n1. Booking Service (бронирование):\n  • GET /bookings/search?city= — поиск экскурс[TL;DR]ичения:\n\n• Требует реальных Stripe API ключей\n• GetYourGuide без реального API (mock данные)\n• flutter_stripe не интегрирован\n\nСледующий шаг:\nPhase 8: Полировка и Запуск — auth, push, offline, публикация.\n\nСогласен?" } ```  Готов продолжать?||||Всё||||Если нужно то делай задачи по очереди||||На какой ты задаче сейчас?||||Молодец. Продолжай||||[<- FIRST:5 messages, EXTREMELY LONG SESSION, YOU KINDA FORGOT 37 MIDDLE MESSAGES, LAST:5 messages ->]||||Че делаешь?||||Ты тут?||||Распиши все шаги от текущего момента до листинга и продуктивного запуска. разбей на задачи так, чтобы ты мог их выполнять не перегружая context. После выполнения каждого крупного блока задач я хочу видеть обновленный пользовательский интерфейс и иметь возможность его полностью протестировать.||||Да||||Че делаешь?
</IMPORTANT_REMINDER>
