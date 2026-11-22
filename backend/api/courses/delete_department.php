
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (!$data || empty($data["id"])) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Department ID is required"
        ]);
        exit;
    }

    $id = (int) $data["id"];

    $database = new Database();
    $conn = $database->connect();

    // Check department exists
    $check = $conn->prepare(
        "SELECT id FROM departments WHERE id = :id"
    );

    $check->execute([
        ":id" => $id
    ]);

    if (!$check->fetch(PDO::FETCH_ASSOC)) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Department not found"
        ]);
        exit;
    }

    // Delete department
    $stmt = $conn->prepare(
        "DELETE FROM departments WHERE id = :id"
    );

    $stmt->execute([
        ":id" => $id
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Department deleted successfully"
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to delete department. It may have associated courses."
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
