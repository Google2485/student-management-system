
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {
    $database = new Database();
    $conn = $database->connect();

    $stmt = $conn->prepare("
        SELECT id, name, created_at
        FROM departments
        ORDER BY id DESC
    ");

    $stmt->execute();

    $departments = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Departments retrieved successfully",
        "total" => count($departments),
        "data" => $departments
    ]);

} catch (Exception $e) {
    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve departments"
    ]);
}