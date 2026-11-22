
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (!$data || empty($data["id"])) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Student ID is required"
        ]);
        exit;
    }

    $id = (int) $data["id"];

    $database = new Database();
    $conn = $database->connect();

    $sql = "DELETE FROM students WHERE id = :id";

    $stmt = $conn->prepare($sql);
    $stmt->execute([
        ":id" => $id
    ]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            "success" => true,
            "message" => "Student deleted successfully"
        ]);
    } else {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Student not found"
        ]);
    }

} catch (PDOException $e) {

    error_log($e->getMessage());
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to delete student"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
