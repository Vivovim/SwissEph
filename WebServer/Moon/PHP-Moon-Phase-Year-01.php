<?php
// Display each month's stored moon phases from earliest to latest.
// Standalone snippet, or include it in your existing page. Existing database
// settings from swish.php are used when $host/$username/$password/$db are set.
$host = $host ?? 'localhost';
$username = $username ?? '__USERNAME__';
$password = $password ?? '__PASSWORD__';
$db = $db ?? 'masterbox';

// DISPLAY OPTIONS
$displayTimezone = 'America/Phoenix'; // Change to 'UTC' to display UTC dates.
$dateFormat = 'r';                   // 'r' = readable date; 'U' = Unix seconds.
$showMissingPhases = false;         // true displays 'na' entries after dated phases.

date_default_timezone_set($displayTimezone);
$calendarYear = (int) date('Y');     // Or set a specific year, e.g. 2026.

// Select only the requested year, with months in calendar order.
$startDate = sprintf('%04d-01-01', $calendarYear);
$endDate = sprintf('%04d-01-01', $calendarYear + 1);

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
    $moonConnection = new mysqli($host, $username, $password, $db);
    $moonConnection->set_charset('utf8mb4');
    $moonStatement = $moonConnection->prepare(
        'SELECT * FROM `yearphase_new`
         WHERE `date` >= ? AND `date` < ?
         ORDER BY `date` ASC'
    );
    $moonStatement->bind_param('ss', $startDate, $endDate);
    $moonStatement->execute();
    $moonResults = $moonStatement->get_result();

    // Array of months, each containing an array of phase/timestamp pairs.
    // All nine pairs are retained here, including 'na' and NULL values.
    $calendar = [];
    while ($row = $moonResults->fetch_assoc()) {
        $phases = [];
        for ($slot = 1; $slot <= 9; $slot++) {
            $phases[$slot] = [
                'phase' => $row['phase' . $slot],
                'stamp' => $row['stamp' . $slot] === null
                    ? null
                    : (int) $row['stamp' . $slot],
            ];
        }

        // Sort the complete entries by Unix seconds BEFORE formatting dates.
        // uasort preserves slot keys (1..9), keeping each label with its stamp.
        // Missing entries have no date, so place them after all dated events.
        uasort($phases, static function ($left, $right) {
            $leftMissing = $left['phase'] === 'na' || $left['stamp'] === null;
            $rightMissing = $right['phase'] === 'na' || $right['stamp'] === null;

            if ($leftMissing !== $rightMissing) {
                return $leftMissing ? 1 : -1;
            }
            if ($leftMissing) {
                return 0;
            }

            return $left['stamp'] <=> $right['stamp'];
        });

        $calendar[$row['date']] = [
            'id' => (int) $row['id'],
            'date' => $row['date'],
            'phases' => $phases,
        ];
    }

    $moonResults->free();
    $moonStatement->close();
    $moonConnection->close();
} catch (mysqli_sql_exception $error) {
    // Keep database connection details out of the displayed page.
    error_log('Moon calendar database error: ' . $error->getMessage());
    echo '<p>The moon phase calendar is temporarily unavailable.</p>';
    return;
}

// Example array access:
// $calendar['2026-05-01']['phases'][9]['phase']  -> 'Blue Moon'
// $calendar['2026-05-01']['phases'][9]['stamp']  -> UTC Unix timestamp
// foreach visits each month's phase entries in chronological order,
// even though their original slot keys may be 5, 6, 7, 8, 1, 2, 3, 4, 9.

$escapeMoonText = static function ($value) {
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
};
?>

<div class="moon-phase-calendar">
    <h2>Moon phases for <?= $calendarYear ?></h2>
    <p>Phases are listed from the start to the end of each month.
        Times shown in <?= $escapeMoonText($displayTimezone) ?>.</p>

    <?php if (!$calendar): ?>
        <p>No moon phase data is available for this year.</p>
    <?php endif; ?>

    <?php foreach ($calendar as $month): ?>
        <section class="moon-phase-month">
            <h3><?= $escapeMoonText(date('F Y', strtotime($month['date']))) ?></h3>
            <table>
                <thead>
                    <tr><th scope="col">Phase</th><th scope="col">Date</th></tr>
                </thead>
                <tbody>
                    <?php foreach ($month['phases'] as $entry): ?>
                        <?php
                        $missing = $entry['phase'] === 'na' || $entry['stamp'] === null;
                        if ($missing && !$showMissingPhases) {
                            continue;
                        }

                        // With $dateFormat = 'r', this is date("r", $value).
                        // Never format NULL: an absent event is not Jan 1, 1970.
                        $value = $entry['stamp'];
                        $var = $missing ? 'na' : date($dateFormat, $value);
                        ?>
                        <tr>
                            <td><?= $escapeMoonText($entry['phase']) ?></td>
                            <td><?= $escapeMoonText($var) ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>
    <?php endforeach; ?>
</div>
