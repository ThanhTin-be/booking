function buildRegexQuery(q) {
    if (!q || typeof q !== 'string') return null;
    const trimmed = q.trim();
    if (!trimmed) return null;
    // Escape regex special chars
    const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return new RegExp(escaped, 'i');
}

module.exports = { buildRegexQuery };

