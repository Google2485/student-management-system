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
            SELECT theme
            FROM admin_preferences
            WHERE admin_id = :admin_id
            LIMIT 1
        ");

        $query->execute([":admin_id" => $adminId]);
        $preference = $query->fetch();

        $theme = $preference["theme"] ?? "light";

        echo json_encode([
            "success" => true,
            "message" => "Appearance settings retrieved successfully",
            "data" => [
                "theme" => $theme
            ]
        ]);

    } elseif ($method === "PUT") {

        $input = json_decode(file_get_contents("php://input"), true);

        $theme = $input["theme"] ?? "";

        if (!in_array($theme, ["light", "dark"], true)) {
            http_response_code(422);
            echo json_encode([
                "success" => false,
                "message" => "Theme must be light or dark"
            ]);
            exit;
        }

        $query = $conn->prepare("
            INSERT INTO admin_preferences (admin_id, theme)
            VALUES (:admin_id, :theme)
            ON DUPLICATE KEY UPDATE
                theme = VALUES(theme)
        ");

        $query->execute([
            ":admin_id" => $adminId,
            ":theme" => $theme
        ]);

        echo json_encode([
            "success" => true,
            "message" => "Appearance settings updated successfully"
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
        "message" => "Unable to process appearance settings"
    ]);
}
