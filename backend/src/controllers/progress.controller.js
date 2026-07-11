import ProgressService from '../services/progress.service.js';
import { logger } from '../utils/logger.js';

/**
 * ProgressController — оқушы прогресін бұлтпен синхрондау (қосымша БОНУС
 * мүмкіндігі; негізгі дерек құрылғыда қалады).
 */
export class ProgressController {
  /** POST /api/progress/sync — құрылғыдан прогресті жүктеу. */
  static async sync(req, res) {
    const { student_id } = req.body;
    const record = await ProgressService.save(student_id, req.body);
    res.json({
      ok: true,
      student_id,
      updated_at: record.updated_at,
      synced: { skills: record.skills.length, nodes: record.nodes.length },
    });
  }

  /** GET /api/progress/:studentId — бұлттан прогресті қайтару. */
  static async get(req, res) {
    const record = await ProgressService.load(req.params.studentId);
    if (!record) {
      return res.status(404).json({ ok: false, error: 'progress_not_found' });
    }
    res.json(record);
  }

  /** DELETE /api/progress/:studentId — дерегін өшіру (құпиялық). */
  static async erase(req, res) {
    await ProgressService.erase(req.params.studentId);
    logger.info(`Progress erased: ${req.params.studentId}`);
    res.json({ ok: true });
  }
}

export default ProgressController;
