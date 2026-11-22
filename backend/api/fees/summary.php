<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $student_id = (int) ($_GET["student_id"] ?? 0);

    $sql = "
        SELECT
            COUNT(*) AS total_payments,
            COALESCE(SUM(amount), 0) AS total_paid,
            COALESCE(AVG(amount), 0) AS average_payment
        FROM fee_payments
    ";

    if ($student_id > 0) {
        $sql .= " WHERE student_id = :student_id";
    }

    $query = $conn->prepare($sql);

    if ($student_id > 0) {
        $query->execute([
            ":student_id" => $student_id
        ]);
    } else {
        $query->execute();
    }

    $summary = $query->fetch();

    echo json_encode([
        "success" => true,
        "message" => "Fee summary retrieved successfully",
        "data" => [
            "total_payments" => (int) $summary["total_payments"],
            "total_paid" => (float) $summary["total_paid"],
            "average_payment" => (float) $summary["average_payment"]
        ]
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve fee summary"
    ]);
}