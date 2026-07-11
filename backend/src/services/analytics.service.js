import { logger } from '../utils/logger.js';
import ProgressService from './progress.service.js';

/**
 * AnalyticsService — синхрондалған прогрестен оқушы мен СЫНЫП аналитикасын
 * есептейді (мұғалім/ата-ана панелі үшін). Бәрі сақталған деректен туынды —
 * жеке дерек қосымша сақталмайды.
 */
export class AnalyticsService {
  static _level(ema, attempts) {
    if (attempts === 0) return 'fresh';
    if (attempts < 2) return 'learning';
    if (ema >= 0.85 && attempts >= 4) return 'mastered';
    if (ema >= 0.6) return 'proven';
    return 'learning';
  }

  /** Бір оқушының аналитикасы. */
  static async student(studentId) {
    const progress = await ProgressService.load(studentId);
    if (!progress) return null;

    const skills = progress.skills || [];
    const practiced = skills.filter((s) => s.attempts > 0);

    const dist = { fresh: 0, learning: 0, proven: 0, mastered: 0 };
    let emaSum = 0;
    const weak = [];
    const bySubject = {};

    for (const s of practiced) {
      const level = s.level || AnalyticsService._level(s.ema, s.attempts);
      dist[level] = (dist[level] || 0) + 1;
      emaSum += s.ema;
      if (level === 'learning') {
        weak.push({ skill_id: s.skill_id, subject: s.subject, ema: s.ema });
      }
      bySubject[s.subject] = bySubject[s.subject] || { practiced: 0, emaSum: 0 };
      bySubject[s.subject].practiced += 1;
      bySubject[s.subject].emaSum += s.ema;
    }

    weak.sort((a, b) => a.ema - b.ema);

    const subjects = Object.fromEntries(
      Object.entries(bySubject).map(([k, v]) => [
        k,
        {
          practiced: v.practiced,
          accuracy: v.practiced ? +(v.emaSum / v.practiced).toFixed(3) : 0,
        },
      ])
    );

    return {
      student_id: studentId,
      name: progress.name,
      grade: progress.grade,
      streak: progress.streak,
      level: progress.level,
      overall_accuracy: practiced.length
        ? +(emaSum / practiced.length).toFixed(3)
        : 0,
      topics_practiced: practiced.length,
      mastered: dist.mastered,
      level_distribution: dist,
      weak_topics: weak.slice(0, 8),
      subjects,
      updated_at: progress.updated_at,
    };
  }

  /** Сынып/мектеп аналитикасы (мұғалімге агрегат). */
  static async classFor(school) {
    const ids = await ProgressService.roster(school);
    const students = [];
    let accSum = 0;
    let accCount = 0;
    const weakCounter = {}; // skill_id -> {subject, count, emaSum}

    for (const id of ids) {
      const a = await AnalyticsService.student(id);
      if (!a) continue;
      students.push({
        student_id: a.student_id,
        name: a.name,
        grade: a.grade,
        accuracy: a.overall_accuracy,
        mastered: a.mastered,
        streak: a.streak,
      });
      if (a.topics_practiced > 0) {
        accSum += a.overall_accuracy;
        accCount += 1;
      }
      for (const w of a.weak_topics) {
        const c = (weakCounter[w.skill_id] = weakCounter[w.skill_id] || {
          subject: w.subject,
          count: 0,
          emaSum: 0,
        });
        c.count += 1;
        c.emaSum += w.ema;
      }
    }

    students.sort((a, b) => b.accuracy - a.accuracy);

    const commonWeak = Object.entries(weakCounter)
      .map(([skill_id, v]) => ({
        skill_id,
        subject: v.subject,
        students_struggling: v.count,
        avg_ema: +(v.emaSum / v.count).toFixed(3),
      }))
      .sort((a, b) => b.students_struggling - a.students_struggling)
      .slice(0, 10);

    logger.info(`Class analytics for ${school}: ${students.length} students`);

    return {
      school,
      student_count: students.length,
      class_accuracy: accCount ? +(accSum / accCount).toFixed(3) : 0,
      common_weak_topics: commonWeak,
      students,
    };
  }
}

export default AnalyticsService;
