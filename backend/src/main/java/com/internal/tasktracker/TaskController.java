package com.internal.tasktracker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@CrossOrigin(origins = "http://localhost:5173")
public class TaskController {

    private static final Logger logger = LoggerFactory.getLogger(TaskController.class);

    private final TaskRepository taskRepository;

    public TaskController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @GetMapping("/api/tasks")
    public ResponseEntity<?> searchTasks(
            @RequestParam(required = false, defaultValue = "") String q,
            @RequestParam(required = false) String status,
            @RequestParam(required = false, defaultValue = "1") int page,
            @RequestParam(required = false, defaultValue = "10") int pageSize) {

        // Validate and sanitize pagination bounds
        int safePage = Math.max(1, page);
        int safePageSize = Math.max(1, Math.min(100, pageSize));

        // Normalize query input
        String query = q == null ? "" : q.trim();
        String searchTerm = query.isEmpty() ? "" : "%" + query.toLowerCase() + "%";

        // Parse and validate status filter
        String normalizedStatus = null;
        if (status != null && !status.trim().isEmpty()) {
            try {
                normalizedStatus = TaskStatus.valueOf(status.trim().toUpperCase()).name();
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", "Invalid status value: '" + status + "'. Allowed values: OPEN, IN_PROGRESS, DONE"
                ));
            }
        }

        logger.info("searchTasks: query='{}', status='{}', page={}, pageSize={}",
                query, normalizedStatus, safePage, safePageSize);

        Pageable pageable = PageRequest.of(safePage - 1, safePageSize);
        Page<Task> taskPage = taskRepository.searchTasks(searchTerm, normalizedStatus, pageable);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("items", taskPage.getContent());
        response.put("total", taskPage.getTotalElements());
        response.put("page", safePage);
        response.put("pageSize", safePageSize);

        return ResponseEntity.ok(response);
    }
}
