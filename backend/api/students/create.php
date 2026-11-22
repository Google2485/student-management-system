
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    // Receive JSON data
    $data = json_decode(file_get_contents("php://input"), true);

    if (!$data) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Invalid JSON data"
        ]);
        exit;
    }

    // Required fields
    $student_id = trim($data["student_id"] ?? "");
    $name = trim($data["name"] ?? "");

    if ($student_id === "" || $name === "") {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Student ID and Name are required"
        ]);
        exit;
    }

    // Optional fields
    $email = $data["email"] ?? null;
    $phone = $data["phone"] ?? null;
    $gender = $data["gender"] ?? null;
    $address = $data["address"] ?? null;
    $admission_date = $data["admission_date"] ?? null;
    $course_id = $data["course_id"] ?? null;
    $status = $data["status"] ?? "Active";

    // Connect database
    $database = new Database();
    $conn = $database->connect();

    // Insert student
    $sql = "INSERT INTO students
        (student_id, name, email, phone, gender, address,
         admission_date, course_id, status)
        VALUES
        (:student_id, :name, :email, :phone, :gender, :address,
         :admission_date, :course_id, :status)";

    $stmt = $conn->prepare($sql);

    $stmt->execute([
        ":student_id" => $student_id,
        ":name" => $name,
        ":email" => $email ?: null,
        ":phone" => $phone ?: null,
        ":gender" => $gender ?: null,
        ":address" => $address ?: null,
        ":admission_date" => $admission_date ?: null,
        ":course_id" => $course_id ?: null,
        ":status" => $status
    ]);

    http_response_code(201);

    echo json_encode([
        "success" => true,
        "message" => "Student created successfully",
        "student_id" => $conn->lastInsertId()
    ]);

} catch (PDOException $e) {

    error_log($e->getMessage());

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Unable to create student. Check the submitted data."
    ]);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server error"
    ]);
}
