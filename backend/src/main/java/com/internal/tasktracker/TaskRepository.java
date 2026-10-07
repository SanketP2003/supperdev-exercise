package com.internal.tasktracker;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    // Search tasks by term and optional status filter with database-level pagination
    @Query(value = "SELECT * FROM tasks WHERE archived = FALSE "
                 + "AND (:term = '' OR LOWER(title) LIKE :term OR LOWER(COALESCE(description, '')) LIKE :term) "
                 + "AND (:status IS NULL OR status = :status) "
                 + "ORDER BY "
                 + "CASE WHEN :term != '' AND LOWER(title) LIKE :term THEN 0 ELSE 1 END, "
                 + "created_at DESC, id DESC",
           countQuery = "SELECT count(*) FROM tasks WHERE archived = FALSE "
                      + "AND (:term = '' OR LOWER(title) LIKE :term OR LOWER(COALESCE(description, '')) LIKE :term) "
                      + "AND (:status IS NULL OR status = :status)",
           nativeQuery = true)
    Page<Task> searchTasks(@Param("term") String term, @Param("status") String status, Pageable pageable);
}
