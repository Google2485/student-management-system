
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (
        !$data ||
        empty($data["id"]) ||
        empty($data["name"])
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Department ID and name are required"
        ]);
        exit;
    }

    $id = (int) $data["id"];
    $name = trim($data["name"]);

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

    // Update department
    $sql = "UPDATE departments SET name = :name WHERE id = :id";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":name" => $name,
        ":id" => $id
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Department updated successfully"
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update department"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
