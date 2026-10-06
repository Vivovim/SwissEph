'use strict';

(() => {
    const NS = 'http://www.w3.org/2000/svg';
    const WIDTH = 1200;
    const LEFT = 32;
    const colors = ['#b76c45', '#5f7d5e', '#b39139', '#587e9b'];
    const fills = ['#f5e4d8', '#e5ecdf', '#f5edcc', '#e1edf3'];
    const byId = (id) => document.getElementById(id);
    const form = byId('chart-form');
    const timezone = byId('timezone');
    const city = byId('city');
    const cityStatus = byId('city-status');
    const live = byId('live');
    const status = byId('status');
    const svg = byId('zodiac-svg');
    let timer;
    let controller;
    let sequence = 0;
    let lastData = null;
    let cityController;
    let citySequence = 0;

    function syncButton() {
        byId('update-button').disabled = timezone.disabled || city.disabled || !city.value || svg.getAttribute('aria-busy') === 'true';
    }
    function cancelCalculation() {
        clearTimeout(timer);
        if (controller) controller.abort();
        ++sequence;
        svg.setAttribute('aria-busy', 'false');
        syncButton();
    }
    async function loadCities(preselect = '') {
        cancelCalculation();
        if (cityController) cityController.abort();
        const current = ++citySequence;
        cityController = new AbortController();
        const request = cityController;
        city.disabled = true;
        city.replaceChildren(new Option('Loading cities…', ''));
        city.setAttribute('aria-busy', 'true');
        cityStatus.classList.remove('error');
        cityStatus.textContent = 'Loading cities…';
        byId('location-details').textContent = 'Coordinates will load from the selected city. Live mode refreshes every minute.';
        byId('fold').value = '';
        byId('fold-control').hidden = true;
        status.classList.remove('error');
        status.textContent = 'Choose a city to draw its sky.' + (lastData ? ` The displayed chart is still for ${lastData.location.city}.` : '');
        syncButton();
        const timeout = setTimeout(() => request.abort(), 15000);
        try {
            const url = new URL(window.location.href);
            url.search = '';
            url.hash = '';
            url.searchParams.set('api', 'cities');
            url.searchParams.set('tz', timezone.value);
            const response = await fetch(url, { headers: { Accept: 'application/json' }, credentials: 'same-origin', cache: 'no-store', signal: request.signal });
            if (!response.headers.get('content-type')?.toLowerCase().startsWith('application/json')) {
                throw new Error('Unable to load cities. Please try again later.');
            }
            const data = await response.json();
            if (current !== citySequence) return;
            if (!response.ok || data.error) throw new Error(data.error?.message || 'Unable to load cities.');
            if (data.timezone !== timezone.value || !Array.isArray(data.cities)) throw new Error('The city list did not match the selected timezone.');
            const options = data.cities.map((row) => {
                if (typeof row.id !== 'string' || !/^[1-9][0-9]{0,9}$/.test(row.id) || typeof row.city !== 'string') throw new Error('The city list was invalid.');
                return new Option(row.city, row.id);
            });
            city.replaceChildren(new Option(options.length ? 'Select a city' : 'No cities available', ''), ...options);
            city.disabled = options.length === 0;
            cityStatus.textContent = options.length ? `${options.length} cities loaded. Choose a city.` : 'No cities are available for this timezone.';
            if (preselect && options.some((option) => option.value === preselect)) city.value = preselect;
        } catch (error) {
            if (current !== citySequence) return;
            city.replaceChildren(new Option('Unable to load cities', ''));
            cityStatus.classList.add('error');
            cityStatus.textContent = error.name === 'AbortError' ? 'City lookup timed out. Select a timezone again to retry.' : error.message;
        } finally {
            clearTimeout(timeout);
            if (current === citySequence) {
                city.removeAttribute('aria-busy');
                syncButton();
                if (city.value) update();
            }
        }
    }

    const degree = (n, precision = 2) => `${n.toFixed(precision)}°`;
    const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
    function element(tag, attributes = {}, text) {
        const node = document.createElementNS(NS, tag);
        for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, String(value));
        if (text !== undefined) node.textContent = text;
        return node;
    }
    function add(parent, tag, attributes, text) {
        const node = element(tag, attributes, text);
        parent.append(node);
        return node;
    }
    function coordinate(fraction) {
        if (typeof fraction !== 'number' || !Number.isFinite(fraction) || fraction < 0 || fraction > 1) {
            throw new Error('The service returned an invalid chart coordinate.');
        }
        return LEFT + fraction * WIDTH;
    }

    function markerLayout(planets) {
        const laneEnds = [];
        return planets.filter((planet) => planet.plot_on_chart).map((planet) => {
            const x = coordinate(planet.x_fraction);
            const labelX = clamp(x, LEFT + 58, LEFT + WIDTH - 58);
            return { planet, x, labelX, left: Math.min(x - 16, labelX - 55), right: Math.max(x + 16, labelX + 55) };
        }).sort((a, b) => a.left - b.left).map((marker) => {
            let lane = laneEnds.findIndex((right) => right + 12 <= marker.left);
            if (lane === -1) lane = laneEnds.length;
            laneEnds[lane] = marker.right;
            return { ...marker, lane };
        });
    }

    function renderChart(data) {
        const markers = markerLayout(data.planets);
        const lanes = Math.max(3, ...markers.map((marker) => marker.lane + 1));
        const top = 52;
        const bandHeight = 58;
        const bottom = top + bandHeight + 74 + lanes * 68;
        const height = bottom + bandHeight + 54;
        const root = element('g');
        add(root, 'text', { x: LEFT, y: 29, class: 'svg-section-label' }, 'ZODIAC');
        add(root, 'rect', { x: LEFT, y: top, width: WIDTH, height: bandHeight, fill: '#f5f1e9', rx: 2 });
        for (const sign of data.zodiac) {
            for (const segment of sign.segments) {
                const x = coordinate(segment.x_start_fraction);
                const end = coordinate(segment.x_end_fraction);
                const width = end - x;
                add(root, 'rect', { x, y: top, width, height: bandHeight, fill: fills[sign.index % 4], stroke: '#fffdf8', 'stroke-width': 1 });
                const center = x + width / 2;
                if (width >= 23) add(root, 'text', { x: center, y: top + 27, 'text-anchor': 'middle', class: 'sign-symbol', fill: colors[sign.index % 4] }, sign.symbol + '\uFE0E');
                if (width >= 66) add(root, 'text', { x: center, y: top + 47, 'text-anchor': 'middle', class: 'sign-name' }, sign.name);
                const title = `${sign.name}: ${sign.index * 30}°–${(sign.index + 1) * 30}° absolute longitude`;
                const tooltip = add(root, 'rect', { x, y: top, width, height: bandHeight, fill: 'transparent' });
                add(tooltip, 'title', {}, title);
            }
        }
        // Degree ticks are absolute zodiac longitudes, rotated by the ruler origin.
        for (let lon = 0; lon < 360; lon += 5) {
            const x = LEFT + ((lon - data.chart.origin_longitude_deg + 360) % 360) / 360 * WIDTH;
            add(root, 'line', { x1: x, x2: x, y1: top + bandHeight, y2: top + bandHeight + (lon % 30 === 0 ? 13 : 6), stroke: '#a69e91', 'stroke-width': 1 });
            if (lon % 30 === 0) add(root, 'text', { x, y: top + bandHeight + 28, class: 'degree-label', 'text-anchor': 'middle' }, `${lon}°`);
        }
        for (const house of data.houses) {
            const x = coordinate(house.x_start_fraction);
            const end = coordinate(house.x_end_fraction);
            add(root, 'line', { x1: x, x2: x, y1: top + bandHeight + 37, y2: bottom, stroke: '#e9e3d8', 'stroke-width': 1 });
            add(root, 'rect', { x, y: bottom, width: end - x, height: bandHeight, fill: house.number % 2 ? '#ece7dc' : '#f3efe6', stroke: '#fffdf8', 'stroke-width': 1 });
            add(root, 'text', { x: (x + end) / 2, y: bottom + 27, 'text-anchor': 'middle', class: 'house-number' }, house.number);
            if (end - x >= 60) add(root, 'text', { x: (x + end) / 2, y: bottom + 46, 'text-anchor': 'middle', class: 'house-cusp' }, `${house.sign.symbol}\uFE0E ${degree(house.sign.degree, 1)}`);
            const tooltip = add(root, 'rect', { x, y: bottom, width: end - x, height: bandHeight, fill: 'transparent' });
            add(tooltip, 'title', {}, `House ${house.number} begins at ${degree(house.cusp_longitude_deg, 6)} absolute longitude`);
        }
        add(root, 'text', { x: LEFT, y: bottom + bandHeight + 31, class: 'svg-section-label' }, 'HOUSES');
        add(root, 'text', { x: LEFT + WIDTH, y: bottom + bandHeight + 31, 'text-anchor': 'end', class: 'degree-label' }, `${degree(data.chart.origin_longitude_deg, 2)} → +360°`);

        for (const { planet, x, labelX, lane } of markers) {
            const y = top + bandHeight + 65 + lane * 68;
            const color = colors[planet.sign.index % 4];
            const group = add(root, 'g', { class: 'planet-marker', tabindex: 0, 'data-planet': planet.key,
                'data-longitude': planet.longitude_deg, 'data-x': x - LEFT,
                'aria-label': `${planet.name}, ${degree(planet.longitude_deg, 6)}, ${planet.sign.name}, house ${planet.house_number}${planet.retrograde ? ', retrograde' : ''}` });
            add(group, 'title', {}, `${planet.name} · ${degree(planet.longitude_deg, 8)} · ${planet.sign.name} ${degree(planet.sign.degree)} · House ${planet.house_number}${planet.retrograde ? ' · Retrograde' : ''}`);
            add(group, 'line', { x1: x, x2: x, y1: top + bandHeight + 36, y2: bottom, stroke: color, 'stroke-opacity': 0.2, 'stroke-width': 1, 'stroke-dasharray': '3 4' });
            add(group, 'circle', { cx: x, cy: y, r: 17, fill: '#fffdf8', stroke: color, 'stroke-width': 1.5 });
            add(group, 'text', { x, y: y + 7, 'text-anchor': 'middle', class: 'planet-symbol', fill: color }, planet.symbol);
            if (x !== labelX) add(group, 'line', { x1: x, y1: y + 18, x2: labelX, y2: y + 24, stroke: color, 'stroke-width': 1 });
            add(group, 'rect', { x: labelX - 56, y: y + 20, width: 112, height: 34, fill: '#fffdf8', rx: 3 });
            add(group, 'text', { x: labelX, y: y + 34, 'text-anchor': 'middle', class: 'planet-name' }, `${planet.name}${planet.retrograde ? ' ℞' : ''}`);
            add(group, 'text', { x: labelX, y: y + 49, 'text-anchor': 'middle', class: 'planet-degree' }, degree(planet.longitude_deg, 2));
        }
        const title = element('title', { id: 'svg-title' }, 'Zodiac ruler for ' + data.instant.local_datetime);
        const description = element('desc', { id: 'svg-description' }, `A straight 360-degree ecliptic ruler beginning at ${degree(data.chart.origin_longitude_deg)}. Zodiac signs above, twelve houses below, and ten geocentric bodies between them. Earth is listed separately. Horizontal positions represent absolute ecliptic longitude relative to the first house cusp.`);
        svg.setAttribute('viewBox', `0 0 1264 ${height}`);
        svg.replaceChildren(title, description, root);
    }

    function renderTable(data) {
        const rows = document.createDocumentFragment();
        for (const planet of data.planets.filter((p) => p.plot_on_chart)) {
            const row = document.createElement('tr');
            const values = [`${planet.symbol}  ${planet.name}`, degree(planet.longitude_deg, 8), `${planet.sign.name} ${degree(planet.sign.degree)}`, planet.house_number, planet.retrograde ? 'Retrograde' : 'Direct'];
            values.forEach((value, i) => {
                const cell = document.createElement(i === 0 ? 'th' : 'td');
                if (i === 0) cell.setAttribute('scope', 'row');
                cell.textContent = String(value);
                if (i === 4 && planet.retrograde) cell.classList.add('retrograde');
                row.append(cell);
            });
            rows.append(row);
        }
        byId('planet-rows').replaceChildren(rows);
        const earth = data.planets.find((p) => p.key === 'earth');
        byId('earth-note').textContent = `${earth.symbol} Earth · ${degree(earth.longitude_deg, 8)} · ${earth.sign.name} ${degree(earth.sign.degree)} · Heliocentric. Earth is the origin of the geocentric chart, so it has no position in the terrestrial houses.`;
    }

    function setTimeMode() {
        byId('date').disabled = live.checked;
        byId('time').disabled = live.checked;
        if (live.checked) {
            byId('fold').value = '';
            byId('fold-control').hidden = true;
        }
    }
    function schedule() {
        clearTimeout(timer);
        if (live.checked && !document.hidden && !city.disabled && city.value) timer = setTimeout(update, 60000);
    }
    async function update() {
        clearTimeout(timer);
        if (timezone.disabled || city.disabled || !city.value) {
            syncButton();
            return;
        }
        if (!form.reportValidity()) return;
        if (controller) controller.abort();
        controller = new AbortController();
        const currentController = controller;
        const current = ++sequence;
        const timeout = setTimeout(() => currentController.abort(), 25000);
        const button = byId('update-button');
        button.disabled = true;
        svg.setAttribute('aria-busy', 'true');
        status.classList.remove('error');
        status.textContent = 'Calculating the sky…';
        const request = {
            mode: live.checked ? 'now' : 'manual', timezone: timezone.value, city_id: city.value,
            house_system: byId('house-system').value,
        };
        if (!live.checked) {
            request.date = byId('date').value;
            request.time = byId('time').value;
            request.fold = byId('fold').value;
        }
        try {
            const url = new URL(window.location.href);
            url.search = '?api=chart';
            url.hash = '';
            const response = await fetch(url, {
                method: 'POST', credentials: 'same-origin', cache: 'no-store', signal: currentController.signal,
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content },
                body: JSON.stringify(request),
            });
            if (!response.headers.get('content-type')?.toLowerCase().startsWith('application/json')) {
                throw new Error('The chart service did not return JSON. Please try again later.');
            }
            const data = await response.json();
            if (current !== sequence) return;
            if (!response.ok || data.error) {
                if (data.error?.code === 'ambiguous_local_time') byId('fold-control').hidden = false;
                throw new Error(data.error?.message || 'The chart could not be calculated.');
            }
            renderChart(data);
            renderTable(data);
            lastData = data;
            byId('date').value = data.instant.date;
            byId('time').value = data.instant.time;
            byId('fold-control').hidden = true;
            const system = { E: 'Equal houses', P: 'Placidus', W: 'Whole-sign houses' }[data.calculation.house_system];
            byId('chart-meta').textContent = `${data.location.city} · ${system}`;
            byId('location-details').textContent = `${data.location.city} · Latitude ${data.location.latitude.toFixed(4)}° · Longitude ${data.location.longitude.toFixed(4)}° · ${data.location.timezone}`;
            byId('origin-note').textContent = `House 1 begins at ${degree(data.chart.origin_longitude_deg)}; each sign spans 30°.`;
            byId('utc-note').textContent = `UTC ${data.instant.utc_datetime.replace('T', ' ').replace('Z', '')}`;
            status.textContent = `${live.checked ? 'Live · ' : ''}${data.instant.date} · ${data.instant.time} · ${data.instant.timezone} (${data.instant.local_datetime.slice(19)})`;
        } catch (error) {
            if (current !== sequence) return;
            status.classList.add('error');
            const message = error.name === 'AbortError' ? 'The chart request timed out. Try again.' : error.message;
            status.textContent = message + (lastData ? ` Showing the previous chart for ${lastData.location.city} at ${lastData.instant.local_datetime}.` : '');
        } finally {
            clearTimeout(timeout);
            if (current === sequence) {
                svg.setAttribute('aria-busy', 'false');
                syncButton();
                schedule();
            }
        }
    }
    form.addEventListener('submit', (event) => { event.preventDefault(); update(); });
    live.addEventListener('change', () => { setTimeMode(); update(); });
    byId('house-system').addEventListener('change', update);
    timezone.addEventListener('change', () => loadCities());
    city.addEventListener('change', () => {
        cancelCalculation();
        byId('fold').value = '';
        byId('fold-control').hidden = true;
        if (city.value) update();
        else {
            status.textContent = 'Choose a city to draw its sky.' + (lastData ? ` The displayed chart is still for ${lastData.location.city}.` : '');
            syncButton();
        }
    });
    for (const id of ['date', 'time']) byId(id).addEventListener('change', () => { byId('fold').value = ''; byId('fold-control').hidden = true; });
    document.addEventListener('visibilitychange', () => { clearTimeout(timer); if (!document.hidden && live.checked) update(); });
    window.addEventListener('pagehide', () => { clearTimeout(timer); if (controller) controller.abort(); if (cityController) cityController.abort(); });
    setTimeMode();
    if (!timezone.disabled && timezone.value) loadCities(city.dataset.defaultCity || '');
})();
