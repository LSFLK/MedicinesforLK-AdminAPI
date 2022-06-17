import ballerina/http;
import ballerinax/mysql;
import ballerina/sql;

# A service representing a network-accessible API
# bound to port `9090`.
service /admin on new http:Listener(9090) {

    # A resource for creating supplier
    # + return - supplierID
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
    # + return - List of suppliers
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

    # A resource for creating quote
    # + return - quoteID
    resource function post Quotation(@http:Payload json quotation) returns int|error {
        Quotation _quotation = check quotation.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO QUOTATION(SUPPLIERID, ITEMID, BRANDNAME, AVAILABLEQTY, EXPIRYDATE, UNITPRICE, REGULATORYINFO)
                                            VALUES (${_quotation.supplierID}, ${_quotation.itemID}, ${_quotation.brandName}, ${_quotation.availableQuantity}
                                                    ${_quotation.expiryDate}, ${_quotation.unitPrice}, ${_quotation.regulatoryInfo})`;
            sql:ExecutionResult result = check dbClient->execute(query);
            _quotation.quotationID = <int> result.lastInsertId;

            error? e = dbClient.close();
            if e is error {
                return _quotation.quotationID;
            }
        }
        return _quotation.quotationID;
    }

    # A resource for creating aid-package;
    # + return - packageID
    resource function post AidPackages(@http:Payload json aidPackage) returns int|error {
        AidPackage _aidPackage = check aidPackage.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE(NAME, DESCRIPTION, STATUS)
                                            VALUES (${_aidPackage.name}, ${_aidPackage.description}, ${_aidPackage.status});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            _aidPackage.packageID = <int> result.lastInsertId;

            error? e = dbClient.close();
            if e is error {
                return _aidPackage.packageID;
            }
        }
        return _aidPackage.packageID;
    }

    # A resource for reading all aidPackages
    # + return - List of aidPackages and optionally filter by status
    resource function get AidPackages(string? status) returns json|error {
        AidPackage[] aidPackages = [];
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            stream<AidPackage, error?> resultStream = dbClient->query(`SELECT NAME, DESCRIPTION, STATUS FROM AID_PACKAGE WHERE ${status} IS NULL OR STATUS=${status};`);
            check from AidPackage aidPackage in resultStream
            do {
                aidPackages.push(aidPackage);
            };

            error? e = dbClient.close();
            if e is error {
                return {"aidPackages": aidPackages}.toJson();
            }
        }
        return {"aidPackages": aidPackages}.toJson();
    }

    # A resource for fetching an aidPackage
    # + return - An aidPackage
    resource function get AidPackage(int packageID) returns json|error {
        AidPackage? aidPackage = ();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            aidPackage = check dbClient->queryRow(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS FROM AID_PACKAGE WHERE PACKAGEID=${packageID};`);

            error? e = dbClient.close();
            if e is error {
                return aidPackage.toJson();
            }
        }
        return aidPackage.toJson(); //OBJECTS
    }

    # A resource for creating aidPackage;
    # + return - packageID
    resource function post AidPackage/[int packageID]/AidPackageItem(@http:Payload json aidPackageItem) returns int|error {
        AidPackageItem _aidPackageItem = check aidPackageItem.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, QTY)
                                            VALUES (${_aidPackageItem.quotationID}, ${packageID}, ${_aidPackageItem.needID}, ${_aidPackageItem.quantity});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            _aidPackageItem.packageItemID = <int> result.lastInsertId;

            error? e = dbClient.close();
            if e is error {
                return _aidPackageItem.packageItemID;
            }
        }
        return _aidPackageItem.packageItemID;
    }
}