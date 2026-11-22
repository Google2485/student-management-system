
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $student_id = (int) ($_GET["student_id"] ?? 0);

    if ($student_id <= 0) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Student ID is required"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    // Check student exists
    $check = $conn->prepare("
        SELECT id, student_id, name
        FROM students
        WHERE id = :id
    ");

    $check->execute([":id" => $student_id]);

    $student = $check->fetch();

    if (!$student) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Student not found"
        ]);
        exit;
    }

    // Attendance summary
    $summaryQuery = $conn->prepare("
        SELECT
            COUNT(*) AS total_days,
            SUM(status = 'Present') AS present_days,
            SUM(status = 'Absent') AS absent_days,
            SUM(status = 'Leave') AS leave_days
        FROM attendance
        WHERE student_id = :student_id
    ");

    $summaryQuery->execute([
        ":student_id" => $student_id
    ]);

    $summary = $summaryQuery->fetch();

    // Attendance history
    $historyQuery = $conn->prepare("
        SELECT id, attendance_date, status
        FROM attendance
        WHERE student_id = :student_id
        ORDER BY attendance_date DESC
    ");

    $historyQuery->execute([
        ":student_id" => $student_id
    ]);

    $history = $historyQuery->fetchAll();

    $total = (int) $summary["total_days"];
    $present = (int) $summary["present_days"];

    $percentage = $total > 0
        ? round(($present / $total) * 100, 2)
        : 0;

    echo json_encode([
        "success" => true,
        "message" => "Attendance report retrieved successfully",
        "student" => $student,
        "summary" => [
            "total_days" => $total,
            "present_days" => $present,
            "absent_days" => (int) $summary["absent_days"],
            "leave_days" => (int) $summary["leave_days"],
            "attendance_percentage" => $percentage
        ],
        "history" => $history
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to generate attendance report"
    ]);
}
