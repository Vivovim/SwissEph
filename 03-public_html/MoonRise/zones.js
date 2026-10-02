'use strict';

(() => {
    const timezone = document.getElementById('timezone');
    const city = document.getElementById('city');
    const status = document.getElementById('city-status');
    const submit = document.getElementById('show-city');
    const form = document.getElementById('zone-form');
    let pendingRequest = null;

    function clearDetails() {
        document.getElementById('city-details')?.remove();
        document.getElementById('form-error')?.remove();
    }

    timezone.addEventListener('change', async () => {
        pendingRequest?.abort();
        pendingRequest = null;
        clearDetails();
        city.replaceChildren(new Option('Select a timezone first', ''));
        city.disabled = true;
        submit.disabled = true;
        status.textContent = '';
        city.removeAttribute('aria-busy');
        if (!timezone.value) return;

        const request = new AbortController();
        pendingRequest = request;
        city.replaceChildren(new Option('Loading cities…', ''));
        city.setAttribute('aria-busy', 'true');
        status.textContent = 'Loading cities…';

        const url = new URL('cities.php', window.location.href);
        url.searchParams.set('tz', timezone.value);

        try {
            const response = await fetch(url, {
                signal: request.signal,
                headers: { Accept: 'application/json' },
                cache: 'no-store',
            });
            if (!response.ok) throw new Error('City request failed.');
            const data = await response.json();
            if (!Array.isArray(data.cities)) throw new Error('Invalid city response.');
            // A slow response must never replace cities for a newer selection.
            if (pendingRequest !== request) return;

            const options = data.cities.map(row => new Option(row.city, String(row.id)));
            city.replaceChildren(new Option(options.length ? 'Select a city' : 'No cities available', ''), ...options);
            city.disabled = options.length === 0;
            status.textContent = options.length
                ? `${options.length} cities loaded. Select a city.`
                : 'No cities found for this timezone.';
        } catch (error) {
            if (request.signal.aborted || pendingRequest !== request) return;
            city.replaceChildren(new Option('Unable to load cities', ''));
            status.textContent = 'Unable to load cities. Select the timezone again or reload the page to retry.';
        } finally {
            if (pendingRequest === request) {
                city.removeAttribute('aria-busy');
                pendingRequest = null;
            }
        }
    });

    city.addEventListener('change', () => {
        clearDetails();
        submit.disabled = city.disabled || !city.value;
        if (!submit.disabled) {
            form.requestSubmit();
        }
    });

    form.addEventListener('submit', () => {
        status.textContent = 'Calculating moonrise and moonset…';
        form.setAttribute('aria-busy', 'true');
        submit.disabled = true;
    });
})();
