
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

    $fields = [
        "student_id",
        "name",
        "email",
        "phone",
        "gender",
        "address",
        "admission_date",
        "course_id",
        "status"
    ];

    $updates = [];
    $params = [":id" => $id];

    foreach ($fields as $field) {
        if (array_key_exists($field, $data)) {
            $updates[] = "$field = :$field";
            $params[":$field"] = $data[$field] === "" ? null : $data[$field];
        }
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "No fields provided to update"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $sql = "UPDATE students SET " . implode(", ", $updates) . " WHERE id = :id";

    $stmt = $conn->prepare($sql);
    $stmt->execute($params);

    echo json_encode([
        "success" => true,
        "message" => $stmt->rowCount() > 0
            ? "Student updated successfully"
            : "No changes made or student not found"
    ]);

} catch (PDOException $e) {
    error_log($e->getMessage());
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update student. Check the submitted data."
    ]);

} catch (Exception $e) {
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
