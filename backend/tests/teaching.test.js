// Content / Progress-sync / Analytics қызметтерінің тесттері.
// Redis жоқ ортада get/set graceful түрде fallback (process жады) қолданады.
import { jest } from '@jest/globals';

const { default: ContentService } = await import(
  '../src/services/content.service.js'
);
const { default: ProgressService } = await import(
  '../src/services/progress.service.js'
);
const { default: AnalyticsService } = await import(
  '../src/services/analytics.service.js'
);

describe('ContentService', () => {
  test('manifest нұсқа мен құрылым санын береді', () => {
    const m = ContentService.manifest();
    expect(m.version).toBeTruthy();
    expect(m.subject_count).toBe(5);
    expect(m.module_count).toBeGreaterThan(50);
  });

  test('curriculum 5 пән, math 7-сыныпта 6 модуль', () => {
    expect(ContentService.curriculum().subjects).toHaveLength(5);
    expect(ContentService.subject('math').grades[7]).toHaveLength(6);
    expect(ContentService.subject('bogus')).toBeNull();
  });
});

describe('Progress sync + Analytics', () => {
  test('save → load айналымы (fallback)', async () => {
    await ProgressService.save('stu_1', {
      name: 'Әли',
      grade: 7,
      school: '№25 мектеп',
      skills: [
        {
          skill_id: 'math_g7_m1',
          subject: 'math',
          grade: 7,
          module: 1,
          attempts: 5,
          correct: 5,
          ema: 0.95,
          level: 'mastered',
        },
        {
          skill_id: 'kazakh_g7_m1',
          subject: 'kazakh',
          grade: 7,
          module: 1,
          attempts: 3,
          correct: 1,
          ema: 0.35,
          level: 'learning',
        },
      ],
      streak: 3,
    });
    const loaded = await ProgressService.load('stu_1');
    expect(loaded.name).toBe('Әли');
    expect(loaded.skills).toHaveLength(2);
  });

  test('оқушы аналитикасы дәлдік пен таралуды есептейді', async () => {
    const a = await AnalyticsService.student('stu_1');
    expect(a.mastered).toBe(1);
    expect(a.weak_topics.length).toBeGreaterThanOrEqual(1);
    expect(a.subjects.math.accuracy).toBeGreaterThan(0.9);
  });

  test('сынып аналитикасы мектеп тізімін жинайды', async () => {
    const c = await AnalyticsService.classFor('№25 мектеп');
    expect(c.student_count).toBeGreaterThanOrEqual(1);
    expect(Array.isArray(c.common_weak_topics)).toBe(true);
  });

  test('қисық/шектен тыс деректі тазалайды (қате бермейді)', async () => {
    const r = await ProgressService.save('stu_2', {
      student_id: 'stu_2',
      skills: 'not-an-array',
      nodes: null,
      grade: 99,
    });
    expect(Array.isArray(r.skills)).toBe(true);
    expect(r.grade).toBe(11); // 1..11 аралығына қысылды
  });
});
