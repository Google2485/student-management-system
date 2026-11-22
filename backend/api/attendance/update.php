
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $data = json_decode(file_get_contents("php://input"), true);

    $id = (int) ($data["id"] ?? 0);
    $status = $data["status"] ?? "";

    if (
        $id <= 0 ||
        !in_array($status, ["Present", "Absent", "Leave"], true)
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Valid attendance ID and status are required"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $stmt = $conn->prepare("
        UPDATE attendance
        SET status = :status
        WHERE id = :id
    ");

    $stmt->execute([
        ":status" => $status,
        ":id" => $id
    ]);

    if ($stmt->rowCount() > 0) {

        echo json_encode([
            "success" => true,
            "message" => "Attendance updated successfully"
        ]);

    } else {

        $check = $conn->prepare(
            "SELECT id FROM attendance WHERE id = :id"
        );
        $check->execute([":id" => $id]);

        if ($check->fetch()) {
            echo json_encode([
                "success" => true,
                "message" => "Attendance status is already the same"
            ]);
        } else {
            http_response_code(404);

            echo json_encode([
                "success" => false,
                "message" => "Attendance record not found"
            ]);
        }
    }

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to update attendance"
    ]);
}
