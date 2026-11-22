<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only POST method is allowed"
    ]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (!$data) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Invalid JSON data"
    ]);
    exit;
}

$studentId = $data['student_id'] ?? null;
$examName = trim($data['exam_name'] ?? '');
$subject = trim($data['subject'] ?? '');
$marks = $data['marks'] ?? null;
$grade = trim($data['grade'] ?? '');

if (!$studentId || $examName === '' || $subject === '' || $marks === null) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Student ID, exam name, subject and marks are required"
    ]);
    exit;
}

if (!is_numeric($marks) || $marks < 0 || $marks > 100) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Marks must be between 0 and 100"
    ]);
    exit;
}

try {

    $database = new Database();
    $conn = $database->connect();

    // Check whether student exists
    $checkStudent = $conn->prepare(
        "SELECT id FROM students WHERE id = :student_id"
    );

    $checkStudent->execute([
        ':student_id' => $studentId
    ]);

    if (!$checkStudent->fetch()) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Student not found"
        ]);
        exit;
    }

    // Insert result
    $sql = "
        INSERT INTO academic_results
        (student_id, subject, marks, grade, exam_name)
        VALUES
        (:student_id, :subject, :marks, :grade, :exam_name)
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':student_id' => $studentId,
        ':subject' => $subject,
        ':marks' => $marks,
        ':grade' => $grade !== '' ? $grade : null,
        ':exam_name' => $examName
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Result added successfully",
        "result_id" => $conn->lastInsertId()
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to add result"
    ]);
}
