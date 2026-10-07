const API_BASE = '/api';

export async function fetchTasks({ query = '', status = '', page = 1, pageSize = 10, signal } = {}) {
  const params = new URLSearchParams();
  if (query) params.set('q', query);
  if (status) params.set('status', status);
  params.set('page', String(page));
  params.set('pageSize', String(pageSize));

  const url = `${API_BASE}/tasks?${params.toString()}`;
  console.log('[api] fetching:', url);

  const response = await fetch(url, { signal });

  if (!response.ok) {
    let errorDetail = `Request failed: ${response.status}`;
    try {
      const errJson = await response.json();
      if (errJson && errJson.error) {
        errorDetail = errJson.error;
      }
    } catch {
      // response body was not JSON, fallback to status code
    }
    throw new Error(errorDetail);
  }

  return response.json();
}
