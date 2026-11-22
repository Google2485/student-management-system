<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $student_id = (int) ($_GET["student_id"] ?? 0);

    $database = new Database();
    $conn = $database->connect();

    $sql = "
        SELECT
            fp.id,
            fp.student_id,
            s.student_id AS student_code,
            s.name AS student_name,
            fp.fee_type_id,
            ft.name AS fee_name,
            fp.amount,
            fp.payment_date,
            fp.payment_method,
            fp.transaction_id,
            fp.created_at
        FROM fee_payments fp
        INNER JOIN students s ON fp.student_id = s.id
        INNER JOIN fee_types ft ON fp.fee_type_id = ft.id
    ";

    if ($student_id > 0) {
        $sql .= " WHERE fp.student_id = :student_id";
    }

    $sql .= " ORDER BY fp.payment_date DESC, fp.id DESC";

    $query = $conn->prepare($sql);

    if ($student_id > 0) {
        $query->execute([
            ":student_id" => $student_id
        ]);
    } else {
        $query->execute();
    }

    $payments = $query->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Payment history retrieved successfully",
        "total" => count($payments),
        "data" => $payments
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve payment history"
    ]);
}