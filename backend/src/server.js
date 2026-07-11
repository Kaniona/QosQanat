import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

import chatRoutes from './routes/chat.routes.js';
import voiceRoutes from './routes/voice.routes.js';
import tutorRoutes from './routes/tutor.routes.js';
import healthRoutes from './routes/health.routes.js';
import progressRoutes from './routes/progress.routes.js';
import analyticsRoutes from './routes/analytics.routes.js';
import contentRoutes from './routes/content.routes.js';
import { errorHandler } from './middleware/errorHandler.middleware.js';
import { logger } from './utils/logger.js';
import { validateEnvironment, validateConfig } from './config/validation.js';
import { initDatabase, closeDatabase } from './database/connection.js';
import { initCache, closeCache } from './services/cache.service.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

let server = null;

// ===== STARTUP SEQUENCE =====

const startup = async () => {
  try {
    console.log('\n🚀 QosQanat API v2.0.0 Startup Sequence\n');

    // 1. Validate environment
    validateEnvironment();
    if (!validateConfig()) {
      logger.error('❌ Configuration validation failed. Aborting startup.');
      process.exit(1);
    }

    // 2. Initialize database
    console.log('📦 Initializing database...');
    await initDatabase();

    // 3. Initialize cache
    console.log('📦 Initializing cache...');
    await initCache();

    // 4. Configure security middleware
    app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"]
        }
      }
    }));

    // 5. Configure compression
    app.use(compression());

    // 6. Configure CORS.
    // `credentials: true` is incompatible with a wildcard origin, so only
    // enable credentials when explicit origin(s) are configured.
    const corsOrigin = process.env.CORS_ORIGIN;
    const allowedOrigins = corsOrigin
      ? corsOrigin.split(',').map(o => o.trim())
      : '*';
    app.use(cors({
      origin: allowedOrigins,
      credentials: allowedOrigins !== '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      maxAge: 86400
    }));

    // 7. Body parsers with size limits
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ limit: '10mb', extended: true }));

    // 8. Request timing and logging
    app.use((req, res, next) => {
      const startTime = Date.now();
      const originalJson = res.json;

      res.json = function(data) {
        const duration = Date.now() - startTime;
        const statusCode = res.statusCode;

        if (duration > 5000) {
          logger.warn(`⏱️ SLOW REQUEST: ${req.method} ${req.path} ${statusCode} (+${duration}ms)`);
        } else {
          const emoji = statusCode < 400 ? '✅' : statusCode < 500 ? '⚠️' : '❌';
          logger.info(`${emoji} ${req.method} ${req.path} ${statusCode} (+${duration}ms)`);
        }

        return originalJson.call(this, data);
      };

      next();
    });

    // 9. Request validation
    app.use((req, res, next) => {
      // Validate Content-Type for POST/PUT
      if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
        const contentType = req.get('content-type');
        if (contentType && !contentType.includes('application/json') && !contentType.includes('multipart/form-data')) {
          return res.status(415).json({
            error: 'Unsupported Media Type',
            code: 'UNSUPPORTED_MEDIA_TYPE'
          });
        }
      }
      next();
    });

    // 10. API Routes
    app.use('/api/chat', chatRoutes);
    app.use('/api/voice', voiceRoutes);
    app.use('/api/tutor', tutorRoutes);
    app.use('/api/health', healthRoutes);
    app.use('/api/progress', progressRoutes);
    app.use('/api/analytics', analyticsRoutes);
    app.use('/api/content', contentRoutes);

    // 11. Root endpoint
    app.get('/', (req, res) => {
      res.json({
        app: 'QosQanat API',
        version: '2.0.0',
        status: 'running',
        environment: NODE_ENV,
        uptime_seconds: Math.floor(process.uptime()),
        timestamp: new Date().toISOString(),
        docs: 'https://github.com/yourusername/qosqanat-api'
      });
    });

    // 12. 404 handler
    app.use((req, res) => {
      logger.warn(`❓ 404: ${req.method} ${req.path}`);
      res.status(404).json({
        error: 'Endpoint not found',
        code: 'NOT_FOUND',
        path: req.path,
        method: req.method,
        timestamp: new Date().toISOString()
      });
    });

    // 13. Error handler (MUST be last)
    app.use(errorHandler);

    // 14. Start HTTP server
    server = app.listen(PORT, () => {
      logger.info(`\n✅ QosQanat API v2.0.0 Successfully Started`);
      logger.info(`🌐 URL: http://localhost:${PORT}`);
      logger.info(`🔄 PID: ${process.pid}`);
      logger.info(`📍 Environment: ${NODE_ENV}`);
      logger.info(`📊 Health: http://localhost:${PORT}/api/health\n`);
    });

    // 15. Server error handling
    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        logger.error(`❌ Port ${PORT} already in use. Try PORT=3001 npm start`);
        process.exit(1);
      } else {
        logger.error('❌ Server error:', error);
        process.exit(1);
      }
    });

    // 16. Graceful shutdown handlers
    const gracefulShutdown = async (signal) => {
      logger.info(`\n🛑 ${signal} received. Starting graceful shutdown...`);

      // Close new connections
      server.close(() => {
        logger.info('✅ HTTP server closed');
      });

      // Wait for existing connections
      setTimeout(() => {
        logger.warn('⏱️ Forcing shutdown after 30s...');
        process.exit(0);
      }, 30000);

      // Close external connections
      try {
        await closeDatabase();
        await closeCache();
        logger.info('✅ All resources closed');
        process.exit(0);
      } catch (error) {
        logger.error('❌ Error during shutdown:', error);
        process.exit(1);
      }
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // 17. Unhandled error handlers
    process.on('unhandledRejection', (reason) => {
      logger.error('🚨 Unhandled Rejection:', reason instanceof Error ? reason.stack : reason);
    });

    process.on('uncaughtException', (error) => {
      logger.error('🚨 Uncaught Exception:', error.stack || error.message);
      process.exit(1);
    });

  } catch (error) {
    logger.error('❌ Startup failed:', error.message);
    process.exit(1);
  }
};

// Start the application
startup();

export default app;
