# QosQanat API — Орналастыру (Deployment) Құжаттамасы

## 🚀 Орналастыру Мүмкіндіктері

### 1. **Docker + Docker Compose** (Ұсынылған - Local)
### 2. **Heroku** (Қарапайым Cloud)
### 3. **AWS EC2** (Ауқымды)
### 4. **Railway.app** (Жылдам)
### 5. **DigitalOcean** (Арзан VPS)

---

## 🐳 **Docker Орналастыру (Local)**

### Қадам 1: Docker орнату
```bash
# macOS (Homebrew)
brew install docker docker-compose

# Linux
sudo apt-get install docker.io docker-compose

# Windows
# Docker Desktop қайта сайттан сүктеңіз
```

### Қадам 2: Орналастыру
```bash
# Сервис негіздерін басы
docker-compose up --build

# Фондық режімде
docker-compose up -d

# Логтарды қараңыз
docker-compose logs -f api
```

### Қадам 3: Тексеру
```bash
# API сайты
curl http://localhost:3000/api/health

# PostgreSQL сайты (pgAdmin)
http://localhost:5050
# Email: admin@qosqanat.local
# Пароль: admin123
```

### Қадым 4: Тоқтату
```bash
docker-compose down
```

---

## 🌐 **Heroku Орналастыру**

### Қадам 1: Heroku CLI орнату
```bash
# macOS
brew tap heroku/brew && brew install heroku

# Linux
curl https://cli-assets.heroku.com/install.sh | sh

# Windows
# https://devcenter.heroku.com/articles/heroku-cli
```

### Қадам 2: Heroku аккаунт құру
```bash
heroku login
# Браузерде логин барлық екрандарда
```

### Қадам 3: Heroku приложениесін құру
```bash
heroku create qosqanat-api
```

### Қадым 4: Environment айнымалыларын орнату
```bash
heroku config:set ANTHROPIC_API_KEY=sk-ant-...
heroku config:set OPENAI_API_KEY=sk-...
heroku config:set AZURE_SPEECH_KEY=...
heroku config:set AZURE_SPEECH_REGION=eastus
heroku config:set NODE_ENV=production
```

### Қадам 5: Орналастыру
```bash
git push heroku main

# Логтарды қараңыз
heroku logs --tail
```

### Қадым 6: Тексеру
```bash
heroku open
# https://qosqanat-api.herokuapp.com/api/health
```

---

## ☁️ **Railway.app Орналастыру (Ең Қарапайым)**

### Қадым 1: Әдістеме
1. https://railway.app қатысыңыз
2. GitHub аккаунтымен кірсеңіз
3. "New Project" басыңыз
4. GitHub репозиториясын таңдаңыз
5. Орналастыру автоматты болады

### Қадым 2: Environment Айнымалыларын орнату
Railway панельде:
```
Settings → Variables
```

Төмендегілерді қосыңыз:
```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=eastus
NODE_ENV=production
```

### Қадым 3: Тексеру
```bash
https://your-project.up.railway.app/api/health
```

---

## 💻 **AWS EC2 Орналастыру**

### Қадам 1: EC2 Instance құру
1. AWS Console → EC2
2. "Launch Instance" басыңыз
3. Ubuntu 20.04 LTS таңдаңыз
4. t2.micro (free tier)
5. Security Group: HTTP(80), HTTPS(443), SSH(22)

### Қадым 2: SSH қосылысы
```bash
ssh -i your-key.pem ubuntu@your-instance-ip
```

### Қадым 3: Орналастыру
```bash
# Node.js орнату
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Репозиториялды клондау
git clone https://github.com/yourusername/qosqanat-api.git
cd qosqanat-api

# Зависимостерді орнату
npm install

# .env файлын құру
cp .env.example .env
# Редакторда толтырыңыз
sudo nano .env

# PM2 арқылы іске қосу (фондық)
sudo npm install -g pm2
pm2 start src/server.js --name "qosqanat-api"
pm2 startup
pm2 save
```

### Қадым 4: Nginx reverse proxy
```bash
sudo apt-get install nginx

# Конфигурацияны құру
sudo nano /etc/nginx/sites-available/default
```

Конфигурация:
```nginx
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo systemctl restart nginx
```

### Қадым 5: SSL (HTTPS)
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

---

## 🔒 Production Қауіпсіздігі

### 1. Environment Айнымалыларын қоры
```bash
# .env файлы ЕШҚАШАН GitHub-ға салынбайтын
# .gitignore-де болуы керек (уже есть)
```

### 2. Rate Limiting көтерілген
```javascript
// src/config/constants.js
export const RATE_LIMITS = {
  CHAT_PER_MINUTE: 30,      // Production: 10-20
  VOICE_PER_MINUTE: 15,     // Production: 5-10
  TUTOR_PER_MINUTE: 20      // Production: 10-15
};
```

### 3. CORS Конфигурация
```bash
# .env
CORS_ORIGIN=https://yourdomain.com
```

### 4. HTTPS Міндетті
```bash
# Heroku, Railway - автоматты HTTPS
# AWS EC2 - Let's Encrypt (әлі)
```

### 5. Database пароліні өзгерту
```bash
# PostgreSQL пароліні өзгерту
ALTER USER qosqanat WITH PASSWORD 'strong_password_123';
```

### 6. API Rate Limiting
```bash
# Proxy-де (Nginx) rate limit орнату
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
```

---

## 📊 Мониторинг және Логгинг

### 1. **Sentry** (Error Tracking)
```bash
npm install @sentry/node
```

```javascript
// src/server.js
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

### 2. **Winston** (Logging)
```bash
npm install winston
```

### 3. **Datadog** (APM)
```bash
npm install dd-trace
```

### 4. **New Relic** (Performance)
```bash
npm install newrelic
```

---

## 🔄 CI/CD Pipeline (GitHub Actions)

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run linter
        run: npm run lint
      
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
          heroku_app_name: "qosqanat-api"
          heroku_email: "email@example.com"
```

---

## 🚨 Health Checks

### Docker
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Heroku
Автоматты болып анықталады `Procfile`-ге

### AWS EC2
CloudWatch Alarms орнатыңыз

---

## 🔍 Troubleshooting

### Орналастыру сәтсіз болды
```bash
# Логтарды қараңыз
docker-compose logs -f api
heroku logs --tail
pm2 logs qosqanat-api
```

### Database қосыла алмайды
```bash
# Қосылысты тексеңіз
psql postgresql://user:pass@host/db
redis-cli ping
```

### API жауап беріп барлығы ептеген
```bash
# Rate limiting бәлгісі
# Аз уақыт күтіңіз, қайта әрекетіңіз
```

---

## 📈 Performance Tuning

### Node.js іске жосуы
```bash
NODE_ENV=production node src/server.js
```

### Database қосылысын синдіру
```javascript
// Connection pooling
const pool = new Pool({
  max: 20,
  idle: 30000,
  connect_timeout: 5000
});
```

### Redis кэш қосу
```bash
REDIS_URL=redis://localhost:6379
```

### CDN (Static файлдар)
```bash
# CloudFront, Cloudflare, Bunny CDN
```

---

## 📞 Қажет болса?

- Heroku Support: https://help.heroku.com
- AWS Support: https://aws.amazon.com/support
- Railway Docs: https://docs.railway.app
- Docker Docs: https://docs.docker.com

**Production-та дайындық!** 🚀
