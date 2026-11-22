
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (
        !$data ||
        empty($data["name"]) ||
        empty($data["department_id"])
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Course name and department ID are required"
        ]);
        exit;
    }

    $name = trim($data["name"]);
    $course_code = trim($data["course_code"] ?? "");
    $department_id = (int) $data["department_id"];

    $database = new Database();
    $conn = $database->connect();

    // Check department exists
    $check = $conn->prepare(
        "SELECT id FROM departments WHERE id = :id"
    );

    $check->execute([":id" => $department_id]);

    if (!$check->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Department not found"
        ]);
        exit;
    }

    // Create course
    $sql = "
        INSERT INTO courses
        (department_id, name, course_code)
        VALUES
        (:department_id, :name, :course_code)
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":department_id" => $department_id,
        ":name" => $name,
        ":course_code" => $course_code ?: null
    ]);

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Course created successfully",
        "course_id" => $conn->lastInsertId()
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to create course. Check the submitted data."
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
