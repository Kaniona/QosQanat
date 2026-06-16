# QosQanat API — Ынамдастыру Нұсқалығы

Барлық материалдарды құлақтамыз! Ынамдастырмақсыз болса, әрәйлі әдістер бар.

## 🤝 Қалай Ынамдастыру керек?

### 1. **GitHub Issues** - Қателеген немесе идея болса
- https://github.com/yourusername/qosqanat-api/issues/new
- Түсіндіріңіз, бәлгілерді сипаттаңыз, мүмкін сценарийлер берсеңіз

### 2. **Pull Requests** - Коды өзгертуге ынамдастыру
- Форк жасаңыз
- Бөлек branch құрыңыз
- Өзгерістерді жасаңыз
- Tests жазыңыз
- Pull Request ашыңыз

### 3. **Documentation** - Құжаттаманы жақсартыңыз
- Typos түзегіңіз
- Мысалдарды қосыңыз
- Құжаттаманы жасаңыз

---

## 🎯 Ынамдастыру Процесі

### Қадым 1: Fork + Clone
```bash
# GitHub-та Fork басыңыз
# Сөйтіңіз орнайтыңыз
git clone https://github.com/YOUR_USERNAME/qosqanat-api.git
cd qosqanat-api
```

### Қадым 2: Develop Branch құру
```bash
# Feature branch құру
git checkout -b feature/your-feature-name

# Мысалы:
git checkout -b feature/websocket-support
git checkout -b fix/voice-chat-latency
git checkout -b docs/add-examples
```

### Қадым 3: Өзгерістерді жасаңыз
```bash
# Файлдарды өзгертіңіз
# Қоляңыз, немесе өндіктерді қосыңыз

# Tests жазыңыз!
npm test

# Linting
npm run lint --if-present
```

### Қадым 4: Commit жасаңыз
```bash
# Өзгерістерді stage-ге қосыңыз
git add .

# Commit: сипаттамалы сообщение
git commit -m "feat: add websocket support for real-time chat"

# Мысалдар:
git commit -m "fix: resolve voice transcription timeout"
git commit -m "docs: update API examples"
git commit -m "refactor: optimize ai.service.js"
git commit -m "test: add unit tests for safety middleware"
```

### Қадым 5: Push + Pull Request
```bash
# Өзінің branchқа push
git push origin feature/your-feature-name

# GitHub-та Pull Request ашыңыз
# Сипаттаңыз:
# - Не жасадыңыз
# - Неге жасадыңыз
# - Test инструкциялары
```

---

## 📝 Commit Message Форматы

Ретінде [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

<body>

<footer>
```

### Types:
- **feat**: Жаңа өндіктер
- **fix**: Қалағы түзету
- **docs**: Құжаттамасын өзгерту
- **style**: Код стилі (шаңдау)
- **refactor**: Кодты қайта құру (функционалдықсыз өзгерту)
- **perf**: Performance өндіктеу
- **test**: Тест қосу немесе түзету
- **chore**: Dependencies, build құрылымы

### Мысалдар:
```bash
git commit -m "feat(voice): add real-time transcription with WebSocket"
git commit -m "fix(ai): handle Anthropic API timeout gracefully"
git commit -m "docs(readme): add deployment guide"
git commit -m "test(chat): increase coverage to 90%"
git commit -m "perf(tts): optimize Azure Speech API calls"
```

---

## 🧪 Code Standards

### Style Guide
- **Spacing**: 2 spaces (не tabs)
- **Naming**: camelCase for variables, PascalCase for classes
- **Comments**: Only for WHY, not WHAT (code should be self-explanatory)

### Before Submitting PR:

```bash
# 1. Lint үшін өлімде
npm run lint --fix

# 2. Тесттерді іске қос
npm test

# 3. Format кодтарды
npm run format

# 4. Type check (если TypeScript)
npm run type-check
```

---

## ✅ Pull Request Checklist

PRыңызды ашпес бұрын өзіңізді тексеріңіз:

- [ ] Branch develop немесе feature branch-тан ветвена
- [ ] Commit message-тер ретінде
- [ ] Код style guide-ты ұстанады
- [ ] Барлық тесттер түз баршы (`npm test`)
- [ ] Линтеу ошибкалары жоқ (`npm run lint`)
- [ ] Құжаттама түзетілген (если қажет)
- [ ] Breaking changes документилеген
- [ ] PR сипаттамасы толық (что, почему, как тестировать)

### PR Template:

```markdown
## Описание
Бұл PR не істеуге немесе жайды түзетуге өндіктейді.

## Байланысты Issues
Closes #123

## Өзгерістер
- [x] Өндіктер қосылды
- [x] Тесттер жазылды
- [x] Құжаттамасы түзетілді

## Test сценарийлері
```bash
# Мысалы:
curl -X POST http://localhost:3000/api/chat -H "Content-Type: application/json" \
  -d '{"message": "Сәлем!", "grade": 8}'
```

## Скриншоттар (если UI)
[Скриншоттарды қосыңыз]

## Қосымша контекст
Ешқандай басқа контекст болса, осында сипаттаңыз.
```

---

## 🐛 Қателік Есімдерінде Қалай Істеу керек?

### Issue ашу
```markdown
## Қателік сипаттамасы
Дауыстық чат 5+ сөйлеген сөздерін күтетін болса өлімде болмайды.

## Қайталау қадамдары
1. `npm run dev` іске қосыңыз
2. Postman-да `POST /api/voice/chat` іске қосыңыз
3. 5+ сөйте аудиопластын жібіңіз
4. Ошибка: "Timeout"

## Күтініліп отырған әрәйлі
Дауыс 5+ сөйтуін өңдеуі керек.

## Күтініліп отырған іс
Ошибка

## Орта
- OS: Ubuntu 22.04
- Node: 18.16.0
- npm: 9.8.1
```

---

## 🔍 Code Review процесі

### Мейнтейнерлер бәрін қарайды:

1. **Functionality** - Коды іс істеді бе?
2. **Tests** - Тесттер жүңді бе?
3. **Documentation** - Құжаттамасы түсіндіргіш пе?
4. **Style** - Код стиль-ге сай ба?
5. **Performance** - Жылдамдығы орта ба?
6. **Security** - Қауіпсіздігі төрт бе?

### Өзгертістерді қондау:

Жалпысын PR сипаттамасындағы сұраулар болса, өзгертістерді жасаңыз және повторно push атыңыз.

```bash
git add .
git commit -m "fix review comments"
git push origin feature/your-feature
```

---

## 🌟 Ынамдастырма Құндылықты

Ынамдастыру өндіктері (бәлгісіз):

- Ондықтар кодын қарайсыз
- Өндіктерді тестейсіз
- Құжаттаманы түзегсіз
- Басқа ынамдастыруларды пікірлегсіз

---

## 📚 Ресурстар

- [Git Workflow](https://git-scm.com/book/en/v2)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)

---

## 🎓 Beginner-ке ұсынысы

Бұл алғашқы өндіктеңіз ме? Қалағысыз болуын өндіктеу арам немесе documentation-ге бастаңыз!

Мысалдар:
- "Add example in README"
- "Fix typo in SETUP.md"
- "Update API_EXAMPLES.md with Python example"

---

## 🚀 Жақсы ынамдастыру нысанасы

```
✅ Жақсы
- Бөлек өндіктесі (бір PR = бір өндіктеу)
- Түсіндіргіш PR сипаттамасы
- Барлық тесттер түз
- Өндіктелген құжаттама
- Мейнтейнерлерге құрметтіл сөйлемі

❌ Жағымсыз
- Бірнеше өндіктесі нәр PR-та
- Сипаттамасыз PR
- Қалмаған тесттер
- Құжаттама жоқ
- Ескі PR-та жауап беріп барлығы
```

---

## 💬 Сұрау болса?

- **GitHub Discussions**: https://github.com/yourrepo/discussions
- **Email**: maksnsip@gmail.com
- **Telegram**: [Your Telegram channel]

---

**Сәтті ынамдастыру!** 🙏✨

*Барлық ынамдастыруларды құлақтамыз және бәрін құлақтағысыз болсақ, біз салмап әлеуетті әрмагарлықтар арқылы нұсқап беремеіз.*
