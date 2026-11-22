<?php

require_once __DIR__ . "/jwt.php";

function base64UrlEncode($data)
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64UrlDecode($data)
{
    return base64_decode(
        strtr($data, '-_', '+/')
    );
}

// Generate JWT Token
function generateJWT($admin)
{
    $header = [
        "alg" => "HS256",
        "typ" => "JWT"
    ];

    $payload = [
        "iss" => JWT_ISSUER,
        "iat" => time(),
        "exp" => time() + JWT_EXPIRE_TIME,
        "admin_id" => (int) $admin["id"],
        "email" => $admin["email"]
    ];

    $encodedHeader = base64UrlEncode(
        json_encode($header)
    );

    $encodedPayload = base64UrlEncode(
        json_encode($payload)
    );

    $signature = hash_hmac(
        "sha256",
        $encodedHeader . "." . $encodedPayload,
        JWT_SECRET,
        true
    );

    $encodedSignature = base64UrlEncode($signature);

    return $encodedHeader . "." .
           $encodedPayload . "." .
           $encodedSignature;
}

// Verify JWT Token
function verifyJWT($token)
{
    $parts = explode(".", $token);

    if (count($parts) !== 3) {
        return false;
    }

    [$header, $payload, $signature] = $parts;

    $decodedHeader = json_decode(
        base64UrlDecode($header),
        true
    );

    if (
        !is_array($decodedHeader) ||
        ($decodedHeader["alg"] ?? "") !== "HS256" ||
        ($decodedHeader["typ"] ?? "") !== "JWT"
    ) {
        return false;
    }

    $expectedSignature = base64UrlEncode(
        hash_hmac(
            "sha256",
            $header . "." . $payload,
            JWT_SECRET,
            true
        )
    );

    if (!hash_equals($expectedSignature, $signature)) {
        return false;
    }

    $decodedPayload = json_decode(
        base64UrlDecode($payload),
        true
    );

    if (!is_array($decodedPayload)) {
        return false;
    }

    if (($decodedPayload["iss"] ?? "") !== JWT_ISSUER) {
        return false;
    }

    if (($decodedPayload["exp"] ?? 0) < time()) {
        return false;
    }

    return $decodedPayload;
}