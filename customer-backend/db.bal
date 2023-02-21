import ballerinax/mssql.driver as _;
import ballerinax/java.jdbc;
import ballerina/log;
import ballerina/sql;

configurable string jdbcConnectionString = ?;
configurable string username = ?;
configurable string password = ?;

public class ManagementDbClient {
    public final jdbc:Client dbClient;

    public function init() {
        log:printInfo("Initializing database client");

        jdbc:Client|error tempClient = new (jdbcConnectionString, username, password);
        if tempClient is jdbc:Client {
            log:printInfo("Successfully created database client");
            self.dbClient = tempClient;
            self.migrate();
        } else {
            log:printError("Error creating database client. Reason : ", tempClient);
            panic tempClient;
        }
    }

    public function close() {
        log:printInfo("Closing database client");
        error? e = self.dbClient.close();
        if e is error {
            log:printError("Error closing database client. Reason : ", e);
        }
    }

    public function migrate() {
        log:printInfo("Migrating database");
        sql:ExecutionResult|sql:Error queryResult = self.dbClient->execute(`
               CREATE TABLE IF NOT EXISTS users (
                id INT IDENTITY(1,1) PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description VARCHAR(255) NOT NULL,
                includes VARCHAR(255) NOT NULL,
                intended_for VARCHAR(255) NOT NULL,
                color VARCHAR(255) NOT NULL,
                material VARCHAR(255) NOT NULL,
                price float NOT NULL,
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL
            );
        `);
        if queryResult is sql:ExecutionResult {
            return log:printInfo("Migrated Successfully database");
        }

        log:printError("Error migrating database. Reason : ", queryResult);

    }

}
