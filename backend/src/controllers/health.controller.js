import { logger } from '../utils/logger.js';
import { query } from '../database/connection.js';
import { get as cacheGet } from '../services/cache.service.js';
import { getEnvSummary } from '../config/validation.js';

let startTime = Date.now();

export const getHealthStatus = async (req, res) => {
  try {
    const uptime = Date.now() - startTime;
    const memoryUsage = process.memoryUsage();

    // Database health
    let databaseHealth = 'disconnected';
    try {
      await query('SELECT NOW()');
      databaseHealth = 'healthy';
    } catch (error) {
      logger.warn('Database health check failed:', error.message);
      databaseHealth = 'unhealthy';
    }

    // Cache health
    let cacheHealth = 'disconnected';
    try {
      await cacheGet('health-check-ping');
      cacheHealth = 'healthy';
    } catch (error) {
      logger.warn('Cache health check failed:', error.message);
      cacheHealth = 'unhealthy';
    }

    const healthStatus = {
      status: databaseHealth === 'healthy' ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime_ms: uptime,
      uptime_seconds: Math.floor(uptime / 1000),
      uptime_minutes: Math.floor(uptime / 1000 / 60),

      services: {
        api: 'healthy',
        database: databaseHealth,
        cache: cacheHealth,
        ai_claude: 'ready',
        ai_openai: 'ready',
        stt_whisper: 'ready',
        tts_azure: 'ready'
      },

      resources: {
        memory_used_mb: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        memory_total_mb: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        external_memory_mb: Math.round(memoryUsage.external / 1024 / 1024),
        cpu_usage_percent: process.cpuUsage().user / 1000
      },

      environment: getEnvSummary(),

      version: {
        app: '2.0.0',
        api: 'v1',
        node: process.version
      }
    };

    const statusCode = healthStatus.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json(healthStatus);
  } catch (error) {
    logger.error('Health check error:', error);
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

export const getDeepHealth = async (req, res) => {
  try {
    const checks = {
      database: { status: 'pending', latency_ms: 0 },
      cache: { status: 'pending', latency_ms: 0 },
      memory: { status: 'pending', usage_percent: 0 },
      disk: { status: 'pending', available_gb: 0 }
    };

    // Database check
    try {
      const start = Date.now();
      await query('SELECT NOW()');
      checks.database = {
        status: 'healthy',
        latency_ms: Date.now() - start
      };
    } catch (error) {
      checks.database = {
        status: 'unhealthy',
        error: error.message
      };
    }

    // Cache check
    try {
      const start = Date.now();
      await cacheGet('deep-health-check');
      checks.cache = {
        status: 'healthy',
        latency_ms: Date.now() - start
      };
    } catch (error) {
      checks.cache = {
        status: 'unhealthy',
        error: error.message
      };
    }

    // Memory check
    const memory = process.memoryUsage();
    const memoryUsagePercent = (memory.heapUsed / memory.heapTotal) * 100;
    checks.memory = {
      status: memoryUsagePercent < 90 ? 'healthy' : 'warning',
      usage_percent: Math.round(memoryUsagePercent),
      heap_used_mb: Math.round(memory.heapUsed / 1024 / 1024),
      heap_total_mb: Math.round(memory.heapTotal / 1024 / 1024)
    };

    const allHealthy = Object.values(checks).every(check =>
      check.status === 'healthy' || check.status === 'warning'
    );

    res.status(allHealthy ? 200 : 503).json({
      status: allHealthy ? 'healthy' : 'degraded',
      checks,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Deep health check error:', error);
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
};

export const getMetrics = async (req, res) => {
  try {
    const uptime = process.uptime();
    const memory = process.memoryUsage();
    const cpu = process.cpuUsage();

    res.json({
      metrics: {
        uptime: {
          seconds: Math.floor(uptime),
          minutes: Math.floor(uptime / 60),
          hours: Math.floor(uptime / 3600)
        },
        memory: {
          heap_used_mb: Math.round(memory.heapUsed / 1024 / 1024),
          heap_total_mb: Math.round(memory.heapTotal / 1024 / 1024),
          external_mb: Math.round(memory.external / 1024 / 1024),
          heap_usage_percent: Math.round((memory.heapUsed / memory.heapTotal) * 100)
        },
        cpu: {
          user_ms: Math.round(cpu.user / 1000),
          system_ms: Math.round(cpu.system / 1000)
        },
        process: {
          pid: process.pid,
          platform: process.platform,
          arch: process.arch,
          node_version: process.version
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Metrics error:', error);
    res.status(500).json({ error: error.message });
  }
};

export default {
  getHealthStatus,
  getDeepHealth,
  getMetrics
};
