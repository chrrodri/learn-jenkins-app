// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Learn Jenkins App', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should have the correct title', async ({ page }) => {
    await expect(page).toHaveTitle(/Learn Jenkins/i);
  });

  test('should display the Udemy link', async ({ page }) => {
    const udemyLink = page.getByRole('link', {
      name: /Learn Jenkins on Udemy/i
    });

    await expect(udemyLink).toBeVisible();
  });

  test('should display the application version', async ({ page }) => {
    const expectedAppVersion = process.env.REACT_APP_VERSION || '1';

    console.log(`Expected version: ${expectedAppVersion}`);

    const versionLabel = page.getByText(
      `Application version: ${expectedAppVersion}`
    );

    await expect(versionLabel).toBeVisible();
  });

});