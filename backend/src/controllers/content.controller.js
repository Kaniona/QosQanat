import ContentService from '../services/content.service.js';

/**
 * ContentController — оқу мазмұнының нұсқасы мен таксономиясы (жаңартуды
 * тексеру + болашақта серверден контент беру).
 */
export class ContentController {
  /** GET /api/content/manifest — нұсқа + құрылым саны. */
  static manifest(req, res) {
    res.json(ContentService.manifest());
  }

  /** GET /api/content/curriculum — толық таксономия. */
  static curriculum(req, res) {
    res.json(ContentService.curriculum());
  }

  /** GET /api/content/subject/:id — бір пәннің құрылымы. */
  static subject(req, res) {
    const data = ContentService.subject(req.params.id);
    if (!data) {
      return res.status(404).json({ ok: false, error: 'unknown_subject' });
    }
    res.json(data);
  }
}

export default ContentController;
