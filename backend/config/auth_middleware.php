<?php

require_once __DIR__ . "/jwt_helper.php";

function authenticateAdmin()
{
    $headers = getallheaders();

    $authHeader = $headers["Authorization"]
        ?? $headers["authorization"]
        ?? "";

    if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Authorization token missing"
        ]);

        exit;
    }

    $token = trim($matches[1]);

    $payload = verifyJWT($token);

    if (!$payload) {

        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid or expired token"
        ]);

        exit;
    }

    return $payload;
}