<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

require_post();
$input = input_json();
$token = (string)($input['token'] ?? '');
$user = user_from_token($token);

if (!$user) {
    fail('Sesja wygasla. Zaloguj sie ponownie.', 401);
}

$library = $input['library'] ?? null;
if (!is_array($library)) {
    fail('Brak danych biblioteki.');
}

$json = json_encode($library, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
if ($json === false) {
    fail('Nie moge zapisac biblioteki.');
}

$stmt = db()->prepare(
    'INSERT INTO user_libraries (user_id, data) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE data = VALUES(data), updated_at = CURRENT_TIMESTAMP'
);
$stmt->execute([(int)$user['id'], $json]);

respond(['ok' => true]);
