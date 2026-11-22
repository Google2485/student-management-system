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
            SELECT id, name, email, created_at
            FROM admins
            WHERE id = :id
            LIMIT 1
        ");

        $query->execute([":id" => $adminId]);
        $admin = $query->fetch();

        if (!$admin) {
            http_response_code(404);
            echo json_encode([
                "success" => false,
                "message" => "Admin not found"
            ]);
            exit;
        }

        echo json_encode([
            "success" => true,
            "message" => "Profile retrieved successfully",
            "data" => $admin
        ]);

    } elseif ($method === "PUT") {

        $input = json_decode(file_get_contents("php://input"), true);

        $name = trim($input["name"] ?? "");
        $email = trim($input["email"] ?? "");

        if ($name === "" || $email === "") {
            http_response_code(422);
            echo json_encode([
                "success" => false,
                "message" => "Name and email are required"
            ]);
            exit;
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(422);
            echo json_encode([
                "success" => false,
                "message" => "Invalid email address"
            ]);
            exit;
        }

        $check = $conn->prepare("
            SELECT id FROM admins
            WHERE email = :email AND id != :id
            LIMIT 1
        ");

        $check->execute([
            ":email" => $email,
            ":id" => $adminId
        ]);

        if ($check->fetch()) {
            http_response_code(409);
            echo json_encode([
                "success" => false,
                "message" => "Email already exists"
            ]);
            exit;
        }

        $query = $conn->prepare("
            UPDATE admins
            SET name = :name, email = :email
            WHERE id = :id
        ");

        $query->execute([
            ":name" => $name,
            ":email" => $email,
            ":id" => $adminId
        ]);

        echo json_encode([
            "success" => true,
            "message" => "Profile updated successfully"
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
        "message" => "Unable to process profile request"
    ]);
}
