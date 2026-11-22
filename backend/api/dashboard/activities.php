
<?php

require_once __DIR__ . "/../../config/cors.php";
require_once __DIR__ . "/../../config/database.php";

try {
    $database = new Database();
    $conn = $database->connect();

    $sql = "
        SELECT *
        FROM (
            SELECT
                'student' AS type,
                'New student registered' AS title,
                CONCAT(
                    s.name,
                    ' (',
                    s.student_id,
                    ') joined ',
                    COALESCE(c.name, 'a course')
                ) AS description,
                s.created_at AS activity_date
            FROM students s
            LEFT JOIN courses c ON s.course_id = c.id

            UNION ALL

            SELECT
                'payment' AS type,
                'Fee payment received' AS title,
                CONCAT(
                    s.name,
                    ' paid ',
                    FORMAT(fp.amount, 2),
                    ' for ',
                    ft.name
                ) AS description,
                fp.created_at AS activity_date
            FROM fee_payments fp
            INNER JOIN students s ON fp.student_id = s.id
            INNER JOIN fee_types ft ON fp.fee_type_id = ft.id

            UNION ALL

            SELECT
                'attendance' AS type,
                'Attendance updated' AS title,
                CONCAT(
                    s.name,
                    ' marked ',
                    a.status
                ) AS description,
                a.created_at AS activity_date
            FROM attendance a
            INNER JOIN students s ON a.student_id = s.id
        ) AS activities
        ORDER BY activity_date DESC
        LIMIT 10
    ";

    $query = $conn->query($sql);
    $activities = $query->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "success" => true,
        "message" => "Recent activities retrieved successfully",
        "data" => $activities
    ]);

} catch (Exception $e) {

    error_log($e->getMessage());

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Unable to retrieve recent activities"
    ]);
}


