
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $sql = "
        SELECT
            students.id,
            students.student_id,
            students.name,
            students.email,
            students.phone,
            students.gender,
            students.address,
            students.admission_date,
            students.status,
            students.created_at,
            courses.name AS course_name,
            departments.name AS department_name

        FROM students

        LEFT JOIN courses
            ON students.course_id = courses.id

        LEFT JOIN departments
            ON courses.department_id = departments.id

        ORDER BY students.id DESC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();

    $students = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Students retrieved successfully",
        "total" => count($students),
        "data" => $students
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve students"
    ]);
}
