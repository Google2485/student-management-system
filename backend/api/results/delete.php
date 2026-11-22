<?php
require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only DELETE method is allowed"
    ]);
    exit;
}

$id = $_GET['id'] ?? null;

if (!$id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Result ID is required"
    ]);
    exit;
}

try {
    $database = new Database();
    $conn = $database->connect();

    $check = $conn->prepare(
        "SELECT id FROM academic_results WHERE id = :id"
    );
    $check->execute([':id' => $id]);

    if (!$check->fetch()) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Result not found"
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "DELETE FROM academic_results WHERE id = :id"
    );
    $stmt->execute([':id' => $id]);

    echo json_encode([
        "success" => true,
        "message" => "Result deleted successfully"
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Unable to delete result"
    ]);
}
