// Shared high score table for the browser build, served by nginx's njs module.
// GET /api/scores -> [{name, score}, ...] (top 5, best first)
// POST /api/scores {name, score} -> merged table
// Stored as JSON in /scores (mount a volume there to keep it).
import fs from 'fs';

const FILE = '/scores/scores.json';
const SIZE = 5;

function load() {
    try {
        const t = JSON.parse(fs.readFileSync(FILE, 'utf8'));
        return Array.isArray(t) ? t : [];
    } catch (e) {
        return [];
    }
}

function reply(r, status, body) {
    r.headersOut['Content-Type'] = 'application/json';
    r.headersOut['Cache-Control'] = 'no-store';
    r.return(status, JSON.stringify(body));
}

function submit(r) {
    let body;
    try {
        body = JSON.parse(r.requestText || '');
    } catch (e) {
        return reply(r, 400, { error: 'bad json' });
    }
    const name = String(body.name || '').replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, 31);
    const score = body.score;
    if (!name || !Number.isInteger(score) || score <= 0 || score > 2147483647) {
        return reply(r, 400, { error: 'bad entry' });
    }

    const table = load();
    table.push({ name: name, score: score });
    table.sort((a, b) => b.score - a.score);
    const top = table.slice(0, SIZE);

    fs.writeFileSync(FILE + '.tmp', JSON.stringify(top));
    fs.renameSync(FILE + '.tmp', FILE);
    reply(r, 200, top);
}

function handle(r) {
    if (r.method === 'GET') return reply(r, 200, load());
    if (r.method === 'POST') return submit(r);
    reply(r, 405, { error: 'method not allowed' });
}

export default { handle };
