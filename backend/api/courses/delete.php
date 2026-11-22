
<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only POST method is allowed"
    ]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data["id"]) || !is_numeric($data["id"])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Course ID is required"
    ]);
    exit;
}

try {
    $database = new Database();
    $db = $database->connect();

    $id = (int) $data["id"];

    $check = $db->prepare("SELECT id FROM courses WHERE id = ?");
    $check->execute([$id]);

    if (!$check->fetch()) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Course not found"
        ]);
        exit;
    }

    $stmt = $db->prepare("DELETE FROM courses WHERE id = ?");
    $stmt->execute([$id]);

    echo json_encode([
        "success" => true,
        "message" => "Course deleted successfully"
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to delete course"
    ]);
}
