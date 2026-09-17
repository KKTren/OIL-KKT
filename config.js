/* ============================================================
   Lube Control — настройки сайта.

   Файл лежит РЯДОМ с index.html, в корне репозитория.
   Правьте значения тут и заливайте файл — их увидят все.
   Если файл удалить, сайт продолжит работать на значениях по умолчанию.

   Подобрать значения мышкой можно в самом сайте:
   войти администратором → «Настройки» → покрутить → «Скачать config.js».
   ============================================================ */

window.LC_CONFIG = {

  /* ---------- Общая база ----------
     Пока поля пустые — демо-режим: данные лежат в браузере
     и не видны другим устройствам.
       Project Settings → Data API   → Project URL
       Project Settings → API Keys   → anon / public          */

  supabaseUrl: 'https://sfbtgricmexysrjfomtp.supabase.co',
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmYnRncmljbWV4eXNyamZvbXRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2NTgwNzMsImV4cCI6MjEwNTIzNDA3M30.AgdHMJZ4Yue2mLG0_FofA5JmFBQ4LgbQ0bAjG-IjErQ',
  emailDomain: 'lubecontrol.app',

  /* ---------- Правила ---------- */

  rules: {
    lowThreshold: 35,      // ниже этой доли вместимости остаток «низкий», %
    cancelWindowMin: 10,   // сколько минут продавец может отменить продажу
    bonusPercent: 10,      // бонус продавца от выручки, %
    defaultMax: 10,        // вместимость новой позиции по умолчанию, шт
    routeDays: 7,          // окно «продано» в карточке стеллажа, дней
    photoWidth: 900,       // до какой ширины ужимать фото стеллажа, px
    photoQuality: 72       // качество JPEG для фото, %
  },

  /* ---------- Цвета ---------- */

  colors: {
    amber: '#F2B705',      // фирменный: кнопки, акценты
    green: '#3DDC84',      // норма, приход, маржа
    orange: '#FFA726',     // низкий остаток, продажа
    red: '#FF5A5F',        // пусто, ошибки
    bg: '#0A0F1A',         // фон страницы
    card: '#111A2C',       // фон карточек
    line: '#1E293D'        // границы
  },

  /* ---------- Надписи ---------- */

  texts: {
    brand: 'Lube Control',
    adminTitle: 'Стеллажи на СТО',
    adminSubtitle: 'Мониторинг остатков',
    sellerTitle: 'Рабочее место продавца',
    sellerSubtitle: 'Отметьте продажу — остаток сразу увидит администратор',
    sellBtn: 'Продал 1 шт',
    requestBtn: 'Запросить пополнение',
    deliveryBtn: 'Принять поставку',
    auditBtn: 'Сверка остатков',
    shiftOpen: 'Смена открыта',
    hint: 'Отмечайте продажу сразу после выдачи канистры — так администратор видит реальный ' +
          'остаток и привозит масло вовремя. Ошиблись? Продажу можно отменить в течение нескольких минут.'
  },

  /* ---------- Категории прайса ----------
     Ключ (key) менять нельзя — он лежит в базе. Название и цвет — можно. */

  categories: [
    { key: 'motor',   label: 'Моторное масло',     color: '#F2B705' },
    { key: 'gear',    label: 'Трансмиссионное',    color: '#7C8CF8' },
    { key: 'coolant', label: 'Антифриз',           color: '#3DDC84' },
    { key: 'brake',   label: 'Тормозная жидкость', color: '#FF5A5F' },
    { key: 'washer',  label: 'Омыватель',          color: '#4FC3F7' },
    { key: 'other',   label: 'Прочее',             color: '#8494AC' }
  ],

  /* ---------- Способы оплаты закупок ----------
     Появляются списком в окне «Новая закупка». */

  payments: [
    'Наличные',
    'Перевод на карту',
    'Безнал по счёту',
    'Отсрочка платежа'
  ],

  /* ---------- Аккаунты ----------
     Пароли работают только в демо-режиме. С подключённым Supabase
     пароль проверяет сервер, здесь остаются логин, роль, имя и стеллаж. */

  accounts: [
    { login: 'admin',   password: 'Oil-Admin-2026', role: 'admin',  name: 'Виталий К.', title: 'Владелец сети', rack: null },
    { login: 'seller1', password: 'Rack101-Oil',    role: 'seller', name: 'Алексей П.', title: 'Продавец',      rack: 'СТ-101' },
    { login: 'seller2', password: 'Rack102-Oil',    role: 'seller', name: 'Сергей В.',  title: 'Продавец',      rack: 'СТ-102' },
    { login: 'seller3', password: 'Rack103-Oil',    role: 'seller', name: 'Ирина Л.',   title: 'Продавец',      rack: 'СТ-103' },
    { login: 'seller4', password: 'Rack104-Oil',    role: 'seller', name: 'Дмитрий Н.', title: 'Продавец',      rack: 'СТ-104' }
  ]
};
