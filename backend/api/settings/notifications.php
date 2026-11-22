<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/auth_middleware.php";

try {

    $adminData = authenticateAdmin();

    $database = new Database();
    $conn = $database->connect();

    $adminId = $adminData["admin_id"];
    $method = $_SERVER["REQUEST_METHOD"];

    if ($method === "GET") {

        $query = $conn->prepare("
            SELECT email_notifications,
                   student_notifications,
                   fee_notifications,
                   attendance_notifications
            FROM notification_settings
            WHERE admin_id = :admin_id
            LIMIT 1
        ");

        $query->execute([":admin_id" => $adminId]);
        $settings = $query->fetch();

        if (!$settings) {
            $settings = [
                "email_notifications" => 1,
                "student_notifications" => 1,
                "fee_notifications" => 1,
                "attendance_notifications" => 1
            ];
        }

        foreach ($settings as $key => $value) {
            $settings[$key] = (bool) $value;
        }

        echo json_encode([
            "success" => true,
            "message" => "Notification settings retrieved successfully",
            "data" => $settings
        ]);

    } elseif ($method === "PUT") {

        $input = json_decode(file_get_contents("php://input"), true);

        if (!is_array($input)) {
            http_response_code(400);
            echo json_encode([
                "success" => false,
                "message" => "Invalid request data"
            ]);
            exit;
        }

        $fields = [
            "email_notifications",
            "student_notifications",
            "fee_notifications",
            "attendance_notifications"
        ];

        $values = [];

        foreach ($fields as $field) {
            $value = $input[$field] ?? null;

            if (!in_array($value, [0, 1, true, false, "0", "1"], true)) {
                http_response_code(422);
                echo json_encode([
                    "success" => false,
                    "message" => "Invalid value for " . $field
                ]);
                exit;
            }

            $values[$field] = (int) $value;
        }

        $query = $conn->prepare("
            INSERT INTO notification_settings (
                admin_id,
                email_notifications,
                student_notifications,
                fee_notifications,
                attendance_notifications
            )
            VALUES (
                :admin_id,
                :email,
                :student,
                :fee,
                :attendance
            )
            ON DUPLICATE KEY UPDATE
                email_notifications = VALUES(email_notifications),
                student_notifications = VALUES(student_notifications),
                fee_notifications = VALUES(fee_notifications),
                attendance_notifications = VALUES(attendance_notifications)
        ");

        $query->execute([
            ":admin_id" => $adminId,
            ":email" => $values["email_notifications"],
            ":student" => $values["student_notifications"],
            ":fee" => $values["fee_notifications"],
            ":attendance" => $values["attendance_notifications"]
        ]);

        echo json_encode([
            "success" => true,
            "message" => "Notification settings updated successfully"
        ]);

    } else {

        http_response_code(405);
        echo json_encode([
            "success" => false,
            "message" => "Method not allowed"
        ]);
    }

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to process notification settings"
    ]);
}
