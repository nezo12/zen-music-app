<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

$checks = [
    'php' => PHP_VERSION,
    'pdo_mysql' => extension_loaded('pdo_mysql'),
    'db_connection' => false,
    'users_table' => false,
    'sessions_table' => false,
];

try {
    $pdo = db();
    $checks['db_connection'] = true;

    $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
    $checks['users_table'] = (bool)$stmt->fetchColumn();

    $stmt = $pdo->query("SHOW TABLES LIKE 'sessions'");
    $checks['sessions_table'] = (bool)$stmt->fetchColumn();

    respond([
        'ok' => $checks['pdo_mysql']
            && $checks['db_connection']
            && $checks['users_table']
            && $checks['sessions_table'],
        'checks' => $checks,
    ]);
} catch (Throwable $error) {
    respond([
        'ok' => false,
        'checks' => $checks,
        'error' => $error->getMessage(),
    ], 500);
}
