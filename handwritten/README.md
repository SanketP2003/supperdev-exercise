# Handwritten Notes Guide

According to the exercise instructions, you must write explanations for each bug fixed **by hand on paper**, photograph or scan the pages, and save the image files (e.g. `page1.jpg`, `page2.jpg`, etc.) directly into this `handwritten/` folder.

Below is the exact content to write down on paper in your own handwriting:

---

### Bug 1: In-Memory Pagination / Full Dataset Loading
- **Where**: `backend/src/main/java/com/internal/tasktracker/TaskController.java` & `TaskRepository.java` (Backend & DB layer)
- **How Discovered**: Code inspection of `TaskController` and SQL logs. Noticed `taskRepository.searchTasks()` returned a full `List<Task>` and the controller sliced it in Java memory via `allResults.subList(start, end)`, unlike the Oracle artifact which did database pagination.
- **Root Cause**: Every page request loaded the entire table into JVM memory and instantiated entity objects for every row. On tables with tens of thousands of tasks, this leads to heavy garbage collection pauses, high latency, and eventual OutOfMemoryError.
- **How Fixed & Why**: Changed `TaskRepository` to accept `Pageable` and return `Page<Task>`, utilizing SQL `LIMIT`/`OFFSET` and `countQuery` at the database level. Updated `TaskController` to use `PageRequest.of(safePage - 1, safePageSize)` and return `taskPage.getContent()` and `taskPage.getTotalElements()`. This scales efficiently to arbitrary table sizes without memory bloat.

---

### Bug 2: Search Relevance Ranking & Blank Search Overhead
- **Where**: `TaskRepository.java`, `db/queries/search_tasks.sql` (SQL & Repository layer)
- **How Discovered**: Testing searches such as "API". Older tasks containing "api" only in the description appeared ahead of newer tasks with "API" in their actual title. Also observed query logs running `LOWER(...) LIKE '%%'` on empty searches.
- **Root Cause**: The query sorted strictly by `created_at DESC` with no relevance weighting. Also, blank search inputs were converted to `"%%"`, forcing the database to perform `LOWER()` function calls and wildcard checks across both title and description columns on every row.
- **How Fixed & Why**:
  1. Added relevance ranking in `ORDER BY`:
     `CASE WHEN :term != '' AND LOWER(title) LIKE :term THEN 0 ELSE 1 END, created_at DESC, id DESC`.
     Title matches now cleanly precede description matches, and `id DESC` provides a deterministic tie-breaker.
  2. Added empty search bypass (`:term = '' OR ...`) and `COALESCE(description, '')` to prevent unnecessary string evaluations and protect against NULL description edge cases.

---

### Bug 3: Debounce Lag on Navigation & Initial Render Flash
- **Where**: `frontend/src/hooks/useTasks.js`, `TaskTable.jsx`, `App.jsx` (Frontend layer)
- **How Discovered**: Testing UI interactions. On initial page load, the table briefly flashed "No tasks found" before displaying "Loading tasks...". Clicking pagination buttons ("Next") or changing the status dropdown suffered an unnecessary 250ms lag.
- **Root Cause**:
  1. `loading` was initialized to `false` and `setLoading(true)` was only executed inside `setTimeout`. During the 250ms debounce window on mount, `tasks` was empty and `loading` was false, causing `TaskTable` to incorrectly render the empty state.
  2. `page` and `status` were included in the debounce timer dependencies, even though debouncing is only intended for rapid keystrokes in search input.
- **How Fixed & Why**:
  1. Separated search query debouncing (`debouncedQuery`) from immediate state. Typing in search is debounced by 250ms, while pagination and status changes fetch immediately with zero artificial delay.
  2. Initialized `loading` to `true` and included `query !== debouncedQuery` in the loading condition to completely eliminate the false "No tasks found" flash.
  3. Formatted status labels in `TaskTable.jsx` (e.g. "In Progress" instead of raw "IN_PROGRESS").

---

### Bug 4: Legacy Pagination & Ordering in Oracle Reference Artifact
- **Where**: `db/oracle/task_search_package.sql` (Database PL/SQL layer)
- **How Discovered**: Code review of the reference PL/SQL package against current Oracle database best practices.
- **Root Cause**: Used legacy pre-12c triple-nested `ROWNUM` subquery pagination, had non-deterministic ordering (`ORDER BY created_at DESC` without an ID tie-breaker), and ran `LIKE '%%'` on empty search terms.
- **How Fixed & Why**: Modernized the procedure using Oracle 12c+ `OFFSET ... ROWS FETCH NEXT ... ROWS ONLY`. Added `id DESC` tie-breaking, trimmed/bypassed search when empty, added title-relevance ordering, and bounded `p_page_size` between 1 and 100 for safety.
