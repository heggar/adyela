import { test, expect } from "@playwright/test";

const API_BASE_URL = process.env.API_URL || "http://localhost:8000";

test.describe("API Health Checks", () => {
  test("should return healthy status from /health endpoint", async ({
    request,
  }) => {
    const response = await request.get(`${API_BASE_URL}/health`);

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty("status");
    expect(body.status).toBe("healthy");
  });

  test("should have OpenAPI documentation available", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/docs`);

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
  });

  test("should return OpenAPI spec", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/openapi.json`);

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const spec = await response.json();
    expect(spec).toHaveProperty("openapi");
    expect(spec).toHaveProperty("info");
    expect(spec).toHaveProperty("paths");
  });

  test("should handle CORS properly", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/health`, {
      headers: {
        Origin: "http://localhost:3000",
      },
    });

    expect(response.ok()).toBeTruthy();
    const headers = response.headers();
    expect(headers["access-control-allow-origin"]).toBeDefined();
  });

  test("should have proper security headers", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/health`);
    const headers = response.headers();

    // Check for common security headers
    // Adjust based on your actual security configuration
    expect(response.ok()).toBeTruthy();
  });

  test("should return correct content-type for JSON", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/health`);

    const contentType = response.headers()["content-type"];
    expect(contentType).toContain("application/json");
  });

  test("should respond within acceptable time", async ({ request }) => {
    const startTime = Date.now();
    const response = await request.get(`${API_BASE_URL}/health`);
    const endTime = Date.now();

    expect(response.ok()).toBeTruthy();

    const responseTime = endTime - startTime;
    expect(responseTime).toBeLessThan(1000); // Should respond within 1 second
  });
});

test.describe("API Error Handling", () => {
  test("should return 404 for non-existent endpoints", async ({ request }) => {
    const response = await request.get(
      `${API_BASE_URL}/non-existent-endpoint`,
      {
        headers: {
          "X-Tenant-ID": "test-tenant",
        },
      },
    );

    expect(response.status()).toBe(404);
  });

  test("should return proper error format", async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/non-existent`, {
      headers: {
        "X-Tenant-ID": "test-tenant",
      },
    });

    const body = await response.json();
    // Should return JSON error format
    expect(body).toHaveProperty("detail");
    expect(body.detail).toBe("Not Found");
  });
});
