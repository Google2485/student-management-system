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

    $name = trim($data["name"] ?? "");
    $amount = $data["amount"] ?? null;

    if ($name === "" || !is_numeric($amount) || $amount <= 0) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Valid fee name and amount are required"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $query = $conn->prepare("
        INSERT INTO fee_types (name, amount)
        VALUES (:name, :amount)
    ");

    $query->execute([
        ":name" => $name,
        ":amount" => $amount
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Fee type created successfully",
        "fee_type_id" => $conn->lastInsertId()
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to create fee type"
    ]);
}