<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

require_post();
$input = input_json();
$token = (string)($input['token'] ?? '');

if ($token !== '') {
    $stmt = db()->prepare('DELETE FROM sessions WHERE token_hash = ?');
    $stmt->execute([hash('sha256', $token)]);
}

respond(['ok' => true]);
