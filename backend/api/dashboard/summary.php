<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    // Student Statistics
    $studentQuery = $conn->query("
        SELECT
            COUNT(*) AS total_students,
            SUM(status = 'Active') AS active_students
        FROM students
    ");

    $students = $studentQuery->fetch();

    // Course Statistics
    $courseQuery = $conn->query("
        SELECT COUNT(*) AS total_courses
        FROM courses
    ");

    $courses = $courseQuery->fetch();

    // Department Statistics
    $departmentQuery = $conn->query("
        SELECT COUNT(*) AS total_departments
        FROM departments
    ");

    $departments = $departmentQuery->fetch();

    // Total Revenue
    $revenueQuery = $conn->query("
        SELECT COALESCE(SUM(amount), 0) AS total_revenue
        FROM fee_payments
    ");

    $revenue = $revenueQuery->fetch();

    // Today's Attendance
    $attendanceQuery = $conn->prepare("
        SELECT
            COUNT(*) AS total_attendance,
            SUM(status = 'Present') AS present,
            SUM(status = 'Absent') AS absent,
            SUM(status = 'Leave') AS leave_count
        FROM attendance
        WHERE attendance_date = CURDATE()
    ");

    $attendanceQuery->execute();

    $attendance = $attendanceQuery->fetch();

    echo json_encode([
        "success" => true,
        "message" => "Dashboard summary retrieved successfully",

        "data" => [
            "total_students" => (int) $students["total_students"],
            "active_students" => (int) $students["active_students"],

            "total_courses" => (int) $courses["total_courses"],

            "total_departments" => (int) $departments["total_departments"],

            "total_revenue" => (float) $revenue["total_revenue"],

            "attendance" => [
                "total" => (int) $attendance["total_attendance"],
                "present" => (int) $attendance["present"],
                "absent" => (int) $attendance["absent"],
                "leave" => (int) $attendance["leave_count"]
            ]
        ]
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve dashboard summary"
    ]);
}
