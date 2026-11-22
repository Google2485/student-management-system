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
            COALESCE(SUM(status = 'Active'), 0) AS active_students,
            COALESCE(SUM(status = 'Inactive'), 0) AS inactive_students
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

    // Fee Statistics
    $feeQuery = $conn->query("
        SELECT
            COUNT(*) AS total_payments,
            COALESCE(SUM(amount), 0) AS total_collection,
            COALESCE(AVG(amount), 0) AS average_payment
        FROM fee_payments
    ");

    $fees = $feeQuery->fetch();

    // Attendance Statistics
    $attendanceQuery = $conn->query("
        SELECT
            COUNT(*) AS total_attendance,
            COALESCE(SUM(status = 'Present'), 0) AS present,
            COALESCE(SUM(status = 'Absent'), 0) AS absent,
            COALESCE(SUM(status = 'Leave'), 0) AS leave_count
        FROM attendance
    ");

    $attendance = $attendanceQuery->fetch();

    // Results Statistics
    $resultsQuery = $conn->query("
        SELECT
            COUNT(*) AS total_results,
            COALESCE(AVG(marks), 0) AS average_marks,
            COALESCE(MAX(marks), 0) AS highest_marks,
            COALESCE(MIN(marks), 0) AS lowest_marks
        FROM academic_results
    ");

    $results = $resultsQuery->fetch();

    echo json_encode([
        "success" => true,
        "message" => "Reports summary retrieved successfully",

        "data" => [
            "students" => [
                "total" => (int) $students["total_students"],
                "active" => (int) $students["active_students"],
                "inactive" => (int) $students["inactive_students"]
            ],

            "courses" => [
                "total" => (int) $courses["total_courses"]
            ],

            "departments" => [
                "total" => (int) $departments["total_departments"]
            ],

            "fees" => [
                "total_payments" => (int) $fees["total_payments"],
                "total_collection" => (float) $fees["total_collection"],
                "average_payment" => (float) $fees["average_payment"]
            ],

            "attendance" => [
                "total" => (int) $attendance["total_attendance"],
                "present" => (int) $attendance["present"],
                "absent" => (int) $attendance["absent"],
                "leave" => (int) $attendance["leave_count"]
            ],

            "results" => [
                "total" => (int) $results["total_results"],
                "average_marks" => round((float) $results["average_marks"], 2),
                "highest_marks" => (float) $results["highest_marks"],
                "lowest_marks" => (float) $results["lowest_marks"]
            ]
        ]
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve reports summary"
    ]);
}
