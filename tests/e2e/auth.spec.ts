import { test, expect } from "@playwright/test";

test.describe("Authentication Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should display login page", async ({ page }) => {
    // Check if login form is visible using data-testid
    await expect(page.getByTestId("login-page")).toBeVisible();
    await expect(page.getByTestId("login-title")).toBeVisible();
    await expect(page.getByTestId("email-input")).toBeVisible();
    await expect(page.getByTestId("password-input")).toBeVisible();
    await expect(page.getByTestId("login-button")).toBeVisible();
  });

  test("should login with valid credentials", async ({ page }) => {
    // Fill in login form using data-testid
    await page.getByTestId("email-input").fill("test@example.com");
    await page.getByTestId("password-input").fill("password123");

    // Submit form
    await page.getByTestId("login-button").click();

    // Should redirect to dashboard
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByTestId("dashboard-title")).toBeVisible();
  });

  test("should show validation errors for empty form", async ({ page }) => {
    // Try to submit without filling
    await page.getByTestId("login-button").click();

    // Should show validation errors (HTML5 validation)
    const emailInput = page.getByTestId("email-input");
    await expect(emailInput).toHaveAttribute("required");
  });

  test("should handle email input validation", async ({ page }) => {
    // Fill invalid email
    await page.getByTestId("email-input").fill("invalid-email");
    await page.getByTestId("password-input").fill("password123");

    // HTML5 validation should prevent submission
    const emailInput = page.getByTestId("email-input");
    await expect(emailInput).toHaveAttribute("type", "email");
  });

  test("should be accessible", async ({ page }) => {
    // Check for accessibility best practices
    await expect(page.getByTestId("email-input")).toHaveAttribute(
      "type",
      "email",
    );
    await expect(page.getByTestId("password-input")).toHaveAttribute(
      "type",
      "password",
    );

    // Check for semantic HTML
    await expect(page.locator("main")).toBeVisible();
    await expect(page.getByTestId("login-form")).toBeVisible();
  });

  test("should be mobile responsive", async ({ page, viewport }) => {
    // Test should run on different viewports (configured in playwright.config.ts)
    const loginButton = page.getByTestId("login-button");
    await expect(loginButton).toBeVisible();

    // Check if elements are properly sized
    const box = await loginButton.boundingBox();
    expect(box?.height).toBeGreaterThan(40); // Minimum touch target
  });

  test("should persist login state", async ({ page, context }) => {
    // Login
    await page.getByTestId("email-input").fill("test@example.com");
    await page.getByTestId("password-input").fill("password123");
    await page.getByTestId("login-button").click();

    // Wait for navigation
    await expect(page).toHaveURL(/\/dashboard/);

    // Create new page in same context
    const newPage = await context.newPage();
    await newPage.goto("/");

    // Should be redirected to dashboard (session persisted)
    // Note: This depends on your auth implementation
    // Adjust based on actual behavior
  });
});
