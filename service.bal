import ballerina/http;
import ballerinax/mysql;
import ballerina/sql;

# A service representing a network-accessible API
# bound to port `9090`.
service /admin on new http:Listener(9090) {

    # A resource for creating supplier
    # + return - supplierID
    resource function post Supplier(@http:Payload json supplier) returns int|error {
        Supplier _supplier = check supplier.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO SUPPLIER(NAME, SHORTNAME, EMAIL, PHONENUMBER)
                                            VALUES (${_supplier.name}, ${_supplier.shortName}, ${_supplier.email}, ${_supplier.phoneNumber});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _supplier.supplierID = <int> result.lastInsertId;
            }

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

    # A resource for creating quotation
    # + return - quoteID
    resource function post Quotation(@http:Payload json quotation) returns int|error {
        Quotation _quotation = check quotation.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO QUOTATION(SUPPLIERID, ITEMID, BRANDNAME, AVAILABLEQUANTITY, EXPIRYDATE, UNITPRICE, REGULATORYINFO)
                                            VALUES (${_quotation.supplierID}, ${_quotation.itemID}, ${_quotation.brandName}, ${_quotation.availableQuantity},
                                                    ${_quotation.expiryDate}, ${_quotation.unitPrice}, ${_quotation.regulatoryInfo});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _quotation.quotationID = <int> result.lastInsertId;
            }

            error? e = dbClient.close();
            if e is error {
                return _quotation.quotationID;
            }
        }
        return _quotation.quotationID;
    }

    # A resource for creating aidPackage
    # + return - packageID
    resource function post AidPackage(@http:Payload json aidPackage) returns int|error {
        AidPackage _aidPackage = check aidPackage.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE(NAME, DESCRIPTION, STATUS)
                                            VALUES (${_aidPackage.name}, ${_aidPackage.description}, ${_aidPackage.status});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _aidPackage.packageID = <int> result.lastInsertId;
            }

            error? e = dbClient.close();
            if e is error {
                return _aidPackage.packageID;
            }
        }
        return _aidPackage.packageID;
    }

    # A resource for modifying aidPackage
    # + return - packageID
    resource function patch AidPackage(@http:Payload json aidPackage) returns int|error {
        AidPackage _aidPackage = check aidPackage.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `UPDATE AID_PACKAGE
                                            SET
                                            NAME=COALESCE(${_aidPackage.name},NAME), 
                                            DESCRIPTION=COALESCE(${_aidPackage.description},DESCRIPTION),
                                            STATUS=COALESCE(${_aidPackage.status},STATUS)
                                            WHERE PACKAGEID=${_aidPackage.packageID};`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _aidPackage.packageID = <int> result.lastInsertId;
            }

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
            stream<AidPackage, error?> resultStream = dbClient->query(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS 
                                                                       FROM AID_PACKAGE
                                                                       WHERE ${status} IS NULL OR STATUS=${status};`);
            check from AidPackage aidPackage in resultStream
            do {
                aidPackage.aidPackageItems = [];
                aidPackages.push(aidPackage);
            };
            foreach AidPackage aidPackage in aidPackages {
                stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID, NEEDID, QUANTITY, TOTALAMOUNT 
                                                                                   FROM AID_PACKAGE_ITEM
                                                                                   WHERE PACKAGEID=${aidPackage.packageID};`);
                check from AidPackageItem aidPackageItem in resultItemStream
                do {
                    aidPackage.aidPackageItems.push(aidPackageItem);
                };
            }

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
        AidPackage aidPackage = {};
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            aidPackage = check dbClient->queryRow(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS FROM AID_PACKAGE
                                                   WHERE PACKAGEID=${packageID};`);
            stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID, NEEDID, QUANTITY, TOTALAMOUNT 
                                                                               FROM AID_PACKAGE_ITEM
                                                                               WHERE PACKAGEID=${packageID};`);
            aidPackage.aidPackageItems = [];
            check from AidPackageItem aidPackageItem in resultItemStream
            do {
                aidPackage.aidPackageItems.push(aidPackageItem);
            };
            error? e = dbClient.close();
            if e is error {
                return aidPackage.toJson();
            }
        }
        return aidPackage.toJson();
    }

    # A resource for creating aidPackageItem;
    # + return - packageItemID
    resource function post AidPackage/[int packageID]/AidPackageItem(@http:Payload json aidPackageItem) returns int|error {
        AidPackageItem _aidPackageItem = check aidPackageItem.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, QUANTITY)
                                            VALUES (${_aidPackageItem.quotationID}, ${packageID}, ${_aidPackageItem.needID}, ${_aidPackageItem.quantity});`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _aidPackageItem.packageItemID = <int> result.lastInsertId;
            }

            error? e = dbClient.close();
            if e is error {
                return _aidPackageItem.packageItemID;
            }
        }
        return _aidPackageItem.packageItemID;
    }

    # A resource for updating aidPackageItem;
    # + return - packageItemID
    resource function put AidPackage/[int packageID]/AidPackageItem(@http:Payload json aidPackageItem) returns int|error {
        AidPackageItem _aidPackageItem = check aidPackageItem.fromJsonWithType();
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, QUANTITY)
                                            VALUES (${_aidPackageItem.quotationID}, ${packageID}, ${_aidPackageItem.needID}, ${_aidPackageItem.quantity})
                                            ON DUPLICATE KEY UPDATE 
                                            QUANTITY=COALESCE(${_aidPackageItem.quantity}, QUANTITY);`;
            sql:ExecutionResult result = check dbClient->execute(query);
            if result.lastInsertId is int {
                _aidPackageItem.packageItemID = <int> result.lastInsertId;
            }

            error? e = dbClient.close();
            if e is error {
                return _aidPackageItem.packageItemID;
            }
        }
        return _aidPackageItem.packageItemID;
    }

    # A resource for reading all medicalNeedInfo
    # + return - List of medicalNeedInfo
    resource function get medicalNeedInfo() returns json|error {
        MedicalNeedInfo[] medicalNeedInfo = [];
        mysql:Client|sql:Error dbClient = new (dbHost, dbUser, dbPass, db, dbPort);

        if dbClient is mysql:Client {
            stream<MedicalNeedInfo, error?> resultStream = dbClient->query(`SELECT NEEDID, PERIOD, URGENCY
                                                                            FROM MEDICAL_NEED;`);
            check from MedicalNeedInfo info in resultStream
            do {
                info.supplierQuotes = [];
                medicalNeedInfo.push(info);
            };
            foreach MedicalNeedInfo info in medicalNeedInfo {
                Beneficiary beneficiary = check dbClient->queryRow(`SELECT B.BENEFICIARYID, B.NAME, B.SHORTNAME, B.EMAIL, B.PHONENUMBER 
                                                                     FROM BENEFICIARY B RIGHT JOIN MEDICAL_NEED M 
                                                                     ON B.BENEFICIARYID=M.BENEFICIARYID
                                                                     WHERE M.NEEDID=${info.needID};`);
                info.beneficiary = beneficiary;

                stream<Quotation, error?> resultQuotationStream = dbClient->query(`SELECT QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                                                   AVAILABLEQUANTITY, EXPIRYDATE,
                                                                                   UNITPRICE, REGULATORYINFO
                                                                                   FROM QUOTATION;`);
                check from Quotation quotation in resultQuotationStream
                do {
                    info.supplierQuotes.push(quotation);
                };

                foreach Quotation quotation in info.supplierQuotes {
                    Supplier supplier = check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER 
                                                                   FROM SUPPLIER
                                                                   WHERE SUPPLIERID=${quotation.supplierID};`);
                    quotation.supplier = supplier;
                }
            }

            error? e = dbClient.close();
            if e is error {
                return {"medicalNeedInfo": medicalNeedInfo}.toJson();
            }
        }
        return {"medicalNeedInfo": medicalNeedInfo}.toJson();
    }
}