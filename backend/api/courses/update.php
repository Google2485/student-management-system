
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    if (
        !$data ||
        empty($data["id"]) ||
        empty($data["name"]) ||
        empty($data["department_id"])
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Course ID, name and department ID are required"
        ]);
        exit;
    }

    $id = (int) $data["id"];
    $name = trim($data["name"]);
    $course_code = trim($data["course_code"] ?? "");
    $department_id = (int) $data["department_id"];

    $database = new Database();
    $conn = $database->connect();

    // Check course exists
    $checkCourse = $conn->prepare(
        "SELECT id FROM courses WHERE id = :id"
    );

    $checkCourse->execute([":id" => $id]);

    if (!$checkCourse->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Course not found"
        ]);
        exit;
    }

    // Check department exists
    $checkDepartment = $conn->prepare(
        "SELECT id FROM departments WHERE id = :id"
    );

    $checkDepartment->execute([":id" => $department_id]);

    if (!$checkDepartment->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Department not found"
        ]);
        exit;
    }

    // Update course
    $sql = "
        UPDATE courses
        SET
            name = :name,
            course_code = :course_code,
            department_id = :department_id
        WHERE id = :id
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":name" => $name,
        ":course_code" => $course_code ?: null,
        ":department_id" => $department_id,
        ":id" => $id
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Course updated successfully"
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update course"
    ]);
}
