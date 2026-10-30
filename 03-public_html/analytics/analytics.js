/**
 * Send one page view each time this script loads.
 * Include on your pages: <script src="/analytics.js" defer></script>
 *
 * The PHP receiver must accept application/json. For other website origins,
 * it must also allow CORS preflight (OPTIONS) and POST requests.
 */
(() => {
    'use strict';

    const endpoint = 'https://www.example.com/tracking.php';

    function trackPageView() {
        const data = {
            url: window.location.href,
            path: window.location.pathname,
            title: document.title,
            referrer: document.referrer,
            screen_width: window.screen.width,
            screen_height: window.screen.height,
            viewport_width: window.innerWidth,
            viewport_height: window.innerHeight,
            pixel_ratio: window.devicePixelRatio || 1,
            language: navigator.language,
            ts: Date.now()
        };

        // Keep the request alive if the visitor navigates away shortly afterward.
        // Delivery remains best-effort; browser settings or network errors can block it.
        fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'omit',
            keepalive: true,
            body: JSON.stringify(data)
        })
            .then((response) => {
                if (!response.ok) {
                    throw new Error(`Tracking request failed: HTTP ${response.status}`);
                }
            })
            .catch((error) => {
                console.warn('[Analytics] Could not send page view.', error);
            });
    }

    // Wait for the document title when installed without the defer attribute.
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', trackPageView, { once: true });
    } else {
        trackPageView();
    }
})();
