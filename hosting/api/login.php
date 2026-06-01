<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

require_post();
$input = input_json();
$email = clean_email((string)($input['email'] ?? ''));
$password = (string)($input['password'] ?? '');

$stmt = db()->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    fail('Nieprawidlowy email albo haslo.', 401);
}

respond([
    'token' => create_token((int)$user['id']),
    'user' => public_user($user),
]);
