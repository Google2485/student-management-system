
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $sql = "
        SELECT
            courses.id,
            courses.name,
            courses.course_code,
            courses.department_id,
            departments.name AS department_name,
            courses.created_at
        FROM courses
        LEFT JOIN departments
            ON courses.department_id = departments.id
        ORDER BY courses.id DESC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();

    $courses = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Courses retrieved successfully",
        "total" => count($courses),
        "data" => $courses
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve courses"
    ]);
}
