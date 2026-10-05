const http = require('http');
const url = require('url');

const PORT = 8080;

let workouts = [
  { id: 1, title: 'CrossFit WOD Pro', code: 'CRF-101', durationMinutes: 60, caloriesBurned: 750, intensity: 5, hallId: 1, trainerId: 1, categoryIds: [1, 2], capacityTotal: 15, capacityAvailable: 4, deletedAt: null },
  { id: 2, title: 'Хатха-йога Баланс', code: 'YOG-201', durationMinutes: 75, caloriesBurned: 320, intensity: 2, hallId: 2, trainerId: 2, categoryIds: [3], capacityTotal: 20, capacityAvailable: 11, deletedAt: null },
  { id: 3, title: 'Бокс Classic', code: 'BOX-301', durationMinutes: 60, caloriesBurned: 800, intensity: 5, hallId: 3, trainerId: 3, categoryIds: [4], capacityTotal: 12, capacityAvailable: 2, deletedAt: null },
  { id: 4, title: 'Пилатес Mat', code: 'PIL-401', durationMinutes: 55, caloriesBurned: 280, intensity: 2, hallId: 2, trainerId: 2, categoryIds: [3], capacityTotal: 18, capacityAvailable: 7, deletedAt: null },
  { id: 5, title: 'Сайклинг Race', code: 'CYC-501', durationMinutes: 45, caloriesBurned: 650, intensity: 4, hallId: 1, trainerId: 1, categoryIds: [2], capacityTotal: 20, capacityAvailable: 8, deletedAt: null },
  { id: 6, title: 'Body Pump', code: 'PMP-601', durationMinutes: 60, caloriesBurned: 580, intensity: 4, hallId: 2, trainerId: 2, categoryIds: [1], capacityTotal: 25, capacityAvailable: 12, deletedAt: null },
  { id: 7, title: 'Стретчинг Relax', code: 'STR-701', durationMinutes: 50, caloriesBurned: 200, intensity: 1, hallId: 2, trainerId: 2, categoryIds: [3], capacityTotal: 20, capacityAvailable: 15, deletedAt: null },
  { id: 8, title: 'Табата Hard', code: 'TAB-102', durationMinutes: 40, caloriesBurned: 620, intensity: 5, hallId: 1, trainerId: 1, categoryIds: [1], capacityTotal: 15, capacityAvailable: 6, deletedAt: null },
  { id: 9, title: 'Кикбоксинг K-1', code: 'BOX-302', durationMinutes: 60, caloriesBurned: 780, intensity: 5, hallId: 3, trainerId: 3, categoryIds: [4], capacityTotal: 14, capacityAvailable: 3, deletedAt: null },
  { id: 10, title: 'Zumba Dance', code: 'ZUM-901', durationMinutes: 55, caloriesBurned: 490, intensity: 3, hallId: 2, trainerId: 2, categoryIds: [2], capacityTotal: 30, capacityAvailable: 18, deletedAt: null },
  { id: 11, title: 'TRX Strong', code: 'TRX-103', durationMinutes: 55, caloriesBurned: 530, intensity: 4, hallId: 1, trainerId: 1, categoryIds: [1], capacityTotal: 12, capacityAvailable: 5, deletedAt: null },
  { id: 12, title: 'Аштанга Йога', code: 'YOG-202', durationMinutes: 90, caloriesBurned: 400, intensity: 3, hallId: 2, trainerId: 2, categoryIds: [3], capacityTotal: 16, capacityAvailable: 8, deletedAt: null },
  { id: 13, title: 'HIIT Cardio', code: 'HIT-502', durationMinutes: 45, caloriesBurned: 670, intensity: 5, hallId: 1, trainerId: 1, categoryIds: [2], capacityTotal: 20, capacityAvailable: 10, deletedAt: null },
  { id: 14, title: 'Functional Power', code: 'FNC-104', durationMinutes: 60, caloriesBurned: 600, intensity: 4, hallId: 1, trainerId: 1, categoryIds: [1], capacityTotal: 18, capacityAvailable: 7, deletedAt: null },
];

function sendJson(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  if (req.method === 'OPTIONS') {
    res.writeHead(200, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    res.end();
    return;
  }

  const delay = parseInt(query.__delay || 0);

  setTimeout(() => {
    if (query.__fail) {
      return sendJson(res, parseInt(query.__fail), { message: 'Тестовый сбой сервера (параметр __fail)' });
    }

    if (pathname === '/api/__health') {
      return sendJson(res, 200, { status: 'OK', service: 'fitness-club-api' });
    }

    if (pathname === '/api/workouts' && req.method === 'GET') {
      let filtered = workouts.filter(w => query.includeDeleted === 'true' || !w.deletedAt);

      if (query.search) {
        const s = query.search.toLowerCase();
        filtered = filtered.filter(w => w.title.toLowerCase().includes(s) || w.code.toLowerCase().includes(s));
      }
      if (query.trainerId) {
        filtered = filtered.filter(w => w.trainerId == query.trainerId);
      }

      if (query.sort) {
        const [field, dir] = query.sort.split(',');
        const asc = dir === 'asc';
        filtered.sort((a, b) => {
          let res = 0;
          if (field === 'duration') res = a.durationMinutes - b.durationMinutes;
          else if (field === 'calories') res = a.caloriesBurned - b.caloriesBurned;
          else res = a.title.localeCompare(b.title);
          return asc ? res : -res;
        });
      }

      const page = parseInt(query.page || 1);
      const size = parseInt(query.size || 10);
      const total = filtered.length;
      const from = (page - 1) * size;
      const paged = from >= total ? [] : filtered.slice(from, from + size);

      return sendJson(res, 200, { items: paged, page, size, total });
    }

    const matchId = pathname.match(/^\/api\/workouts\/(\d+)$/);
    if (matchId && req.method === 'GET') {
      const id = parseInt(matchId[1]);
      const item = workouts.find(w => w.id === id);
      if (!item) return sendJson(res, 404, { message: 'Тренировка не найдена' });
      return sendJson(res, 200, item);
    }

    if (pathname === '/api/workouts' && req.method === 'POST') {
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', () => {
        try {
          const item = JSON.parse(body);
          if (workouts.some(w => w.code.toLowerCase() === item.code.toLowerCase())) {
            return sendJson(res, 422, {
              message: 'Ошибка валидации',
              errors: { code: 'Программа с таким артикулом уже зарегистрирована на сервере' }
            });
          }
          item.id = Date.now();
          item.deletedAt = null;
          workouts.push(item);
          return sendJson(res, 201, item);
        } catch {
          return sendJson(res, 400, { message: 'Некорректный JSON' });
        }
      });
      return;
    }

    if (matchId && req.method === 'PUT') {
      const id = parseInt(matchId[1]);
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', () => {
        const item = JSON.parse(body);
        const idx = workouts.indexWhere ? workouts.findIndex(w => w.id === id) : workouts.findIndex(w => w.id === id);
        if (idx === -1) return sendJson(res, 404, { message: 'Запись не найдена' });
        workouts[idx] = { ...item, id };
        return sendJson(res, 200, workouts[idx]);
      });
      return;
    }

    if (matchId && req.method === 'DELETE') {
      const id = parseInt(matchId[1]);
      const idx = workouts.findIndex(w => w.id === id);
      if (idx === -1) return sendJson(res, 404, { message: 'Запись не найдена' });

      if (query.hard === 'true') {
        workouts.splice(idx, 1);
      } else {
        workouts[idx].deletedAt = new Date().toISOString();
      }
      return sendJson(res, 200, { success: true });
    }

    const matchRestore = pathname.match(/^\/api\/workouts\/(\d+)\/restore$/);
    if (matchRestore && req.method === 'POST') {
      const id = parseInt(matchRestore[1]);
      const item = workouts.find(w => w.id === id);
      if (!item) return sendJson(res, 404, { message: 'Запись не найдена' });
      item.deletedAt = null;
      return sendJson(res, 200, item);
    }

    if (pathname === '/api/workouts/bulk-delete' && req.method === 'POST') {
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', () => {
        const { ids } = JSON.parse(body);
        let count = 0;
        ids.forEach(id => {
          const item = workouts.find(w => w.id === id && !w.deletedAt);
          if (item) {
            item.deletedAt = new Date().toISOString();
            count++;
          }
        });
        return sendJson(res, 200, { deleted: count });
      });
      return;
    }

    if (pathname === '/api/test-conflict') {
      return sendJson(res, 409, { message: 'Невозможно выполнить операцию: в выбранной группе нет свободных мест.' });
    }

    sendJson(res, 404, { message: 'Маршрут API не найден' });
  }, delay);
});

server.listen(PORT, () => {
  console.log(` Mock API сервер запущен на http://localhost:${PORT}`);
  console.log(` Health check: http://localhost:${PORT}/api/__health`);
});