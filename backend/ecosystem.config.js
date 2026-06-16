export default {
  apps: [
    {
      name: 'qosqanat-api',
      script: './src/server.js',
      instances: 'max',
      exec_mode: 'cluster',
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      watch: false,
      ignore_watch: ['node_modules', 'logs', '.git'],
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      listen_timeout: 3000,
      kill_timeout: 5000,
      wait_ready: false,
      shutdown_with_message: true
    }
  ],

  deploy: {
    production: {
      user: 'ubuntu',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'https://github.com/yourusername/qosqanat-api.git',
      path: '/var/www/qosqanat-api',
      'post-deploy': 'npm ci --omit=dev && pm2 startOrRestart ecosystem.config.js --env production',
      'pre-deploy-local': 'echo "Deploying to production server"'
    }
  }
};
