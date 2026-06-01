<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

set_exception_handler(function (Throwable $error): void {
    http_response_code(500);
    echo json_encode([
        'error' => 'Blad serwera API: ' . $error->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
});

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

function input_json(): array
{
    $raw = file_get_contents('php://input') ?: '{}';
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function respond(array $data, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function fail(string $message, int $status = 400): void
{
    respond(['error' => $message], $status);
}

function require_post(): void
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        fail('Method not allowed', 405);
    }
}

function clean_email(string $email): string
{
    return strtolower(trim($email));
}

function public_user(array $user): array
{
    return [
        'id' => (int)$user['id'],
        'email' => $user['email'],
        'created_at' => $user['created_at'],
    ];
}

function create_token(int $userId): string
{
    $token = bin2hex(random_bytes(32));
    $hash = hash('sha256', $token);
    $stmt = db()->prepare(
        'INSERT INTO sessions (user_id, token_hash, ip_address, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))'
    );
    $stmt->execute([$userId, $hash, client_ip()]);
    return $token;
}

function user_from_token(string $token): ?array
{
    if ($token === '') {
        return null;
    }

    $hash = hash('sha256', $token);
    $stmt = db()->prepare(
        'SELECT users.* FROM sessions JOIN users ON users.id = sessions.user_id WHERE sessions.token_hash = ? AND sessions.expires_at > NOW() LIMIT 1'
    );
    $stmt->execute([$hash]);
    $user = $stmt->fetch();
    return $user ?: null;
}
