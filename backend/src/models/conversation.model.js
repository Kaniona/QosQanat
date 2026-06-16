// Conversation Model
// For production: implement with PostgreSQL/MongoDB

export class ConversationModel {
  constructor(data = {}) {
    this.id = data.id || Math.random().toString(36).substring(7);
    this.studentId = data.studentId;
    this.messages = data.messages || [];
    this.grade = data.grade;
    this.subject = data.subject;
    this.topic = data.topic;
    this.assistantType = data.assistantType || 'bektur';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  addMessage(role, content) {
    this.messages.push({
      role,
      content,
      timestamp: new Date()
    });
    this.updatedAt = new Date();
  }

  getLastNMessages(n = 10) {
    return this.messages.slice(-n);
  }

  toJSON() {
    return {
      id: this.id,
      studentId: this.studentId,
      messages: this.messages,
      grade: this.grade,
      subject: this.subject,
      topic: this.topic,
      assistantType: this.assistantType,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      messageCount: this.messages.length
    };
  }
}

export default ConversationModel;
