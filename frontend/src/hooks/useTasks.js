import { useState, useEffect } from 'react';
import { fetchTasks } from '../api';

export function useTasks(query, status, page, pageSize) {
  const [debouncedQuery, setDebouncedQuery] = useState(query);
  const [tasks, setTasks] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Debounce search query so rapid typing does not flood the backend
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(query);
    }, 250);

    return () => clearTimeout(timer);
  }, [query]);

  // Fetch tasks immediately whenever debounced query, status, or pagination changes
  useEffect(() => {
    let ignore = false;
    const controller = new AbortController();

    setLoading(true);
    setError(null);

    fetchTasks({ query: debouncedQuery, status, page, pageSize, signal: controller.signal })
      .then((data) => {
        if (!ignore) {
          setTasks(data.items || []);
          setTotal(data.total || 0);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (!ignore && err.name !== 'AbortError') {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
      controller.abort();
    };
  }, [debouncedQuery, status, page, pageSize]);

  return {
    tasks,
    total,
    loading: loading || query !== debouncedQuery,
    error,
  };
}
