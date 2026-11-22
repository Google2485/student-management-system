<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/jwt_helper.php";

try {

    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        http_response_code(405);

        echo json_encode([
            "success" => false,
            "message" => "Only POST method is allowed"
        ]);
        exit;
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $email = trim($data["email"] ?? "");
    $password = $data["password"] ?? "";

    if ($email === "" || $password === "") {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Email and password are required"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $query = $conn->prepare("
        SELECT id, name, email, password
        FROM admins
        WHERE email = :email
        LIMIT 1
    ");

    $query->execute([
        ":email" => $email
    ]);

    $admin = $query->fetch();

    if (!$admin || !password_verify($password, $admin["password"])) {
        http_response_code(401);

        echo json_encode([
            "success" => false,
            "message" => "Invalid email or password"
        ]);
        exit;
    }

    // Generate real JWT
    $token = generateJWT($admin);

    echo json_encode([
        "success" => true,
        "message" => "Login successful",
        "token_type" => "Bearer",
        "expires_in" => JWT_EXPIRE_TIME,
        "token" => $token,
        "admin" => [
            "id" => $admin["id"],
            "name" => $admin["name"],
            "email" => $admin["email"]
        ]
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to login"
    ]);
}