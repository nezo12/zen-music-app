<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

require_post();
$input = input_json();
$email = clean_email((string)($input['email'] ?? ''));
$password = (string)($input['password'] ?? '');

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fail('Podaj poprawny email.');
}

if (strlen($password) < 8) {
    fail('Haslo musi miec minimum 8 znakow.');
}

$ip = client_ip();
$stmt = db()->prepare('SELECT COUNT(*) FROM users WHERE registration_ip = ?');
$stmt->execute([$ip]);
if ((int)$stmt->fetchColumn() >= MAX_ACCOUNTS_PER_IP) {
    fail('Z tego IP mozna utworzyc maksymalnie 2 konta.', 429);
}

$stmt = db()->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    fail('Konto z tym emailem juz istnieje.', 409);
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = db()->prepare('INSERT INTO users (email, password_hash, registration_ip) VALUES (?, ?, ?)');
$stmt->execute([$email, $hash, $ip]);
$userId = (int)db()->lastInsertId();

$stmt = db()->prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
$stmt->execute([$userId]);
$user = $stmt->fetch();

respond([
    'token' => create_token($userId),
    'user' => public_user($user),
], 201);
