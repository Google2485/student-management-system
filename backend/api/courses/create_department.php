
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (!$data || empty($data["name"])) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Department name is required"
        ]);
        exit;
    }

    $name = trim($data["name"]);

    $database = new Database();
    $conn = $database->connect();

    $sql = "INSERT INTO departments (name) VALUES (:name)";

    $stmt = $conn->prepare($sql);
    $stmt->execute([
        ":name" => $name
    ]);

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Department created successfully",
        "department_id" => $conn->lastInsertId()
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to create department"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}

