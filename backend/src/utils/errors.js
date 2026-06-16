import { getReasonPhrase } from 'http-status-codes';

export class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.timestamp = new Date().toISOString();
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      error: this.message,
      code: this.code,
      statusCode: this.statusCode,
      timestamp: this.timestamp,
      ...(process.env.NODE_ENV === 'development' && { stack: this.stack })
    };
  }
}

export class ValidationError extends AppError {
  constructor(message, details = null) {
    super(message, 400, 'VALIDATION_ERROR');
    this.details = details;
  }

  toJSON() {
    return {
      ...super.toJSON(),
      ...(this.details && { details: this.details })
    };
  }
}

export class AuthenticationError extends AppError {
  constructor(message = 'Аутентификация қажет') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

export class AuthorizationError extends AppError {
  constructor(message = 'Рұқсат жоқ') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

export class NotFoundError extends AppError {
  constructor(resource = 'Ресурс') {
    super(`${resource} табылмады`, 404, 'NOT_FOUND');
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Ресурс бұрынса бар') {
    super(message, 409, 'CONFLICT');
  }
}

export class RateLimitError extends AppError {
  constructor(message = 'Сұрау лимиті асылды', retryAfter = null) {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
    this.retryAfter = retryAfter;
  }

  toJSON() {
    return {
      ...super.toJSON(),
      ...(this.retryAfter && { retryAfter: this.retryAfter })
    };
  }
}

export class ServiceUnavailableError extends AppError {
  constructor(service = 'Қызмет') {
    super(`${service} қайта қосыңыз, қайталап көрсеңіз`, 503, 'SERVICE_UNAVAILABLE');
  }
}

export class TimeoutError extends AppError {
  constructor(operation = 'Операция') {
    super(`${operation} уақыты асты (timeout)`, 504, 'GATEWAY_TIMEOUT');
  }
}

export class BadGatewayError extends AppError {
  constructor(message = 'Шлюз қатесі') {
    super(message, 502, 'BAD_GATEWAY');
  }
}

export class DatabaseError extends AppError {
  constructor(message = 'Дерекқор қатесі') {
    super(message, 500, 'DATABASE_ERROR');
  }
}

export class ExternalAPIError extends AppError {
  constructor(service, originalError) {
    const message = `${service} қызмет қатесі: ${originalError?.message || 'Unknown error'}`;
    super(message, 503, 'EXTERNAL_API_ERROR');
    this.originalError = originalError;
    this.service = service;
  }

  toJSON() {
    return {
      ...super.toJSON(),
      service: this.service
    };
  }
}

// Factory function for creating errors
export const createError = (type, message, details = null) => {
  const errorMap = {
    VALIDATION: (msg, det) => new ValidationError(msg, det),
    AUTHENTICATION: (msg) => new AuthenticationError(msg),
    AUTHORIZATION: (msg) => new AuthorizationError(msg),
    NOT_FOUND: (msg) => new NotFoundError(msg),
    CONFLICT: (msg) => new ConflictError(msg),
    RATE_LIMIT: (msg) => new RateLimitError(msg),
    SERVICE_UNAVAILABLE: (msg) => new ServiceUnavailableError(msg),
    TIMEOUT: (msg) => new TimeoutError(msg),
    BAD_GATEWAY: (msg) => new BadGatewayError(msg),
    DATABASE: (msg) => new DatabaseError(msg),
    EXTERNAL_API: (msg, det) => new ExternalAPIError(msg, det)
  };

  const ErrorClass = errorMap[type] || AppError;
  return new ErrorClass(message, details);
};

export default {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  RateLimitError,
  ServiceUnavailableError,
  TimeoutError,
  BadGatewayError,
  DatabaseError,
  ExternalAPIError,
  createError
};
