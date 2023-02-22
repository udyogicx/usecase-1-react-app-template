import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/log;

type Product record {|
    string id;
    string title;
    string description;
    string includes;
    string intendedFor;
    string color;
    string material;
    float price;
|};

configurable string HOST = ?;
configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {
    private final mysql:Client db;

    function init() returns error? {
        mysql:Options mysqlOptions = {
            connectTimeout: 10,
            socketTimeout: 10,
            ssl: {
                mode: mysql:SSL_REQUIRED
            }

        };

        sql:ConnectionPool poolOptions = {
            maxOpenConnections: 2,
            minIdleConnections: 1
        };
        self.db = check new (HOST, USER, PASSWORD, DATABASE, PORT, mysqlOptions, poolOptions);
        self.migrate();
    }

    public function migrate() {
        log:printInfo("Migrating database");
        sql:ExecutionResult|sql:Error queryResult = self.db->execute(`
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

    # A resource for catalog Item
    # + id - the input string id
    # + return - string name with hello message or error
    resource function get products/[string id]() returns Product|http:NotFound|error {
        Product|sql:Error result = self.db->queryRow(`SELECT * FROM products WHERE id = ${id}`);
        if (result is sql:Error) {
            return http:NOT_FOUND;
        } else {
            return result;
        }
    }

    resource function get products() returns Product[]|error {
        stream<Product, sql:Error?> resultStream = self.db->query(`SELECT * FROM products`);
        Product[]|sql:Error? products = from var result in resultStream
            select result;
        if (products is sql:Error?) {
            return error sql:ApplicationError("Error in retrieving products");
        } else {
            return products;
        }
    }

    resource function post products(@http:Payload Product catalogItem) returns http:Created|error {
        sql:ParameterizedQuery query =
        `INSERT INTO products ('title', 'description', 'includes', intendedFor', 'color', 'material', 'price')
         VALUES (
            ${catalogItem.title},
            ${catalogItem.description},
            ${catalogItem.includes},
            ${catalogItem.intendedFor},
            ${catalogItem.color},
            ${catalogItem.material},
            ${catalogItem.price}
            )`;

        sql:ExecutionResult|sql:Error result = self.db->execute(query);
        if (result is sql:Error) {
            return result;
        } else {
            return http:CREATED;
        }
    }

    resource function patch products/[string id](@http:Payload Product catalogItem) returns http:Accepted|error {
        sql:ParameterizedQuery query =
        `UPDATE products SET
            title = ${catalogItem.title},
            description = ${catalogItem.description},
            includes = ${catalogItem.includes},
            intendedFor = ${catalogItem.intendedFor},
            color = ${catalogItem.color},
            material = ${catalogItem.material},
            price = ${catalogItem.price}
        WHERE id = ${id}`;

        sql:ExecutionResult|sql:Error result = self.db->execute(query);
        if (result is sql:Error) {
            return result;
        } else {
            return http:ACCEPTED;
        }
    }
}
