<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

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

    $name = trim($data["name"] ?? "");
    $email = trim($data["email"] ?? "");
    $password = $data["password"] ?? "";

    // Validation
    if ($name === "" || $email === "" || $password === "") {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "All fields are required"
        ]);
        exit;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Invalid email address"
        ]);
        exit;
    }

    if (strlen($password) < 8) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Password must be at least 8 characters"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    // Check existing admin
    $check = $conn->prepare("
        SELECT id FROM admins WHERE email = :email
    ");

    $check->execute([
        ":email" => $email
    ]);

    if ($check->fetch()) {
        http_response_code(409);

        echo json_encode([
            "success" => false,
            "message" => "Admin email already exists"
        ]);
        exit;
    }

    // Hash password
    $hashedPassword = password_hash(
        $password,
        PASSWORD_DEFAULT
    );

    // Insert admin
    $query = $conn->prepare("
        INSERT INTO admins (name, email, password)
        VALUES (:name, :email, :password)
    ");

    $query->execute([
        ":name" => $name,
        ":email" => $email,
        ":password" => $hashedPassword
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Admin registered successfully",
        "admin_id" => $conn->lastInsertId()
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to register admin"
    ]);
}