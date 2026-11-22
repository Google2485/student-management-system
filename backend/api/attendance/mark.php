
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {
    $data = json_decode(file_get_contents("php://input"), true);

    $student_id = (int) ($data["student_id"] ?? 0);
    $date = $data["attendance_date"] ?? date("Y-m-d");
    $status = $data["status"] ?? "";

    if (
        $student_id <= 0 ||
        !in_array($status, ["Present", "Absent", "Leave"], true)
    ) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Valid student ID and attendance status are required"
        ]);
        exit;
    }

    $dateObject = DateTime::createFromFormat("!Y-m-d", $date);

    if (!$dateObject || $dateObject->format("Y-m-d") !== $date) {
        http_response_code(400);

        echo json_encode([
            "success" => false,
            "message" => "Invalid attendance date"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    // Check student exists
    $check = $conn->prepare(
        "SELECT id FROM students WHERE id = :id"
    );

    $check->execute([":id" => $student_id]);

    if (!$check->fetch()) {
        http_response_code(404);

        echo json_encode([
            "success" => false,
            "message" => "Student not found"
        ]);
        exit;
    }

    // Save or update attendance
    $sql = "
        INSERT INTO attendance
        (student_id, attendance_date, status)
        VALUES
        (:student_id, :attendance_date, :status)
        ON DUPLICATE KEY UPDATE
        status = :updated_status
    ";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":student_id" => $student_id,
        ":attendance_date" => $date,
        ":status" => $status,
        ":updated_status" => $status
    ]);

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Attendance saved successfully"
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to save attendance"
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
