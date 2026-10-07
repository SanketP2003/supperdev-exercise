-- Oracle PL/SQL package for task search
-- This is a reference artifact — it does not run locally against H2.
-- It mirrors the logic used by the Spring Data repository and is
-- representative of the kind of Oracle PL/SQL found in production.

CREATE OR REPLACE PACKAGE task_search_pkg AS

    TYPE task_record IS RECORD (
        id          NUMBER,
        title       VARCHAR2(255),
        description VARCHAR2(1000),
        status      VARCHAR2(20),
        priority    VARCHAR2(10),
        assignee    VARCHAR2(100),
        created_at  TIMESTAMP
    );

    TYPE task_cursor IS REF CURSOR RETURN task_record;

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    );

END task_search_pkg;
/

CREATE OR REPLACE PACKAGE BODY task_search_pkg AS

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    ) IS
        v_clean_term VARCHAR2(255);
        v_term       VARCHAR2(257);
        v_page       NUMBER;
        v_size       NUMBER;
        v_offset     NUMBER;
    BEGIN
        v_clean_term := TRIM(p_search_term);
        v_term       := '%' || LOWER(v_clean_term) || '%';
        v_page       := GREATEST(NVL(p_page, 1), 1);
        v_size       := LEAST(GREATEST(NVL(p_page_size, 10), 1), 100);
        v_offset     := (v_page - 1) * v_size;

        -- Total count for pagination metadata
        SELECT COUNT(*)
          INTO p_total_count
          FROM tasks
         WHERE archived = 0
           AND (v_clean_term IS NULL OR LOWER(title) LIKE v_term OR LOWER(NVL(description, ' ')) LIKE v_term)
           AND (p_status IS NULL OR status = p_status);

        -- Modern Oracle 12c+ pagination with relevance ranking and deterministic sort
        OPEN p_results FOR
            SELECT id, title, description, status, priority, assignee, created_at
              FROM tasks
             WHERE archived = 0
               AND (v_clean_term IS NULL OR LOWER(title) LIKE v_term OR LOWER(NVL(description, ' ')) LIKE v_term)
               AND (p_status IS NULL OR status = p_status)
             ORDER BY
                   CASE WHEN v_clean_term IS NOT NULL AND LOWER(title) LIKE v_term THEN 0 ELSE 1 END,
                   created_at DESC,
                   id DESC
            OFFSET v_offset ROWS
            FETCH NEXT v_size ROWS ONLY;

    END search_tasks;

END task_search_pkg;
/
