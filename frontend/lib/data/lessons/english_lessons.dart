import '../../models/lesson.dart';

/// Ағылшын тілі сабақтары: [сынып][модуль] → грамматика теориясы + үлгілер.
/// Түсіндірме қазақша, жаттығу ағылшынша. Бала алдымен жауапты БОЛЖАЙДЫ.
const Map<int, Map<int, Lesson>> englishLessons = {
  // ============================ 5-СЫНЫП ============================
  5: {
    1: Lesson(
      title: 'Present Simple',
      hook: '«She go to school» десең — ағылшын құлағына «ол мектепке '
          'барад» дегендей естіледі. Бір ғана -s әрпі сөйлеміңді сауатты '
          'етеді!',
      intro: 'Present Simple — күнделікті әдетті білдіреді; he/she/it '
          'жағында етістікке -s жалғанады.',
      explainSteps: [
        'Қолданысы: every day, usually, on Sundays — қайталанатын '
            'істер.',
        'I/you/we/they — етістік өзгеріссіз: They play.',
        'He/she/it — етістікке -s/-es: She goes, He plays.',
      ],
      formula: 'I/you/we/they + V · he/she/it + V-s',
      whyFormula: 'Ағылшын тілінде жіктік жалғау жоқтың қасы — сақталып '
          'қалған жалғыз белгі осы -s. Қазақшадағы «барады»-ның «-ды»-сы '
          'сияқты: 3-жақтың таңбасы.',
      examples: [
        WorkedExample(
          problem: 'She ___ to school every day.',
          choices: ['goes', 'go', 'going'],
          steps: [
            ExampleStep('Бастауыш — she (3-жақ жекеше)'),
            ExampleStep('Етістікке -es жалғанады: go → goes'),
          ],
          answer: 'goes',
        ),
        WorkedExample(
          problem: 'They ___ football on Sundays.',
          choices: ['play', 'plays', 'playing'],
          steps: [
            ExampleStep('Бастауыш — they (көпше)'),
            ExampleStep('Көпше жақта -s жалғанбайды: play'),
          ],
          answer: 'play',
        ),
      ],
      commonMistake: 'He / she / it жағында -s ұмытпа: «He play» ❌ → «He plays» ✅.',
      takeaway: 'Present Simple — әдет; 3-жақ жекешеде етістікке -s.',
    ),
    2: Lesson(
      title: 'My Hobbies',
      hook: 'Досыңнан «What is your hobby?» деп сұрасаң, жауап көбіне '
          '-ing-мен келеді: reading, swimming, drawing. Неге екенін '
          'қазір білесің.',
      intro: 'Хобби туралы айтқанда like / enjoy етістігінен кейін V-ing '
          'формасы келеді: I like reading.',
      explainSteps: [
        'like, enjoy, love — ұнатуды білдіретін етістіктер.',
        'Олардан кейін іс-әрекет -ing «киімін» киеді: read → reading.',
        'Сұрақ-жауап үлгісі: What is your hobby? — I enjoy playing '
            'football.',
      ],
      formula: 'I like / enjoy + V-ing (I like reading)',
      whyFormula: '-ing форма етістікті «іс атауына» айналдырады: '
          'reading — «оқу» деген зат есім іспетті. Ұнататының — '
          'іс-әрекеттің өзі, сондықтан -ing.',
      examples: [
        WorkedExample(
          problem: 'I enjoy ___ books.',
          choices: ['reading', 'read', 'reads'],
          steps: [
            ExampleStep('enjoy етістігінен кейін -ing формасы'),
            ExampleStep('read → reading'),
          ],
          answer: 'reading',
        ),
        WorkedExample(
          problem: 'He likes ___ football.',
          choices: ['playing', 'play', 'played'],
          steps: [
            ExampleStep('like-тан кейін -ing формасы'),
            ExampleStep('play → playing'),
          ],
          answer: 'playing',
        ),
      ],
      commonMistake: 'like-тан кейін көбіне -ing: «I like swim» ❌ → '
          '«I like swimming» ✅.',
      takeaway: 'Хобби туралы: like / enjoy + V-ing.',
    ),
  },
  // ============================ 6-СЫНЫП ============================
  6: {
    1: Lesson(
      title: 'Past Simple',
      hook: '«Кеше не істедің?» дегенге ағылшынша бір сөзбен жауап '
          'бересің: watched, played, went. Тек өткен шақтың «киімін» '
          'білсең болғаны.',
      intro: 'Past Simple — өткенде болып, аяқталған іс: дұрыс етістік + '
          '-ed, бұрысы — өз 2-формасы.',
      explainSteps: [
        'Белгі сөздер: yesterday, last year, ago.',
        'Дұрыс етістік: watch → watched (тек -ed жалғанады).',
        'Бұрыс етістік ережеге бағынбайды — жаттау керек: go → went, '
            'see → saw.',
      ],
      formula: 'V-ed (regular) · went / saw / did (irregular)',
      whyFormula: 'Неге «goed» қате? Ең көне әрі ең жиі етістіктер '
          '-ed ережесінен бұрын пайда болған — сондықтан олар ежелгі '
          'формаларын сақтап қалған (went, saw, did).',
      examples: [
        WorkedExample(
          problem: 'Yesterday I ___ a film.',
          choices: ['watched', 'watch', 'watching'],
          steps: [
            ExampleStep('«Yesterday» — өткен шақ белгісі'),
            ExampleStep('watch — дұрыс етістік: watch → watched'),
          ],
          answer: 'watched',
        ),
        WorkedExample(
          problem: 'She ___ to Almaty last year.',
          choices: ['went', 'goed', 'go'],
          steps: [
            ExampleStep('go — бұрыс етістік'),
            ExampleStep('Өткен шағы: go → went'),
          ],
          answer: 'went',
        ),
      ],
      commonMistake: 'Бұрыс етістікке -ed қоспа: «goed» ❌ → «went» ✅.',
      takeaway: 'Past Simple: -ed немесе бұрыс етістіктің 2-формасы.',
    ),
    2: Lesson(
      title: 'Travelling',
      hook: 'Шетелге шықсаң: passport, ticket, luggage — үшеуі үнемі '
          'қасыңда. Ал «автобуспен» дегенді ағылшынша қалай айтасың? '
          'Бір кішкентай by жеткілікті!',
      intro: 'Көлікпен жүру — by (by bus, by plane), жаяу — on foot, '
          'шетелге — abroad.',
      explainSteps: [
        'Саяхат сөздігі: ticket (билет), luggage (жүк), passport '
            '(төлқұжат), abroad (шетелде).',
        'Кез келген көлік алдында by: by bus, by train, by plane.',
        'Жалғыз ерекшелік — жаяу жүру: on foot (by foot ЕМЕС!).',
      ],
      formula: 'travel by bus/plane/train · go abroad · on foot',
      whyFormula: 'by — «арқылы, көмегімен» деген идея: by plane = ұшақ '
          'арқылы. Ал жаяуда құрал жоқ — өз аяғыңның ҮСТІНДЕ жүресің: '
          'on foot.',
      examples: [
        WorkedExample(
          problem: 'We travelled ___ plane.',
          choices: ['by', 'on', 'with'],
          steps: [
            ExampleStep('Көлікпен жүру — by предлогы'),
            ExampleStep('by plane'),
          ],
          answer: 'by',
        ),
        WorkedExample(
          problem: 'He went ___ to study.',
          choices: ['abroad', 'aboard', 'a broad'],
          steps: [
            ExampleStep('«Шетелге» мағынасы — abroad'),
          ],
          answer: 'abroad',
        ),
      ],
      commonMistake: '«by foot» ❌ — дұрысы «on foot».',
      takeaway: 'Көлікпен — by, шетелге — abroad, жаяу — on foot.',
    ),
  },
  // ============================ 7-СЫНЫП ============================
  7: {
    1: Lesson(
      title: 'Future Forms',
      hook: 'Аспанда қап-қара бұлт: «It is going to rain!» Ал жай '
          'ойыңдағы болжам: «I think it will rain». Екі болашақтың '
          'айырмасы — ДӘЛЕЛДЕ.',
      intro: 'will — сол сәттегі шешім мен жай болжам; be going to — '
          'жоспар мен көзге көрінген дәлел.',
      explainSteps: [
        'will: дәл қазір шешім қабылдадың немесе жай болжайсың: '
            'I think she will win.',
        'be going to: алдын ала жоспар немесе дәлелі бар болжам: '
            'Look at the clouds! It is going to rain.',
        'Сынақ сұрағы: дәлел көзге көрініп тұр ма? Иә → going to; '
            'жай ой → will.',
      ],
      formula: 'will + V (decision/prediction) · be going to + V (plan/evidence)',
      whyFormula: 'going to сөзбе-сөз «бара жатыр» — іс басталуға БЕТ '
          'АЛҒАН кезде айтылады: бұлт келе жатыр = жаңбыр «жолда».',
      examples: [
        WorkedExample(
          problem: 'Look at the clouds! It ___ rain.',
          choices: ['is going to', 'will', 'goes'],
          steps: [
            ExampleStep('Бұлт — көзге көрінген дәлел бар'),
            ExampleStep('Дәлелге сүйенген болжам — be going to'),
          ],
          answer: 'is going to',
        ),
        WorkedExample(
          problem: 'I think she ___ win the game.',
          choices: ['will', 'going to', 'goes'],
          steps: [
            ExampleStep('«I think» — жай болжам, дәлел жоқ'),
            ExampleStep('Болжам — will'),
          ],
          answer: 'will',
        ),
      ],
      commonMistake: 'Көзге көрінген дәлел болса (clouds) → going to; жай '
          'болжам / «I think» → will.',
      takeaway: 'will — шешім/болжам, going to — жоспар/дәлел.',
    ),
    2: Lesson(
      title: 'Comparatives',
      hook: 'Піл мысықтан үлкен, ал көк кит — бәрінен үлкен! Ағылшынша '
          'мұны -er мен the -est шешеді: bigger, the biggest.',
      intro: 'Қысқа сын есім + -er/-est; ұзын сын есімге more / the most '
          'қойылады.',
      explainSteps: [
        'Қысқа сөз (1–2 буын): big → bigger → the biggest.',
        'Ұзын сөз (3+ буын): interesting → more interesting → '
            'the most interesting.',
        'Салыстырғанда than: An elephant is bigger THAN a cat.',
      ],
      formula: 'short + -er than · long → more ... than · the -est / the most',
      whyFormula: 'Неге екі тәсіл? Айтуға ыңғайлылық: қысқа сөзге -er '
          'жеңіл жабысады (bigger), ал «interestinger» — тілге ауыр. '
          'Сондықтан ұзын сөздер more-ды алады.',
      examples: [
        WorkedExample(
          problem: 'An elephant is ___ than a cat.',
          choices: ['bigger', 'more big', 'biggest'],
          steps: [
            ExampleStep('big — қысқа сөз'),
            ExampleStep('Қысқа сөзге -er: big → bigger'),
          ],
          answer: 'bigger',
        ),
        WorkedExample(
          problem: 'This is the ___ film I have seen.',
          choices: ['most interesting', 'interestingest', 'more interesting'],
          steps: [
            ExampleStep('interesting — ұзын сөз, үстемелік қажет'),
            ExampleStep('the most + ұзын сөз: the most interesting'),
          ],
          answer: 'most interesting',
        ),
      ],
      commonMistake: '«more bigger» ❌ — -er мен more-ды қатар қолданба.',
      takeaway: 'Қысқа сөз -er, ұзын сөз more; ең — the -est / the most.',
    ),
  },
  // ============================ 8-СЫНЫП ============================
  8: {
    1: Lesson(
      title: 'Present Perfect',
      hook: '«I have already eaten» — қашан жегенің айтылмайды, бірақ '
          'ҚАЗІР тоқ екенің белгілі. Өткен іс + қазіргі нәтиже = '
          'Present Perfect.',
      intro: 'Present Perfect (have/has + V3) — өткенде болып, нәтижесі '
          'ҚАЗІРГЕ қатысты іс.',
      explainSteps: [
        'Құрылымы: I/you/we/they + have, he/she/it + has, сосын V3.',
        'Серік сөздер: just, already, yet, ever, never.',
        'Нақты уақыт аталса (yesterday) — Past Simple-ге ауыс: '
            'I saw him yesterday.',
      ],
      formula: 'have / has + V3 (past participle)',
      whyFormula: 'have = «менде бар»: I have eaten — «менде жеп қойған '
          'күй бар». Тәжірибе қазір «қолыңда» болғандықтан, құрылым осы '
          'шақтағы have-пен басталады.',
      examples: [
        WorkedExample(
          problem: 'I ___ already eaten.',
          choices: ['have', 'has', 'had'],
          steps: [
            ExampleStep('Бастауыш — I'),
            ExampleStep('I жағында — have + V3'),
          ],
          answer: 'have',
        ),
        WorkedExample(
          problem: 'She ___ never been to London.',
          choices: ['has', 'have', 'was'],
          steps: [
            ExampleStep('Бастауыш — she (3-жақ жекеше)'),
            ExampleStep('she жағында — has + V3'),
          ],
          answer: 'has',
        ),
      ],
      commonMistake: 'Нақты өткен уақыт (yesterday) болса — Past Simple: '
          '«I have seen him yesterday» ❌.',
      takeaway: 'have / has + V3 — өткеннің қазірмен байланысы.',
    ),
    2: Lesson(
      title: 'Modal Verbs',
      hook: 'can, must, should — үш кішкентай сөз үш түрлі күш береді: '
          '«істей аламын», «істеуім МІНДЕТ», «істеген жөн». Таңдауың '
          'сөйлем реңкін өзгертеді.',
      intro: 'Модаль етістіктер (can, must, should, may) мағына реңкін '
          'қосады; олардан кейін to-сыз етістік келеді.',
      explainSteps: [
        'can — қабілет пен мүмкіндік: Birds can fly.',
        'must — қатаң міндет; should — жұмсақ кеңес: You should see '
            'a doctor.',
        'Модальден кейін жалаң етістік: must go (must TO go емес), '
            '3-жақта -s та жоқ: he can swim.',
      ],
      formula: 'modal + V (to-сыз): can swim, must go, should rest',
      whyFormula: 'Модальдер — көмекші сөздер: өздері іс-әрекет емес, '
          'іске КӨЗҚАРАС білдіреді. Сондықтан to да, -s те алмай, '
          'етістіктің алдында тұрады.',
      examples: [
        WorkedExample(
          problem: 'You look ill. You ___ see a doctor.',
          choices: ['should', 'must not', 'can'],
          steps: [
            ExampleStep('Бұл — кеңес мағынасы'),
            ExampleStep('Кеңес — should'),
          ],
          answer: 'should',
        ),
        WorkedExample(
          problem: 'Birds ___ fly.',
          choices: ['can', 'must', 'should'],
          steps: [
            ExampleStep('Бұл — мүмкіндік (қабілет)'),
            ExampleStep('Қабілет — can'),
          ],
          answer: 'can',
        ),
      ],
      commonMistake: 'Модальден кейін «to» қойма: «must to go» ❌ → «must go» ✅.',
      takeaway: 'Модаль + негізгі етістік (to-сыз): мүмкіндік/міндет/кеңес.',
    ),
  },
  // ============================ 9-СЫНЫП ============================
  9: {
    1: Lesson(
      title: 'Passive Voice',
      hook: '«Ағылшын тілінде бүкіл әлем сөйлейді» дегенде КІМ сөйлейтіні '
          'емес, ТІЛДІҢ өзі маңызды. Ағылшын мұндайда сөйлемді төңкереді: '
          'English is spoken…',
      intro: 'Passive (be + V3) — әрекетті кім істегені емес, НЕ '
          'істелгені маңызды болғанда қолданылады.',
      explainSteps: [
        'Объект бастауыш орнына шығады: English is spoken all over '
            'the world.',
        'Шақты be көрсетеді: is spoken (қазір), was built (өткен шақ).',
        'Орындаушыны айтқың келсе — by: was built by my grandfather.',
      ],
      formula: 'be (am/is/are/was/were) + V3 (+ by ...)',
      whyFormula: 'V3 (spoken, built) — «істелген» деген сын есім тәрізді '
          'форма, ал be оны шаққа байлайды. be түссе, сөйлем шақсыз '
          'қалады: «English spoken» ❌.',
      examples: [
        WorkedExample(
          problem: 'English ___ all over the world.',
          choices: ['is spoken', 'speaks', 'spoke'],
          steps: [
            ExampleStep('Тіл — әрекеттің объектісі (passive)'),
            ExampleStep('is + V3: is spoken'),
          ],
          answer: 'is spoken',
        ),
        WorkedExample(
          problem: 'The house ___ in 1990.',
          choices: ['was built', 'built', 'build'],
          steps: [
            ExampleStep('Өткен шақ + passive'),
            ExampleStep('was + V3: was built'),
          ],
          answer: 'was built',
        ),
      ],
      commonMistake: 'be етістігін ұмытпа: «English spoken» ❌ → «is spoken» ✅.',
      takeaway: 'Passive = be + V3; орындаушы by-мен беріледі.',
    ),
    2: Lesson(
      title: 'Conditionals',
      hook: '«Жаңбыр жауса, үйде қаламын» — нақты жоспар. «Бай болсам, '
          'әлемді аралар едім» — қиял. Ағылшын бұл екеуін ЕКІ бөлек '
          'құрылыммен айтады.',
      intro: '1st Conditional — нақты болашақ (If + Present, will); '
          '2nd — қиял (If + Past, would).',
      explainSteps: [
        '1st: If it rains, I will stay home — болуы әбден мүмкін '
            'жағдай.',
        '2nd: If I were rich, I would travel — қазір олай емес, тек '
            'қиял.',
        'Басты ереже: if-тен кейін will/would ҚОЙЫЛМАЙДЫ: If it rains '
            '(if it will rain емес).',
      ],
      formula: '1st: If + Present, will + V · 2nd: If + Past, would + V',
      whyFormula: '2nd-те неге Past? Өткен шақ формасы «шындықтан '
          'алыстауды» білдіреді — уақыт емес, ЫҚТИМАЛДЫҚ алыстайды: '
          'I were rich = «шынында бай емеспін ғой».',
      examples: [
        WorkedExample(
          problem: 'If it rains, I ___ stay home.',
          choices: ['will', 'would', 'am'],
          steps: [
            ExampleStep('If + Present (rains) — нақты шарт (1st)'),
            ExampleStep('Бас бөлік: will + V'),
          ],
          answer: 'will',
        ),
        WorkedExample(
          problem: 'If I were rich, I ___ travel a lot.',
          choices: ['would', 'will', 'am'],
          steps: [
            ExampleStep('If + Past (were) — қиял (2nd)'),
            ExampleStep('Бас бөлік: would + V'),
          ],
          answer: 'would',
        ),
      ],
      commonMistake: 'If-тен кейін will қойма: «If it will rain» ❌ → '
          '«If it rains» ✅.',
      takeaway: '1st — нақты (will), 2nd — қиял (would, were).',
    ),
  },
  // ============================ 10-СЫНЫП ============================
  10: {
    1: Lesson(
      title: 'Reported Speech',
      hook: 'Досың кеше: «I am happy» деді. Бүгін соны жеткізесің: '
          '«He said he WAS happy». Неге am → was? Себебі оның '
          '«қазіргісі» енді өткенде қалды!',
      intro: 'Төл сөзді жеткізгенде шақ бір саты артқа жылжиды: '
          'am → was, will → would.',
      explainSteps: [
        'Present → Past: «I am happy» → She said she was happy.',
        'will → would: «I will call» → He said he would call.',
        'Құрылымы: say / tell + (that) + жылжыған шақ.',
      ],
      formula: 'say / tell + that + (шақ артқа): am→was, will→would',
      whyFormula: 'Сөз айтылған сәт өткенде қалды — сол сәттің '
          '«қазіргісі» де онымен бірге өткенге жылжиды. Back-shift — '
          'жай ереже емес, уақыт логикасы.',
      examples: [
        WorkedExample(
          problem: 'Direct: «I am happy.» → She said she ___ happy.',
          choices: ['was', 'is', 'will be'],
          steps: [
            ExampleStep('am — бір саты артқа жылжиды'),
            ExampleStep('am → was'),
          ],
          answer: 'was',
        ),
        WorkedExample(
          problem: 'Direct: «I will call.» → He said he ___ call.',
          choices: ['would', 'will', 'was'],
          steps: [
            ExampleStep('will — бір саты артқа жылжиды'),
            ExampleStep('will → would'),
          ],
          answer: 'would',
        ),
      ],
      commonMistake: 'Шақты артқа жылжытуды ұмытпа: «She said she is happy» '
          'көбіне ❌.',
      takeaway: 'Reported speech — шақ бір саты артқа (back-shift).',
    ),
    2: Lesson(
      title: 'Phrasal Verbs',
      hook: 'give = беру, up = жоғары. Ал give up = … бас тарту?! '
          'Ағылшын тілінің «құпия коды» — phrasal verbs: екі сөз '
          'қосылып, мүлдем жаңа мағына туады.',
      intro: 'Phrasal verb = етістік + бөлшек: мағынасы тұтасымен '
          'жаңарады (give up — бас тарту).',
      explainSteps: [
        'Жиі кездесетіндері: turn on (қосу), look after (бағу), '
            'give up (бас тарту).',
        'Сөзбе-сөз аударма ЖҮРМЕЙДІ: look after — «артынан қарау» '
            'емес, «қамқорлық жасау».',
        'Тіркес күйінде, сөйлем ішінде жатта: She looks after her '
            'brother.',
      ],
      formula: 'verb + particle = жаңа мағына (give up = бас тарту)',
      whyFormula: 'Бөлшек — етістіктің бағытын бұратын «руль»: up көбіне '
          '«аяқтау/тоқтату» реңкін береді (give up, eat up). Реңктерді '
          'байқасаң, жаңа тіркестерді өзің болжай аласың.',
      examples: [
        WorkedExample(
          problem: 'It is dark. Please turn ___ the light.',
          choices: ['on', 'up', 'after'],
          steps: [
            ExampleStep('«Қосу» мағынасы — turn on'),
          ],
          answer: 'on',
        ),
        WorkedExample(
          problem: 'She looks ___ her little brother.',
          choices: ['after', 'for', 'up'],
          steps: [
            ExampleStep('«Қарау, бағу» мағынасы — look after'),
          ],
          answer: 'after',
        ),
      ],
      commonMistake: 'Phrasal verb мағынасын сөзбе-сөз аударма: «give up» — '
          '«жоғары беру» емес, «бас тарту».',
      takeaway: 'Phrasal verb — етістік + бөлшек, тұтас жаңа мағына.',
    ),
  },
  // ============================ 11-СЫНЫП ============================
  11: {
    1: Lesson(
      title: 'Advanced Grammar',
      hook: '«Never have I seen such a view!» — сөз тәртібі «қате» ме? '
          'Жоқ — бұл inversion: сөйлемді әдейі төңкеріп, сөзге күш беру '
          'тәсілі. Жоғары деңгейдің белгісі!',
      intro: 'wish + Past — өкінішті білдіреді; inversion '
          '(Never have I…) — сөйлемді әсерлі етеді.',
      explainSteps: [
        'I wish I knew — «білсем ғой» (қазір білмеймін, өкінемін).',
        'Inversion: Never/Rarely сөйлем басына шықса, көмекші етістік '
            'бастауыштан БҰРЫН келеді: Never have I seen…',
        'Екеуі де — эмоцияны күшейту құралы: эссе мен сөйлеуге дең '
            'береді.',
      ],
      formula: 'I wish + Past (өкіну): I wish I knew · inversion: Never have I',
      whyFormula: 'wish-тен кейінгі Past — 2nd Conditional-дағыдай '
          '«шындықтан алыстау» белгісі: уақыт емес, арман мен шындық '
          'арасы алыс.',
      examples: [
        WorkedExample(
          problem: 'I do not know the answer. I wish I ___ it.',
          choices: ['knew', 'know', 'will know'],
          steps: [
            ExampleStep('wish-тен кейін Past — өкінішті білдіреді'),
            ExampleStep('know → knew'),
          ],
          answer: 'knew',
        ),
        WorkedExample(
          problem: 'Never ___ I seen such a beautiful view.',
          choices: ['have', 'did', 'was'],
          steps: [
            ExampleStep('Inversion: Never + have/has + бастауыш + V3'),
            ExampleStep('Демек — have'),
          ],
          answer: 'have',
        ),
      ],
      commonMistake: '«I wish I know» ❌ — wish-тен кейін Past: «I wish I knew».',
      takeaway: 'wish + Past — өкіну; inversion — әсерлі бастау.',
    ),
    2: Lesson(
      title: 'Academic English',
      hook: 'Эссеңді «Yeah, so I guess…» деп бастасаң, бағаң түсіп кетуі '
          'мүмкін. Ал «It can be concluded that…» десең — мүлдем басқа '
          'деңгей!',
      intro: 'Академиялық ағылшын — ресми, дәл, тұлғасыз стиль: сленгсіз, '
          'қысқартусыз, дәйекті.',
      explainSteps: [
        'Қысқарған форма жоқ: don’t емес — do not.',
        'Тұлғасыздық: «I think» орнына «It can be concluded that…».',
        'Байланыстырғыштар: Furthermore, However, Therefore — ой '
            'желісін көрсетеді.',
      ],
      formula: 'Academic = ресми + тұлғасыз + дәйекті (no contractions, no slang)',
      whyFormula: 'Ғылым — жеке пікір емес, дәйек әлемі: тұлғасыз '
          'құрылым («it is known») назарды автордан ФАКТІГЕ аударады.',
      examples: [
        WorkedExample(
          problem: 'Қай тіркес академиялық стильге сай?',
          choices: ['It can be concluded that', 'Yeah, so', 'I guess that'],
          steps: [
            ExampleStep('Академиялық — тұлғасыз, ресми тіркес'),
            ExampleStep('Демек — «It can be concluded that»'),
          ],
          answer: 'It can be concluded that',
        ),
        WorkedExample(
          problem: 'Қай байланыстырғыш академиялық жазуға сай?',
          choices: ['Furthermore', 'Plus', 'Anyway'],
          steps: [
            ExampleStep('Plus, Anyway — ауызекі стиль'),
            ExampleStep('Ресми байланыстырғыш — Furthermore'),
          ],
          answer: 'Furthermore',
        ),
      ],
      commonMistake: 'Академиялық жазуда қысқарған форма (do not → толық) мен '
          'сленг қолданба.',
      takeaway: 'Академиялық тіл — ресми, дәл, дәйекке негізделген.',
    ),
  },
};
