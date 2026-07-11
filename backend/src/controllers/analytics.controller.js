import AnalyticsService from '../services/analytics.service.js';

/**
 * AnalyticsController — оқушы/сынып аналитикасы (мұғалім-ата-ана панелі).
 */
export class AnalyticsController {
  /** GET /api/analytics/student/:studentId */
  static async student(req, res) {
    const data = await AnalyticsService.student(req.params.studentId);
    if (!data) {
      return res.status(404).json({ ok: false, error: 'no_data' });
    }
    res.json(data);
  }

  /** GET /api/analytics/class/:school */
  static async classFor(req, res) {
    const school = decodeURIComponent(req.params.school);
    const data = await AnalyticsService.classFor(school);
    res.json(data);
  }
}

export default AnalyticsController;
