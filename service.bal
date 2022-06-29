import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;

final mysql:Client dbClient = check new (dbHost, dbUser, dbPass, db, dbPort);

# A service representing a network-accessible API bound to port `9090`.
service /admin on new http:Listener(9090) {

    # A resource for reading all MedicalNeedInfo
    # + return - List of MedicalNeedInfo
    resource function get medicalNeedInfo() returns MedicalNeedInfo[]|error {
        MedicalNeedInfo[] medicalNeedInfo = [];
        stream<MedicalNeedInfo, error?> resultStream = dbClient->query(`SELECT I.NAME, I.ITEMID, NEEDID, PERIOD, URGENCY,
                                                                        NEEDEDQUANTITY, REMAININGQUANTITY
                                                                        FROM MEDICAL_NEED N
                                                                        LEFT JOIN MEDICAL_ITEM I ON I.ITEMID=N.ITEMID;`);
        check from MedicalNeedInfo info in resultStream
            do {
                medicalNeedInfo.push(info);
            };
        foreach MedicalNeedInfo info in medicalNeedInfo {
            info.period.day = 1;
            info.supplierQuotes = [];
            info.beneficiary = check dbClient->queryRow(`SELECT B.BENEFICIARYID, B.NAME, B.SHORTNAME, B.EMAIL, 
                                                        B.PHONENUMBER 
                                                        FROM BENEFICIARY B RIGHT JOIN MEDICAL_NEED M 
                                                        ON B.BENEFICIARYID=M.BENEFICIARYID
                                                        WHERE M.NEEDID=${info.needID};`);
            stream<Quotation, error?> resultQuotationStream = dbClient->query(`SELECT QUOTATIONID, SUPPLIERID,
                BRANDNAME, AVAILABLEQUANTITY, PERIOD,EXPIRYDATE, UNITPRICE, REGULATORYINFO
                FROM QUOTATION Q
                WHERE YEAR(Q.PERIOD)=${info.period.year} AND MONTH(Q.PERIOD)=${info.period.month} AND Q.ITEMID=${info.itemID};`);
            check from Quotation quotation in resultQuotationStream
                do {
                    info.supplierQuotes.push(quotation);
                };
            foreach Quotation quotation in info.supplierQuotes {
                quotation.supplier = check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER 
                                                               FROM SUPPLIER
                                                               WHERE SUPPLIERID=${quotation.supplierID}`);
            }
        }
        return medicalNeedInfo;
    }

    # A resource for creating Supplier
    # + return - Supplier
    resource function post Supplier(@http:Payload Supplier supplier) returns Supplier|error {
        sql:ParameterizedQuery query = `INSERT INTO SUPPLIER(NAME, SHORTNAME, EMAIL, PHONENUMBER)
                                        VALUES (${supplier.name}, ${supplier.shortName},
                                                ${supplier.email}, ${supplier.phoneNumber});`;
        sql:ExecutionResult result = check dbClient->execute(query);
        supplier.supplierID = <int>result.lastInsertId;
        return supplier;
    }

    # A resource for reading all Suppliers
    # + return - List of Suppliers
    resource function get Suppliers() returns Supplier[]|error {
        Supplier[] suppliers = [];
        stream<Supplier, error?> resultStream = dbClient->query(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER 
                                                                 FROM SUPPLIER`);
        check from Supplier supplier in resultStream
            do {
                suppliers.push(supplier);
            };
        return suppliers;
    }

    # A resource for fetching a Supplier
    # + return - A Supplier
    resource function get Supplier(int supplierId) returns Supplier|error {
        Supplier supplier = check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER FROM SUPPLIER
                                                      WHERE SUPPLIERID=${supplierId}`);
        return supplier;
    }

    # A resource for creating Quotation
    # + return - Quotation
    resource function post Quotation(@http:Payload Quotation quotation) returns Quotation|error {
        quotation.period.day = 1;
        sql:ParameterizedQuery query = `INSERT INTO QUOTATION(SUPPLIERID, ITEMID, BRANDNAME, AVAILABLEQUANTITY, PERIOD,
                                        EXPIRYDATE, UNITPRICE, REGULATORYINFO)
                                        VALUES (${quotation.supplierID}, ${quotation.itemID}, ${quotation.brandName},
                                                ${quotation.availableQuantity}, ${quotation.period},
                                                ${quotation.expiryDate}, ${quotation.unitPrice}, ${quotation.regulatoryInfo});`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            quotation.quotationID = <int>result.lastInsertId;
        }
        quotation.supplier = check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER FROM SUPPLIER
                                                       WHERE SUPPLIERID=${quotation.supplierID}`);
        return quotation;
    }

    # A resource for reading all Aid-Packages
    # + return - List of Aid-Packages and optionally filter by status
    resource function get AidPackages(string? status) returns AidPackage[]|error {
        AidPackage[] aidPackages = [];
        stream<AidPackage, error?> resultStream = dbClient->query(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS 
                                                                    FROM AID_PACKAGE
                                                                    WHERE ${status} IS NULL OR STATUS=${status};`);
        check from AidPackage aidPackage in resultStream
            do {
                aidPackages.push(aidPackage);
            };
        foreach AidPackage aidPackage in aidPackages {
            aidPackage.aidPackageItems = [];
            stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID,
                                                                               NEEDID, QUANTITY, TOTALAMOUNT 
                                                                               FROM AID_PACKAGE_ITEM
                                                                               WHERE PACKAGEID=${aidPackage.packageID};`);
            check from AidPackageItem aidPackageItem in resultItemStream
                do {
                    aidPackage.aidPackageItems.push(aidPackageItem);
                };
            foreach AidPackageItem? aidPackageItem in aidPackage.aidPackageItems {
                if aidPackageItem is AidPackageItem {
                    aidPackageItem.quotation = check dbClient->queryRow(`SELECT
                                                                        QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                                        AVAILABLEQUANTITY, PERIOD, EXPIRYDATE,
                                                                        UNITPRICE, REGULATORYINFO
                                                                        FROM QUOTATION 
                                                                        WHERE QUOTATIONID=${aidPackageItem.quotationID}`);
                }
            }
        }
        return aidPackages;
    }

    # A resource for fetching an Aid-Package
    # + return - Aid-Package
    resource function get AidPackage(int packageID) returns AidPackage|error {
        AidPackage aidPackage = check dbClient->queryRow(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS FROM AID_PACKAGE
                                                          WHERE PACKAGEID=${packageID};`);
        stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID,
                                                                           NEEDID, QUANTITY, TOTALAMOUNT 
                                                                           FROM AID_PACKAGE_ITEM
                                                                           WHERE PACKAGEID=${packageID};`);
        aidPackage.aidPackageItems = [];
        check from AidPackageItem aidPackageItem in resultItemStream
            do {
                aidPackage.aidPackageItems.push(aidPackageItem);
            };
        foreach AidPackageItem? aidPackageItem in aidPackage.aidPackageItems {
            if aidPackageItem is AidPackageItem {
                aidPackageItem.quotation = check dbClient->queryRow(`SELECT
                                                                    QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                                    AVAILABLEQUANTITY, PERIOD, EXPIRYDATE,
                                                                    UNITPRICE, REGULATORYINFO
                                                                    FROM QUOTATION 
                                                                    WHERE QUOTATIONID=${aidPackageItem.quotationID}`);
            }
        }
        return aidPackage;
    }

    # A resource for creating Aid-Package
    # + return - Aid-Package
    resource function post AidPackage(@http:Payload AidPackage aidPackage) returns AidPackage|error {
        sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE(NAME, DESCRIPTION, STATUS)
                                        VALUES (${aidPackage.name}, ${aidPackage.description}, ${aidPackage.status});`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            aidPackage.packageID = <int>result.lastInsertId;
        }
        return aidPackage;
    }

    # A resource for modifying Aid-Package
    # + return - Aid-Package
    resource function patch AidPackage(@http:Payload AidPackage aidPackage) returns AidPackage|error {
        sql:ParameterizedQuery query = `UPDATE AID_PACKAGE
                                        SET
                                        NAME=COALESCE(${aidPackage.name},NAME), 
                                        DESCRIPTION=COALESCE(${aidPackage.description},DESCRIPTION),
                                        STATUS=COALESCE(${aidPackage.status},STATUS)
                                        WHERE PACKAGEID=${aidPackage.packageID};`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            aidPackage.packageID = <int>result.lastInsertId;
        }
        stream<AidPackageItem, error?> resultItemStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID,
                                                                           NEEDID, QUANTITY, TOTALAMOUNT 
                                                                           FROM AID_PACKAGE_ITEM
                                                                           WHERE PACKAGEID=${aidPackage.packageID};`);
        aidPackage.aidPackageItems = [];
        check from AidPackageItem aidPackageItem in resultItemStream
            do {
                aidPackage.aidPackageItems.push(aidPackageItem);
            };
        foreach AidPackageItem? aidPackageItem in aidPackage.aidPackageItems {
            if aidPackageItem is AidPackageItem {
                aidPackageItem.quotation = check dbClient->queryRow(`SELECT
                                                                    QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                                    AVAILABLEQUANTITY, PERIOD, EXPIRYDATE,
                                                                    UNITPRICE, REGULATORYINFO
                                                                    FROM QUOTATION 
                                                                    WHERE QUOTATIONID=${aidPackageItem.quotationID}`);
            }
        }
        return aidPackage;
    }

    # A resource for creating AidPackage-Item
    # + return - AidPackage-Item
    resource function post AidPackage/[int packageID]/AidPackageItem(@http:Payload AidPackageItem aidPackageItem)
                                                                    returns AidPackageItem|error {
        aidPackageItem.packageID = packageID;
        sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, QUANTITY)
                                        VALUES (${aidPackageItem.quotationID}, ${aidPackageItem.packageID},
                                                ${aidPackageItem.needID}, ${aidPackageItem.quantity});`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            aidPackageItem.packageItemID = <int>result.lastInsertId;
        }
        query = `UPDATE MEDICAL_NEED
                 SET REMAININGQUANTITY=NEEDEDQUANTITY-(SELECT SUM(QUANTITY) FROM AID_PACKAGE_ITEM WHERE NEEDID=${aidPackageItem.needID})
                 WHERE NEEDID=${aidPackageItem.needID};`;
        _ = check dbClient->execute(query);
        aidPackageItem.quotation = check dbClient->queryRow(`SELECT
                                                            QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                            AVAILABLEQUANTITY, PERIOD, EXPIRYDATE,
                                                            UNITPRICE, REGULATORYINFO
                                                            FROM QUOTATION 
                                                            WHERE QUOTATIONID=${aidPackageItem.quotationID}`);
        return aidPackageItem;
    }

    # A resource for updating AidPackage-Item
    # + return - AidPackage-Item
    resource function put AidPackage/[int packageID]/AidPackageItem(@http:Payload AidPackageItem aidPackageItem)
                                                                    returns AidPackageItem|error {
        aidPackageItem.packageID = packageID;
        sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, QUANTITY)
                                        VALUES (${aidPackageItem.quotationID}, ${aidPackageItem.packageID},
                                                ${aidPackageItem.needID}, ${aidPackageItem.quantity})
                                        ON DUPLICATE KEY UPDATE 
                                        QUANTITY=COALESCE(${aidPackageItem.quantity}, QUANTITY);`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            aidPackageItem.packageItemID = <int>result.lastInsertId;
        }
        query = `UPDATE MEDICAL_NEED
                 SET REMAININGQUANTITY=NEEDEDQUANTITY-(SELECT SUM(QUANTITY) FROM AID_PACKAGE_ITEM WHERE NEEDID=${aidPackageItem.needID})
                 WHERE NEEDID=${aidPackageItem.needID};`;
        _ = check dbClient->execute(query);
        aidPackageItem.quotation = check dbClient->queryRow(`SELECT
                                                            QUOTATIONID, SUPPLIERID, BRANDNAME,
                                                            AVAILABLEQUANTITY, PERIOD, EXPIRYDATE,
                                                            UNITPRICE, REGULATORYINFO
                                                            FROM QUOTATION 
                                                            WHERE QUOTATIONID=${aidPackageItem.quotationID}`);
        return aidPackageItem;
    }

    # A resource for fetching all comments of an Aid-Package
    # + return - list of AidPackageUpdateComments
    resource function get AidPackage/UpdateComments(int packageID) returns AidPackageUpdate[]|error {
        AidPackageUpdate[] aidPackageUpdates = [];
        stream<AidPackageUpdate, error?> resultStream = dbClient->query(`SELECT
                                                PACKAGEID, PACKAGEUPDATEID, UPDATECOMMENT, DATETIME 
                                                FROM AID_PACKAGAE_UPDATE
                                                WHERE PACKAGEID=${packageID};`);
        check from AidPackageUpdate aidPackageUpdate in resultStream
            do {
                aidPackageUpdates.push(aidPackageUpdate);
            };
        return aidPackageUpdates;
    }

    # A resource for saving update with a comment to an aidPackage
    # + return - aidPackageUpdateId
    resource function put AidPackage/[int packageID]/UpdateComment(@http:Payload AidPackageUpdate aidPackageUpdate)
                                                                returns AidPackageUpdate?|error {
        aidPackageUpdate.packageID = packageID;
        sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGAE_UPDATE(PACKAGEID, PACKAGEUPDATEID, UPDATECOMMENT, DATETIME)
                                        VALUES (${aidPackageUpdate.packageID},
                                                IFNULL(${aidPackageUpdate.packageUpdateId}, DEFAULT(PACKAGEUPDATEID)),
                                                ${aidPackageUpdate.updateComment},
                                                FROM_UNIXTIME(${time:utcNow()[0]})
                                        ) ON DUPLICATE KEY UPDATE
                                        DATETIME=FROM_UNIXTIME(COALESCE(${time:utcNow()[0]}, DATETIME)),
                                        UPDATECOMMENT=COALESCE(${aidPackageUpdate.updateComment}, UPDATECOMMENT);`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.lastInsertId is int {
            aidPackageUpdate.packageUpdateId = <int>result.lastInsertId;
        }
        aidPackageUpdate.dateTime = check dbClient->queryRow(`SELECT DATETIME 
                                                              FROM AID_PACKAGAE_UPDATE
                                                              WHERE PACKAGEUPDATEID=${aidPackageUpdate.packageUpdateId};`);
        return aidPackageUpdate;
    }
}
