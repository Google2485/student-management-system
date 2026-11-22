<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/auth_middleware.php";

try {

    // Verify JWT Token
    $adminData = authenticateAdmin();

    $database = new Database();
    $conn = $database->connect();

    // Get admin information
    $query = $conn->prepare("
        SELECT id, name, email, created_at
        FROM admins
        WHERE id = :id
        LIMIT 1
    ");

    $query->execute([
        ":id" => $adminData["admin_id"]
    ]);

    $admin = $query->fetch();

    if (!$admin) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Admin not found"
        ]);
        exit;
    }

    echo json_encode([
        "success" => true,
        "message" => "Admin profile retrieved successfully",
        "data" => $admin
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve admin profile"
    ]);
}