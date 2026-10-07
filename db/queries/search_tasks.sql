-- H2-compatible task search query
-- Used by the Spring Data repository layer
--
-- Parameters:
--   :term   — search term wrapped in wildcards (e.g. '%api%') or empty string '' for all
--   :status — status filter or NULL for all statuses

SELECT *
FROM tasks
WHERE archived = FALSE
  AND (:term = '' OR LOWER(title) LIKE :term OR LOWER(COALESCE(description, '')) LIKE :term)
  AND (:status IS NULL OR status = :status)
ORDER BY
  CASE WHEN :term != '' AND LOWER(title) LIKE :term THEN 0 ELSE 1 END,
  created_at DESC,
  id DESC;
