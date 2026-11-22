<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/auth_middleware.php";

try {

    $adminData = authenticateAdmin();

    $database = new Database();
    $conn = $database->connect();

    $method = $_SERVER["REQUEST_METHOD"];

    if ($method === "GET") {

        $query = $conn->query("
            SELECT id, institution_name, address, phone, email, logo
            FROM institution_settings
            WHERE id = 1
            LIMIT 1
        ");

        $settings = $query->fetch();

        if (!$settings) {
            $settings = [
                "id" => 1,
                "institution_name" => "",
                "address" => "",
                "phone" => "",
                "email" => "",
                "logo" => ""
            ];
        }

        echo json_encode([
            "success" => true,
            "message" => "Institution settings retrieved successfully",
            "data" => $settings
        ]);

    } elseif ($method === "PUT") {

        $input = json_decode(file_get_contents("php://input"), true);

        $name = trim($input["institution_name"] ?? "");
        $address = trim($input["address"] ?? "");
        $phone = trim($input["phone"] ?? "");
        $email = trim($input["email"] ?? "");
        $logo = trim($input["logo"] ?? "");

        if ($name === "") {
            http_response_code(422);
            echo json_encode([
                "success" => false,
                "message" => "Institution name is required"
            ]);
            exit;
        }

        if ($email !== "" && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(422);
            echo json_encode([
                "success" => false,
                "message" => "Invalid institution email"
            ]);
            exit;
        }

        $query = $conn->prepare("
            INSERT INTO institution_settings
                (id, institution_name, address, phone, email, logo)
            VALUES
                (1, :name, :address, :phone, :email, :logo)
            ON DUPLICATE KEY UPDATE
                institution_name = VALUES(institution_name),
                address = VALUES(address),
                phone = VALUES(phone),
                email = VALUES(email),
                logo = VALUES(logo)
        ");

        $query->execute([
            ":name" => $name,
            ":address" => $address,
            ":phone" => $phone,
            ":email" => $email,
            ":logo" => $logo
        ]);

        echo json_encode([
            "success" => true,
            "message" => "Institution settings updated successfully"
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
        "message" => "Unable to process institution settings"
    ]);
}
