<?php
/**
 * Database Configuration & Connection Class
 * Connects to MySQL using PDO with robust error handling and UTF-8 encoding.
 */

declare(strict_types=1);

class Database {
    private static ?PDO $instance = null;

    // Default configuration for XAMPP / Localhost development
    private const DB_HOST = 'localhost';
    private const DB_PORT = '3306';
    private const DB_NAME = 'grocery_admin_db';
    private const DB_USER = 'root';
    private const DB_PASS = '';

    /**
     * Returns a singleton PDO database connection instance.
     */
    public static function getConnection(): PDO {
        if (self::$instance === null) {
            $host = getenv('DB_HOST') ?: self::DB_HOST;
            $port = getenv('DB_PORT') ?: self::DB_PORT;
            $dbname = getenv('DB_NAME') ?: self::DB_NAME;
            $user = getenv('DB_USER') ?: self::DB_USER;
            $pass = getenv('DB_PASS') !== false ? getenv('DB_PASS') : self::DB_PASS;

            $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];

            try {
                self::$instance = new PDO($dsn, $user, $pass, $options);
            } catch (PDOException $e) {
                // If API request, output JSON error
                if (str_contains($_SERVER['REQUEST_URI'] ?? '', '/api/')) {
                    header('Content-Type: application/json; charset=utf-8', true, 500);
                    echo json_encode([
                        'status' => 'error',
                        'message' => 'Database connection failure. Please ensure MySQL is running on localhost.',
                    ]);
                    exit;
                }
                
                die("<!DOCTYPE html><html><head><title>Database Error</title><style>body{font-family:system-ui,-apple-system,sans-serif;padding:40px;background:#f8fafc;color:#1e293b}.card{background:#fff;padding:24px;border-radius:12px;border:1px solid #e2e8f0;max-width:560px;margin:40px auto;box-shadow:0 4px 6px -1px rgba(0,0,0,0.1)}h2{color:#e11d48;margin-top:0}</style></head><body><div class='card'><h2>Database Connection Failed</h2><p>Could not connect to MySQL database <strong>{$dbname}</strong> on <strong>{$host}</strong>.</p><p>Please make sure MySQL is started in XAMPP Control Panel and database is imported.</p><code>" . htmlspecialchars($e->getMessage()) . "</code></div></body></html>");
            }
        }

        return self::$instance;
    }
}
