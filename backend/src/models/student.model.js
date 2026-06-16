// Student Model
// For production: implement with PostgreSQL/MongoDB

export class StudentModel {
  constructor(data = {}) {
    this.id = data.id || Math.random().toString(36).substring(7);
    this.name = data.name || 'Оқушы';
    this.grade = data.grade || 8;
    this.school = data.school || '';
    this.email = data.email || '';
    this.preferredAssistant = data.preferredAssistant || 'bektur';
    this.favoriteSubjects = data.favoriteSubjects || [];
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
    this.lastActive = data.lastActive || new Date();
    this.totalQuestions = data.totalQuestions || 0;
  }

  updateLastActive() {
    this.lastActive = new Date();
  }

  incrementQuestionCount() {
    this.totalQuestions += 1;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      grade: this.grade,
      school: this.school,
      email: this.email,
      preferredAssistant: this.preferredAssistant,
      favoriteSubjects: this.favoriteSubjects,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      lastActive: this.lastActive,
      totalQuestions: this.totalQuestions
    };
  }
}

export default StudentModel;
