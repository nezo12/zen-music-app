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

$stmt = db()->prepare('SELECT data, updated_at FROM user_libraries WHERE user_id = ? LIMIT 1');
$stmt->execute([(int)$user['id']]);
$library = $stmt->fetch();

if (!$library) {
    respond([
        'library' => null,
        'updated_at' => null,
    ]);
}

$data = json_decode((string)$library['data'], true);
respond([
    'library' => is_array($data) ? $data : [],
    'updated_at' => $library['updated_at'],
]);
