<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $query = $conn->prepare("
        SELECT id, name, amount
        FROM fee_types
        ORDER BY id DESC
    ");

    $query->execute();

    $fees = $query->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Fee types retrieved successfully",
        "total" => count($fees),
        "data" => $fees
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve fee types"
    ]);
}