<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only PUT method is allowed"
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

$id = $data['id'] ?? null;
$examName = trim($data['exam_name'] ?? '');
$subject = trim($data['subject'] ?? '');
$marks = $data['marks'] ?? null;
$grade = trim($data['grade'] ?? '');

if (!$id || $examName === '' || $subject === '' || $marks === null) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Result ID, exam name, subject and marks are required"
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

    $check = $conn->prepare(
        "SELECT id FROM academic_results WHERE id = :id"
    );

    $check->execute([':id' => $id]);

    if (!$check->fetch()) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Result not found"
        ]);
        exit;
    }

    $sql = "
        UPDATE academic_results
        SET
            exam_name = :exam_name,
            subject = :subject,
            marks = :marks,
            grade = :grade
        WHERE id = :id
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ':exam_name' => $examName,
        ':subject' => $subject,
        ':marks' => $marks,
        ':grade' => $grade !== '' ? $grade : null,
        ':id' => $id
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Result updated successfully"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update result"
    ]);
}
