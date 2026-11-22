
<?php

require_once __DIR__ . "/config/database.php";

header("Content-Type: application/json");

try {
    $database = new Database();
    $conn = $database->connect();

    echo json_encode([
        "success" => true,
        "message" => "EduManage Database Connected Successfully!"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}
