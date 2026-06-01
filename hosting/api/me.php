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

respond(['user' => public_user($user)]);
