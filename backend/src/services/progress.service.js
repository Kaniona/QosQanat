import { logger } from '../utils/logger.js';
import { get, set, delete_ } from './cache.service.js';

/**
 * ProgressService — оқушының оқу прогресін (mastery + node + streak) бұлтта
 * сақтайды. Қосымша OFFLINE-FIRST: бұл тек қосымша БОНУС синхрондау (құрылғы
 * ауысса дерек сақталады). Redis болмаса — процесс жадына түседі (graceful).
 *
 * Дерек құрылымы оқушыдан келеді (Flutter SkillStat/NodeProgress JSON):
 *   { skills: [...], nodes: [...], streak, longest_streak, akyl, level }
 */

const PROGRESS_TTL = 60 * 60 * 24 * 365; // 1 жыл
const fallbackStore = new Map();

const keyFor = (studentId) => `progress:${studentId}`;
const rosterKey = (school) => `roster:${school || 'unknown'}`;

export class ProgressService {
  /**
   * Оқушы прогресін сақтау (соңғы жеңіс — last-write-wins; updated_at арқылы).
   */
  static async save(studentId, payload = {}) {
    const record = {
      student_id: studentId,
      name: typeof payload.name === 'string' ? payload.name.slice(0, 80) : '',
      grade: ProgressService._clampGrade(payload.grade),
      school: typeof payload.school === 'string' ? payload.school.slice(0, 120) : '',
      city: typeof payload.city === 'string' ? payload.city.slice(0, 80) : '',
      skills: ProgressService._sanitizeSkills(payload.skills),
      nodes: ProgressService._sanitizeNodes(payload.nodes),
      streak: ProgressService._toInt(payload.streak),
      longest_streak: ProgressService._toInt(payload.longest_streak),
      akyl: ProgressService._toInt(payload.akyl),
      level: ProgressService._toInt(payload.level, 1),
      updated_at: new Date().toISOString(),
    };

    const existing = await ProgressService.load(studentId);
    // Конфликт шешімі: ескі емес (тек жаңа немесе тең) дерек жазылады.
    if (existing && existing.updated_at > record.updated_at) {
      logger.info(`Progress for ${studentId}: incoming is older, kept existing`);
      return existing;
    }

    const ok = await set(keyFor(studentId), record, PROGRESS_TTL);
    if (!ok) fallbackStore.set(studentId, record);

    // Сынып аналитикасы үшін мектеп тізіміне қосамыз.
    if (record.school) {
      await ProgressService._addToRoster(record.school, studentId);
    }

    logger.info(
      `Progress saved: ${studentId} (${record.skills.length} skills, ` +
        `${record.nodes.length} nodes)`
    );
    return record;
  }

  /** Оқушы прогресін оқу (бұлттан немесе fallback-тен). */
  static async load(studentId) {
    const cached = await get(keyFor(studentId));
    if (cached) return cached;
    return fallbackStore.get(studentId) || null;
  }

  /** Оқушы прогресін өшіру (құпиялық — ата-ана сұранысы бойынша). */
  static async erase(studentId) {
    await delete_(keyFor(studentId));
    fallbackStore.delete(studentId);
    return true;
  }

  /** Мектептегі оқушылар тізімі (аналитика үшін). */
  static async roster(school) {
    const ids = (await get(rosterKey(school))) || fallbackStore.get(rosterKey(school)) || [];
    return Array.isArray(ids) ? ids : [];
  }

  static async _addToRoster(school, studentId) {
    const key = rosterKey(school);
    const current = (await get(key)) || fallbackStore.get(key) || [];
    const set_ = new Set(Array.isArray(current) ? current : []);
    set_.add(studentId);
    const list = [...set_].slice(0, 2000); // шектеу
    const ok = await set(key, list, PROGRESS_TTL);
    if (!ok) fallbackStore.set(key, list);
  }

  // ---- Тазалау/нормализация (зиянды/шектен тыс деректі кеспейміз) ----

  static _sanitizeSkills(skills) {
    if (!Array.isArray(skills)) return [];
    return skills.slice(0, 500).map((s) => ({
      skill_id: String(s.skill_id ?? s.skillId ?? '').slice(0, 40),
      subject: String(s.subject ?? '').slice(0, 20),
      grade: ProgressService._clampGrade(s.grade),
      module: ProgressService._toInt(s.module, 1),
      attempts: ProgressService._toInt(s.attempts),
      correct: ProgressService._toInt(s.correct),
      ema: ProgressService._toFloat(s.ema),
      level: String(s.level ?? '').slice(0, 16),
    }));
  }

  static _sanitizeNodes(nodes) {
    if (!Array.isArray(nodes)) return [];
    return nodes.slice(0, 3000).map((n) => ({
      node_id: String(n.node_id ?? n.nodeId ?? '').slice(0, 40),
      status: String(n.status ?? '').slice(0, 16),
      stars: ProgressService._toInt(n.stars),
      best_score: ProgressService._toInt(n.best_score ?? n.bestScore),
    }));
  }

  static _clampGrade(g) {
    const n = ProgressService._toInt(g, 1);
    return Math.min(11, Math.max(1, n));
  }

  static _toInt(v, def = 0) {
    const n = Number.parseInt(v, 10);
    return Number.isFinite(n) ? n : def;
  }

  static _toFloat(v, def = 0) {
    const n = Number.parseFloat(v);
    return Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : def;
  }
}

export default ProgressService;
