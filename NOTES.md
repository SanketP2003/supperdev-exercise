# Engineering Notes

### Summary of Changes
- **Backend & DB Pagination (`TaskRepository.java`, `TaskController.java`)**: Replaced full-table in-memory slicing with Spring Data `Pageable` database-level pagination (`LIMIT`/`OFFSET`), eliminating OutOfMemory risks on large datasets.
- **Search Ranking & Query Performance (`TaskRepository.java`, `search_tasks.sql`)**: Skipped unnecessary `LIKE` scans for blank queries, guarded nullable descriptions with `COALESCE`, and added relevance ranking (`CASE WHEN LOWER(title) LIKE :term THEN 0 ELSE 1 END`) to prioritize title matches over descriptions.
- **Frontend Debounce & UX (`useTasks.js`, `TaskTable.jsx`, `App.jsx`)**: Debounced only search keystrokes so pagination and status filters react instantly. Fixed the 250ms "No tasks found" flash on load, formatted status badges, and centralized `PAGE_SIZE`.
- **Oracle PL/SQL Reference (`task_search_package.sql`)**: Updated legacy `ROWNUM` pagination to modern ANSI `OFFSET/FETCH`, added deterministic `id DESC` sorting, and aligned title-priority search logic.
- **Structured Logging (`TaskController.java`)**: Replaced `System.out.println` with SLF4J logger.

### What Was Not Changed & Why
- **Full-Text Search Engine**: Avoided Elasticsearch/Lucene to keep the setup zero-dependency and lightweight for this scope.
- **CSS / UI Redesign**: Maintained existing vanilla CSS and component structure rather than rewriting with external frameworks.
- **Task Mutation APIs**: Preserved focus strictly on high-impact query and UX bugs within the 90-minute timebox.

### Biggest Remaining Risk
Unindexed `LIKE '%term%'` wildcard searches perform full table scans. As records exceed tens of thousands, queries will degrade without database trigram indexes (e.g. `pg_trgm`) or dedicated full-text indexing.

### Tools & AI Used
Used AI to inspect cross-layer edge cases, draft Spring Data `Pageable` native query syntax, and review Oracle PL/SQL pagination. All changes were manually verified and smoke-tested locally.
