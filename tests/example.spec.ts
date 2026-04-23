import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('http://localhost:9292/login');
  await page.getByTestId('username').fill("Ludvig");
  await page.getByTestId('password').fill("123");

  await page.getByTestId('Log-in-button').click();

  // Expect a title "to contain" a substring.
  await expect(page.getByText('Välkommen!')).toBeVisible();
});


