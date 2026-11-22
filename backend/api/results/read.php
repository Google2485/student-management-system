<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $studentId = $_GET['student_id'] ?? null;
    $examName = $_GET['exam_name'] ?? null;

    $sql = "
        SELECT
            academic_results.id,
            academic_results.student_id,
            students.student_id AS student_code,
            students.name AS student_name,
            academic_results.exam_name,
            academic_results.subject,
            academic_results.marks,
            academic_results.grade,
            academic_results.created_at

        FROM academic_results

        LEFT JOIN students
            ON academic_results.student_id = students.id
    ";

    $conditions = [];
    $params = [];

    if (!empty($studentId)) {
        $conditions[] = "academic_results.student_id = :student_id";
        $params[':student_id'] = $studentId;
    }

    if (!empty($examName)) {
        $conditions[] = "academic_results.exam_name LIKE :exam_name";
        $params[':exam_name'] = '%' . $examName . '%';
    }

    if (!empty($conditions)) {
        $sql .= " WHERE " . implode(" AND ", $conditions);
    }

    $sql .= " ORDER BY academic_results.id DESC";

    $stmt = $conn->prepare($sql);
    $stmt->execute($params);

    $results = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Results retrieved successfully",
        "total" => count($results),
        "data" => $results
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve results"
    ]);
}
