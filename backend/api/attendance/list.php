
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $date = $_GET["date"] ?? date("Y-m-d");

    $dateObject = DateTime::createFromFormat("!Y-m-d", $date);

    if (!$dateObject || $dateObject->format("Y-m-d") !== $date) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Invalid attendance date"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $sql = "
        SELECT
            s.id AS student_id,
            s.student_id AS student_code,
            s.name,
            s.email,
            s.phone,
            c.name AS course_name,
            a.id AS attendance_id,
            a.status,
            a.attendance_date
        FROM students s
        LEFT JOIN courses c
            ON s.course_id = c.id
        LEFT JOIN attendance a
            ON s.id = a.student_id
            AND a.attendance_date = :attendance_date
        ORDER BY s.id DESC
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":attendance_date" => $date
    ]);

    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "success" => true,
        "message" => "Attendance list retrieved successfully",
        "date" => $date,
        "total" => count($students),
        "data" => $students
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve attendance list"
    ]);
}

