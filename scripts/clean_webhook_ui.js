// ==============================================================================
// Webhook.site Clean Presentation Script (Faculty Demo Mode)
// Removes all commercial, pricing, login, signup, and promotional elements
// ==============================================================================

(function cleanWebhookSiteUI() {
    console.log("[*] Activating Clean Faculty Demo Mode on Webhook.site...");

    const clean = () => {
        // 1. Remove Top Navbar commercial items: Pricing, Login, Sign Up
        document.querySelectorAll('a, button, li, span').forEach(el => {
            const text = (el.innerText || el.textContent || '').trim().toLowerCase();
            if (
                text.includes('features & pricing') ||
                text.includes('pricing') ||
                text === 'login' ||
                text === 'sign up now' ||
                text.includes('sign up now') ||
                text.includes('$7.5') ||
                text.includes('read more about benefits')
            ) {
                const target = el.closest('li') || el.closest('button') || el;
                target.style.setProperty('display', 'none', 'important');
            }
        });

        // 2. Remove Upgrade / Marketing cards in the right column
        document.querySelectorAll('h2, h3, h4, p, div').forEach(el => {
            const text = (el.innerText || el.textContent || '').trim().toLowerCase();
            if (text.startsWith('benefits of upgrading')) {
                // Hide the marketing block containing benefits & pricing cards
                const container = el.closest('div');
                if (container) {
                    container.style.setProperty('display', 'none', 'important');
                }
            }
        });

        // 3. Remove any remaining promo buttons
        document.querySelectorAll('button, a.btn').forEach(btn => {
            const text = (btn.innerText || btn.textContent || '').trim().toLowerCase();
            if (text.includes('sign up') || text.includes('pricing') || text.includes('$7.5')) {
                btn.style.setProperty('display', 'none', 'important');
            }
        });
    };

    // Run immediately
    clean();

    // Re-apply if Webhook.site re-renders elements dynamically
    const observer = new MutationObserver(clean);
    observer.observe(document.body, { childList: true, subtree: true });

    console.log("[+] Clean mode active: All pricing, login, and signup elements removed!");
})();
