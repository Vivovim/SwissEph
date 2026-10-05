'use strict';

(() => {
    const timezone = document.getElementById('timezone');
    if (!timezone || timezone.disabled || timezone.value) return;

    const savedTimezone = timezone.dataset.savedTimezone;
    if (!savedTimezone || !Array.from(timezone.options).some(option => option.value === savedTimezone)) return;

    timezone.value = savedTimezone;
    // Let zones.js load cities through its existing change handler.
    timezone.dispatchEvent(new Event('change', { bubbles: true }));
})();
