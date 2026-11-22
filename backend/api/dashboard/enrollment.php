<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {

    $database = new Database();
    $conn = $database->connect();

    $query = $conn->query("
        SELECT
            DATE_FORMAT(admission_date, '%Y-%m') AS month_key,
            DATE_FORMAT(admission_date, '%b') AS month,
            COUNT(*) AS total
        FROM students
        WHERE admission_date >= DATE_SUB(
            DATE_FORMAT(CURDATE(), '%Y-%m-01'),
            INTERVAL 6 MONTH
        )
        AND admission_date <= CURDATE()
        GROUP BY DATE_FORMAT(admission_date, '%Y-%m')
        ORDER BY month_key ASC
    ");

    $results = $query->fetchAll(PDO::FETCH_ASSOC);

    $enrollment = [];

    foreach ($results as $row) {
        $enrollment[] = [
            "month" => $row["month"],
            "total" => (int) $row["total"]
        ];
    }

    echo json_encode([
        "success" => true,
        "message" => "Enrollment data retrieved successfully",
        "data" => $enrollment
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve enrollment data"
    ]);
}
