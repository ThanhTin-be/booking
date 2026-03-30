function parsePagination(query = {}) {
    const page = Math.max(parseInt(query.page || '1', 10) || 1, 1);
    const limitRaw = parseInt(query.limit || '20', 10) || 20;
    const limit = Math.min(Math.max(limitRaw, 1), 200);
    const skip = (page - 1) * limit;
    return { page, limit, skip };
}

function parseSort(sortQuery, defaultSort = { createdAt: -1 }) {
    // sort=createdAt:desc,name:asc
    if (!sortQuery || typeof sortQuery !== 'string') return defaultSort;
    const sort = {};
    for (const part of sortQuery.split(',')) {
        const [fieldRaw, dirRaw] = part.split(':').map(s => (s || '').trim());
        const field = fieldRaw;
        const dir = (dirRaw || 'desc').toLowerCase();
        if (!field) continue;
        sort[field] = dir === 'asc' ? 1 : -1;
    }
    return Object.keys(sort).length ? sort : defaultSort;
}

module.exports = { parsePagination, parseSort };

