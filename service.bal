import ballerina/http;
import ballerinax/mysql;
import ballerina/time;
import ballerina/sql;

type Supplier record {
  int supplierID = -1;
  string name;
  string shortName;
  string email;
  string phoneNumber;
};

type Quotes record {
  int supplierID;
  int medicalitemID; 
  int maxQuantity; 
  int period;
  string brandName;
  int unitPrice; 
  time:Date expiraryDate; 
  string regulatoryInfo;
};

// public type aidpkg record {
//     string package_id;
//     string name;
//     string description;
//     aidpkg_status status;
// };

// public enum aidpkg_status {
//     Unfunded,
//     Partially\ Funded,
//     Fully\ Funded,
//     Awaiting\ Payment,
//     Ordered,
//     Shipped,
//     Received\ MoH,
//     Delivery\ InProgess,
//     Delivered
// }

# A service representing a network-accessible API
# bound to port `9090`.
service /admin on new http:Listener(9090) {

    # A resource for creating supplier
    # + return - suppierID
    resource function post Suppliers(@http:Payload json supplier) returns int|error {
        Supplier _supplier = check supplier.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO SUPPLIER(NAME, SHORTNAME, EMAIL, PHONENUMBER)
                                            VALUES (${_supplier.name}, ${_supplier.shortName}, ${_supplier.email}, ${_supplier.phoneNumber});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            _supplier.supplierID = <int> result.lastInsertId;

            error? e = dbClient.close();
            if e is error {
                return _supplier.supplierID;
            }
        }
        return _supplier.supplierID;
    }

    # A resource for reading all suppliers
    # + return - List of suppiers
    resource function get Suppliers() returns json|error {
        Supplier[] suppliers = [];
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            stream<Supplier, error?> resultStream = dbClient->query(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER FROM SUPPLIER`);
            check from Supplier supplier in resultStream
            do {
                suppliers.push(supplier);
            };

            error? e = dbClient.close();
            if e is error {
                return {"suppliers": suppliers}.toJson();
            }
        }
        return {"suppliers": suppliers}.toJson();
    }

    # A resource for fetching a supplier
    # + return - A supplier
    resource function get Supplier(int supplierId) returns json|error {
        Supplier? supplier = ();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            supplier = check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER FROM SUPPLIER
                                                 WHERE SUPPLIERID=${supplierId}`);

            error? e = dbClient.close();
            if e is error{
                return {};
            }
        }
        if supplier is Supplier {
            return supplier.toJson();
        }
        return {};
    }
}