<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/auth_middleware.php";

try {

    if ($_SERVER["REQUEST_METHOD"] !== "PUT") {
        http_response_code(405);
        echo json_encode([
            "success" => false,
            "message" => "Only PUT method is allowed"
        ]);
        exit;
    }

    $adminData = authenticateAdmin();

    $input = json_decode(file_get_contents("php://input"), true);

    $currentPassword = $input["current_password"] ?? "";
    $newPassword = $input["new_password"] ?? "";
    $confirmPassword = $input["confirm_password"] ?? "";

    if ($currentPassword === "" || $newPassword === "" || $confirmPassword === "") {
        http_response_code(422);
        echo json_encode([
            "success" => false,
            "message" => "All password fields are required"
        ]);
        exit;
    }

    if (strlen($newPassword) < 8) {
        http_response_code(422);
        echo json_encode([
            "success" => false,
            "message" => "New password must be at least 8 characters"
        ]);
        exit;
    }

    if ($newPassword !== $confirmPassword) {
        http_response_code(422);
        echo json_encode([
            "success" => false,
            "message" => "New password and confirmation do not match"
        ]);
        exit;
    }

    $database = new Database();
    $conn = $database->connect();

    $query = $conn->prepare("
        SELECT password FROM admins
        WHERE id = :id
        LIMIT 1
    ");

    $query->execute([
        ":id" => $adminData["admin_id"]
    ]);

    $admin = $query->fetch();

    if (!$admin || !password_verify($currentPassword, $admin["password"])) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Current password is incorrect"
        ]);
        exit;
    }

    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

    $update = $conn->prepare("
        UPDATE admins
        SET password = :password
        WHERE id = :id
    ");

    $update->execute([
        ":password" => $hashedPassword,
        ":id" => $adminData["admin_id"]
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Password changed successfully"
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to change password"
    ]);
}
