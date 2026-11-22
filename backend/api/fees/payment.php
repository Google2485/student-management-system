<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        http_response_code(405);

        echo json_encode([
            "success" => false,
            "message" => "Only POST method is allowed"
        ]);
        exit;
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $student_id = (int) ($data["student_id"] ?? 0);
    $fee_type_id = (int) ($data["fee_type_id"] ?? 0);
    $amount = $data["amount"] ?? null;
    $payment_date = $data["payment_date"] ?? date("Y-m-d");
    $payment_method = trim($data["payment_method"] ?? "");
    $transaction_id = trim($data["transaction_id"] ?? "");

    if (
        $student_id <= 0 ||
        $fee_type_id <= 0 ||
        !is_numeric($amount) ||
        $amount <= 0 ||
        $payment_method === ""
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Required payment information is missing"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    // Check student
    $studentCheck = $conn->prepare("
        SELECT id FROM students WHERE id = :id
    ");

    $studentCheck->execute([
        ":id" => $student_id
    ]);

    if (!$studentCheck->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Student not found"
        ]);
        exit;
    }

    // Check fee type
    $feeCheck = $conn->prepare("
        SELECT id FROM fee_types WHERE id = :id
    ");

    $feeCheck->execute([
        ":id" => $fee_type_id
    ]);

    if (!$feeCheck->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Fee type not found"
        ]);
        exit;
    }

    // Validate date
    $date = DateTime::createFromFormat("!Y-m-d", $payment_date);

    if (!$date || $date->format("Y-m-d") !== $payment_date) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Invalid payment date"
        ]);
        exit;
    }

    // Save payment
    $query = $conn->prepare("
        INSERT INTO fee_payments
        (
            student_id,
            fee_type_id,
            amount,
            payment_date,
            payment_method,
            transaction_id
        )
        VALUES
        (
            :student_id,
            :fee_type_id,
            :amount,
            :payment_date,
            :payment_method,
            :transaction_id
        )
    ");

    $query->execute([
        ":student_id" => $student_id,
        ":fee_type_id" => $fee_type_id,
        ":amount" => $amount,
        ":payment_date" => $payment_date,
        ":payment_method" => $payment_method,
        ":transaction_id" => $transaction_id !== "" ? $transaction_id : null
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Payment saved successfully",
        "payment_id" => $conn->lastInsertId()
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to save payment"
    ]);
}