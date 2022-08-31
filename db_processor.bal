import ballerina/sql;
import ballerina/time;
import ballerina/log;

const TIME_ZONE = "Asia/Colombo";

//Medical Needs
function getMedicalNeeds() returns MedicalNeed[]|error {
    MedicalNeed[] medicalNeeds = [];
    stream<MedicalNeed, error?> resultStream = dbClient->query(`SELECT ITEMID, NEEDID, PERIOD, URGENCY, NEEDEDQUANTITY, 
                                                                BENEFICIARYID, REMAININGQUANTITY FROM MEDICAL_NEED;`);
    check from MedicalNeed medicalNeed in resultStream
        do {
            medicalNeeds.push(medicalNeed);
        };
    check resultStream.close();
    return medicalNeeds;
}

//Medical Need
function getMedicalNeed(int needId) returns MedicalNeed|error {
    return check dbClient->queryRow(`SELECT ITEMID, NEEDID, PERIOD, URGENCY, NEEDEDQUANTITY, BENEFICIARYID, REMAININGQUANTITY FROM MEDICAL_NEED WHERE NEEDID=${needId}`);
}

//Medical Item
function getMedicalItem(int itemId) returns MedicalItem|error {
    return check dbClient->queryRow(`SELECT ITEMID, NAME, TYPE, UNIT FROM MEDICAL_ITEM WHERE ITEMID=${itemId}`);
}

function getMedicalItemId(string itemName) returns int|error {
    return check dbClient->queryRow(`SELECT ITEMID FROM MEDICAL_ITEM WHERE NAME=${itemName};`);
}

//Beneficiary
function getBeneficiary(int beneficiaryId) returns Beneficiary|error {
    return check dbClient->queryRow(`SELECT BENEFICIARYID, NAME, SHORTNAME, EMAIL, PHONENUMBER FROM BENEFICIARY 
                                     WHERE BENEFICIARYID=${beneficiaryId}`);
}

function getBeneficiaryId(string beneficiaryName) returns int|error {
    return check dbClient->queryRow(`SELECT BENEFICIARYID FROM BENEFICIARY WHERE NAME=${beneficiaryName};`);
}

//Supplier
function getSupplier(int supplierId) returns Supplier|error {
    return check dbClient->queryRow(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER 
                                        FROM SUPPLIER WHERE SUPPLIERID=${supplierId}`);
}

function getSupplierId(string shortName) returns int|error {
    return check dbClient->queryRow(`SELECT SUPPLIERID FROM SUPPLIER WHERE SHORTNAME=${shortName};`);
}

function getSuppliers() returns Supplier[]|error {
    Supplier[] suppliers = [];
    stream<Supplier, error?> resultStream = dbClient->query(`SELECT SUPPLIERID, NAME, SHORTNAME, EMAIL, PHONENUMBER 
                                                                 FROM SUPPLIER`);
    check from Supplier supplier in resultStream
        do {
            suppliers.push(supplier);
        };
    check resultStream.close();
    return suppliers;
}

function addSupplier(Supplier supplier) returns Supplier|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO SUPPLIER(NAME, SHORTNAME, EMAIL, PHONENUMBER)
                                        VALUES (${supplier.name}, ${supplier.shortName},
                                                ${supplier.email}, ${supplier.phoneNumber});`);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        supplier.supplierID = lastInsertedID;
    }
    return supplier;
}

//Quotation
function getQuotation(int quotationId) returns Quotation|error {
    return check dbClient->queryRow(`SELECT QUOTATIONID, SUPPLIERID, ITEMID, BRANDNAME, AVAILABLEQUANTITY, REMAININGQUANTITY, PERIOD, EXPIRYDATE,
                                        UNITPRICE, REGULATORYINFO FROM QUOTATION  WHERE QUOTATIONID=${quotationId}`);
}

function addQuotation(Quotation quotation) returns int|error {
    int quotationId = -1;
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO QUOTATION(SUPPLIERID, ITEMID, BRANDNAME, 
                                        AVAILABLEQUANTITY, REMAININGQUANTITY, PERIOD, EXPIRYDATE, UNITPRICE, REGULATORYINFO)
                                        VALUES (${quotation.supplierID}, ${quotation.itemID}, ${quotation.brandName},
                                        ${quotation.availableQuantity}, ${quotation.remainingQuantity}, ${quotation.period},
                                        ${quotation.expiryDate}, ${quotation.unitPrice}, ${quotation.regulatoryInfo});`);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        quotationId = lastInsertedID;
    }
    return quotationId;
}

function getMatchingQuotatonsForMedicalNeed(MedicalNeed medicalNeed) returns Quotation[]|error {
    Quotation[] quotations = [];
    stream<Quotation, error?> resultQuotationStream = dbClient->query(`SELECT QUOTATIONID, SUPPLIERID,
                                                                                BRANDNAME, AVAILABLEQUANTITY, REMAININGQUANTITY, PERIOD,
                                                                                EXPIRYDATE, UNITPRICE, REGULATORYINFO
                                                                                FROM QUOTATION Q
                                                                                WHERE YEAR(Q.PERIOD)=${medicalNeed.period.year} 
                                                                                AND MONTH(Q.PERIOD)=${medicalNeed.period.month} 
                                                                                AND Q.ITEMID=${medicalNeed.itemID};`);
    check from Quotation quotation in resultQuotationStream
        do {
            quotation.supplier = check getSupplier(quotation.supplierID);
            quotations.push(quotation);
        };
    check resultQuotationStream.close();
    return quotations;
}

//Pledge
function getPledges(int? packageId = ()) returns Pledge[]|error {
    Pledge[] pledges = [];
    sql:ParameterizedQuery query = `SELECT PLEDGEID, PACKAGEID, DONORID, AMOUNT, STATUS FROM PLEDGE`;
    if packageId is int {
        query = sql:queryConcat(query, ` WHERE PACKAGEID=${packageId}`);
    }
    stream<Pledge, error?> resultStream = dbClient->query(query);
    check from Pledge pledge in resultStream
        do {
            Donor? donor = check getDonor(pledge.donorID);
            if donor is Donor {
                pledge.donor = donor;
            }
            pledges.push(pledge);
        };
    check resultStream.close();
    return pledges;
}

function getPledge(int pledgeId) returns Pledge|error {
    Pledge pledge = check dbClient->queryRow(`SELECT PLEDGEID, PACKAGEID, DONORID, AMOUNT, STATUS 
                                                                     FROM PLEDGE WHERE PLEDGEID=${pledgeId};`);
    Donor? donor = check getDonor(pledge.donorID);
    if donor is Donor {
        pledge.donor = donor;
    }
    return pledge;
}

function updatePledge(string status, int pledgeId) returns Pledge|error {
    _ = check dbClient->execute(`UPDATE PLEDGE SET STATUS = ${status} WHERE PLEDGEID=${pledgeId};`);
    return getPledge(pledgeId);
}

function deletePledge(int pledgeId) returns error? {
    _ = check dbClient->execute(`DELETE FROM PLEDGE_UPDATE WHERE PLEDGEID=${pledgeId}`);
    _ = check dbClient->execute(`DELETE FROM PLEDGE WHERE PLEDGEID=${pledgeId};`);
}

//Pledge update
function getPledgeUpdates(int pledgeId) returns PledgeUpdate[]|error {
    PledgeUpdate[] pledgeUpdates = [];
    stream<PledgeUpdate, error?> resultStream = dbClient->query(`SELECT PLEDGEID, PLEDGEUPDATEID, UPDATECOMMENT, DATETIME 
                                                                     FROM PLEDGE_UPDATE WHERE PLEDGEID=${pledgeId};`);
    check from PledgeUpdate pledgeUpdate in resultStream
        do {
            pledgeUpdates.push(pledgeUpdate);
        };
    check resultStream.close();
    return pledgeUpdates;
}

function getPledgeUpdateLUT(int? pledgeUpdateId) returns string|error {
    return check dbClient->queryRow(`SELECT DATETIME FROM PLEDGE_UPDATE WHERE PLEDGEUPDATEID=${pledgeUpdateId};`);
}

function deletePledgeUpdate(int pledgeId, int pledgeUpdateId) returns error? {
    _ = check dbClient->execute(`DELETE FROM PLEDGE_UPDATE WHERE PLEDGEID=${pledgeId} 
                                 AND PLEDGEUPDATEID=${pledgeUpdateId};`);
}

function insertOrUpdatePledgeUpdate(PledgeUpdate pledgeUpdate) returns error? {
    int currentTime = getEpoch();
    sql:ParameterizedQuery query = `INSERT INTO PLEDGE_UPDATE(PLEDGEID, PLEDGEUPDATEID, UPDATECOMMENT, DATETIME)
                                        VALUES (${pledgeUpdate.pledgeID},
                                                IFNULL(${pledgeUpdate.pledgeUpdateID}, DEFAULT(PLEDGEUPDATEID)),
                                                ${pledgeUpdate.updateComment},
                                                FROM_UNIXTIME(${currentTime})
                                        ) ON DUPLICATE KEY UPDATE
                                        DATETIME=FROM_UNIXTIME(COALESCE(${currentTime}, DATETIME)),
                                        UPDATECOMMENT=COALESCE(${pledgeUpdate.updateComment}, UPDATECOMMENT);`;
    sql:ExecutionResult result = check dbClient->execute(query);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        pledgeUpdate.pledgeUpdateID = lastInsertedID;
    }
}

function getAidPackage(int packageId) returns AidPackage|error {
    AidPackage aidPackage = check dbClient->queryRow(`SELECT PACKAGEID, NAME, DESCRIPTION, STATUS, UNIX_TIMESTAMP(DATETIME) as 'dateTime', DONORID, CREATEDBY as 'createdBy' FROM AID_PACKAGE
                                                          WHERE PACKAGEID=${packageId};`);
    return aidPackage;
}

//Aid Package
function getAidPackages(string? status) returns AidPackage[]|error {
    AidPackage[] aidPackages = [];
    sql:ParameterizedQuery query = `SELECT PACKAGEID, NAME, DESCRIPTION, STATUS, UNIX_TIMESTAMP(DATETIME) as 'dateTime', DONORID, CREATEDBY as 'createdBy' FROM AID_PACKAGE`;
    if (status is string) {
        query = sql:queryConcat(query, ` WHERE STATUS=${status}`);
    }
    query = sql:queryConcat(query, ` ORDER BY PACKAGEID DESC`);
    stream<AidPackage, error?> resultStream = dbClient->query(query);
    check from AidPackage aidPackage in resultStream
        do {
            aidPackages.push(aidPackage);
        };
    check resultStream.close();
    return aidPackages;
}

function addAidPackage(AidPackage aidPackage, string createdBy) returns int|error {
    int packageId = -1;
    int currentTime = getEpoch();
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO AID_PACKAGE(NAME, DESCRIPTION, STATUS, DATETIME, DONORID, CREATEDBY)
                                        VALUES (${aidPackage.name}, ${aidPackage.description}, ${aidPackage.status}, FROM_UNIXTIME(${currentTime}), ${aidPackage.donorId}, ${createdBy});`);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        packageId = lastInsertedID;
    }
    return packageId;
}

function updateAidPackage(AidPackage aidPackage) returns error? {
    _ = check dbClient->execute(`UPDATE AID_PACKAGE SET
                                        NAME=COALESCE(${aidPackage.name},NAME), 
                                        DESCRIPTION=COALESCE(${aidPackage.description},DESCRIPTION),
                                        STATUS=COALESCE(${aidPackage.status},STATUS)
                                        WHERE PACKAGEID=${aidPackage.packageID};`);
}

function constructAidPackageData(AidPackage aidPackage) returns error? {
    int? packageId = aidPackage.packageID;
    if (packageId is ()) {
        return error("Invalid aid package item id on construct aid package data");
    }
    aidPackage.aidPackageItems = check getAidPackageItems(packageId);
    decimal totalAmount = 0;
    foreach AidPackageItem aidPackageItem in aidPackage.aidPackageItems {
        Quotation quotation = check getQuotation(aidPackageItem.quotationID);
        quotation.supplier = check getSupplier(quotation.supplierID);
        MedicalNeed medicalNeed = check getMedicalNeed(aidPackageItem.needID);
        aidPackageItem.period = medicalNeed.period;
        aidPackageItem.period.day = 1;
        aidPackageItem.quotation = quotation;
        aidPackageItem.totalAmount = <decimal>aidPackageItem.quantity * quotation.unitPrice;
        totalAmount = totalAmount + aidPackageItem.totalAmount;
    }
    aidPackage.goalAmount = totalAmount;
    aidPackage.receivedAmount = check getReceivedAmount(packageId);
}

//Aid Package Item
function getAidPackageItems(int packageId) returns AidPackageItem[]|error {
    AidPackageItem[] aidPackageItems = [];
    stream<AidPackageItem, error?> resultStream = dbClient->query(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID,
                                                                               NEEDID, INITIALQUANTITY, QUANTITY, TOTALAMOUNT 
                                                                               FROM AID_PACKAGE_ITEM
                                                                               WHERE PACKAGEID=${packageId};`);
    check from AidPackageItem aidPackageItem in resultStream
        do {
            aidPackageItems.push(aidPackageItem);
        };
    check resultStream.close();
    return aidPackageItems;
}

//Aid Package Item
function getAidPackageItem(int packageItemId) returns AidPackageItem|error {

    return dbClient->queryRow(`SELECT PACKAGEITEMID, PACKAGEID, QUOTATIONID,
                                NEEDID, INITIALQUANTITY, QUANTITY, TOTALAMOUNT 
                                FROM AID_PACKAGE_ITEM
                                WHERE PACKAGEITEMID=${packageItemId};`);
}

function addAidPackageItem(AidPackageItem aidPackageItem) returns int|error {
    int aidPackageItemId = -1;
    sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, NEEDID, INITIALQUANTITY, QUANTITY,TOTALAMOUNT)
                                        VALUES (${aidPackageItem.quotationID}, ${aidPackageItem.packageID},
                                        ${aidPackageItem.needID}, ${aidPackageItem.quantity}, ${aidPackageItem.quantity}, ${aidPackageItem.totalAmount});`;
    sql:ExecutionResult result = check dbClient->execute(query);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        aidPackageItemId = lastInsertedID;
    }
    return aidPackageItemId;
}

function constructAidPAckageItem(int packageId, AidPackageItem aidPackageItem) returns error? {
    Quotation quotation = check getQuotation(aidPackageItem.quotationID);
    aidPackageItem.quotation = quotation;
    aidPackageItem.packageID = packageId;
    aidPackageItem.totalAmount = <decimal>aidPackageItem.quantity * quotation.unitPrice;
    aidPackageItem.packageItemID = check addAidPackageItem(aidPackageItem);
    check updateMedicalNeedQuantity(aidPackageItem.needID);
    check updateQuotationRemainingQuantity(aidPackageItem);
}

function deleteAidPackageItem(int packageId, int packageItemId) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`DELETE AID_PACKAGE_ITEM FROM AID_PACKAGE_ITEM INNER JOIN AID_PACKAGE ON
    AID_PACKAGE_ITEM.PACKAGEID=AID_PACKAGE.PACKAGEID WHERE
    AID_PACKAGE_ITEM.PACKAGEID=${packageId} AND PACKAGEITEMID=${packageItemId} AND (STATUS="Draft" OR STATUS="Published");`);
    if result.affectedRowCount != 1 {
        AidPackage aidPackage = check getAidPackage(packageId);
        if aidPackage.status != "Draft" && aidPackage.status != "Published" {
            return error("Can't delete items from package in " + (aidPackage.status ?: "()") + " status");
        }
        return error("Couldn't delete package");
    } 
}

function deleteAidPackage(int packageId) returns error? {
    _ = check dbClient->execute(`DELETE FROM AID_PACKAGE WHERE PACKAGEID=${packageId};`);
}

function insertOrUpdateAidPackageItem(AidPackageItem aidPackageItem) returns error? {
    AidPackage aidPackage = check getAidPackage(<int>aidPackageItem.packageID);
    Quotation quotation = check getQuotation(aidPackageItem.quotationID);
    aidPackageItem.quotation = quotation;
    aidPackageItem.totalAmount = <decimal>aidPackageItem.quantity * quotation.unitPrice;
    if aidPackage.status != "Draft" && aidPackage.status != "Published" {
        return error("Can't edit items in package in " + (aidPackage.status ?: "()") + " status");
    }
    sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, 
                                        NEEDID, INITIALQUANTITY, QUANTITY, TOTALAMOUNT)
                                        VALUES (${aidPackageItem.quotationID}, ${aidPackageItem.packageID},${aidPackageItem.needID},
                                                 ${aidPackageItem.quantity}, ${aidPackageItem.quantity}, ${aidPackageItem.totalAmount}
                                        ) ON DUPLICATE KEY UPDATE
                                        QUANTITY=${aidPackageItem.quantity},
                                        TOTALAMOUNT=${aidPackageItem.totalAmount};`;

    if (aidPackage.status == "Draft") {
        query = `INSERT INTO AID_PACKAGE_ITEM(QUOTATIONID, PACKAGEID, 
                                        NEEDID, INITIALQUANTITY, QUANTITY, TOTALAMOUNT)
                                         VALUES (${aidPackageItem.quotationID}, ${aidPackageItem.packageID},${aidPackageItem.needID},
                                                 ${aidPackageItem.quantity}, ${aidPackageItem.quantity}, ${aidPackageItem.totalAmount}
                                        ) ON DUPLICATE KEY UPDATE
                                        INITIALQUANTITY=${aidPackageItem.quantity},
                                        QUANTITY=${aidPackageItem.quantity},
                                        TOTALAMOUNT=${aidPackageItem.totalAmount};`;

    }
    sql:ExecutionResult result = check dbClient->execute(query);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        aidPackageItem.packageItemID = lastInsertedID;
    }
}

//Aid Package Update
function getAidPackageUpdate(int packageId) returns AidPackageUpdate[]|error {
    AidPackageUpdate[] aidPackageUpdates = [];
    stream<AidPackageUpdate, error?> resultStream = dbClient->query(`SELECT PACKAGEID, PACKAGEUPDATEID, UPDATECOMMENT, UNIX_TIMESTAMP(DATETIME) as 'dateTime'
                                                                    FROM AID_PACKAGE_UPDATE WHERE PACKAGEID=${packageId};`);
    check from AidPackageUpdate aidPackageUpdate in resultStream
        do {
            aidPackageUpdates.push(aidPackageUpdate);
        };
    check resultStream.close();
    return aidPackageUpdates;
}

function insertOrUpdateAidPackageUpdate(AidPackageUpdate aidPackageUpdate) returns error? {
    int currentTime = getEpoch();
    sql:ParameterizedQuery query = `INSERT INTO AID_PACKAGE_UPDATE(PACKAGEID, PACKAGEUPDATEID, UPDATECOMMENT, DATETIME)
                                        VALUES (${aidPackageUpdate.packageID},
                                                IFNULL(${aidPackageUpdate.packageUpdateID}, DEFAULT(PACKAGEUPDATEID)),
                                                ${aidPackageUpdate.updateComment},
                                                FROM_UNIXTIME(${currentTime})
                                        ) ON DUPLICATE KEY UPDATE
                                        DATETIME=FROM_UNIXTIME(COALESCE(${currentTime}, DATETIME)),
                                        UPDATECOMMENT=COALESCE(${aidPackageUpdate.updateComment}, UPDATECOMMENT);`;
    sql:ExecutionResult result = check dbClient->execute(query);
    var lastInsertedID = result.lastInsertId;
    if lastInsertedID is int {
        aidPackageUpdate.packageUpdateID = lastInsertedID;
    }
}

function deleteAidPackageUpdate(int packageId, int packageUpdateId) returns error? {
    _ = check dbClient->execute(`DELETE FROM AID_PACKAGE_UPDATE WHERE PACKAGEID=${packageId} AND
                                        PACKAGEUPDATEID=${packageUpdateId};`);
}

function getAidPackageUpdateLUT(int? packageUpdateId) returns int|error {
    return check dbClient->queryRow(`SELECT UNIX_TIMESTAMP(DATETIME) as 'dateTime' FROM AID_PACKAGE_UPDATE WHERE PACKAGEUPDATEID=${packageUpdateId};`);
}

//Check Medical Need Quantity
function checkMedicalNeedQuantityAvailable(AidPackageItem aidPackageItem) returns boolean|error {
    int aidPakageExistCount = check dbClient->queryRow(`SELECT count(PACKAGEITEMID) FROM AID_PACKAGE_ITEM WHERE PACKAGEID=${aidPackageItem.packageID} AND QUOTATIONID=${aidPackageItem.quotationID} AND NEEDID=${aidPackageItem.needID};`);
    if (aidPakageExistCount == 0) {
        int quantityAvailableCheck = check dbClient->queryRow(`SELECT REMAININGQUANTITY>=${aidPackageItem.quantity} FROM MEDICAL_NEED WHERE NEEDID=${aidPackageItem.needID};`);
        log:printInfo("quantityAvailable" + quantityAvailableCheck.toString());
        if (quantityAvailableCheck == 0) {
            return false;
        } else {
            return true;
        }
    } else {
        int oldQuantity = check dbClient->queryRow(`SELECT QUANTITY FROM AID_PACKAGE_ITEM WHERE PACKAGEID=${aidPackageItem.packageID} AND QUOTATIONID=${aidPackageItem.quotationID} AND NEEDID=${aidPackageItem.needID};`);
        if (oldQuantity < aidPackageItem.quantity) {
            int quantityAvailableCheck = check dbClient->queryRow(`SELECT REMAININGQUANTITY>=${aidPackageItem.quantity - oldQuantity} FROM MEDICAL_NEED WHERE NEEDID=${aidPackageItem.needID};`);
            log:printInfo("quantityAvailable" + quantityAvailableCheck.toString());
            if (quantityAvailableCheck == 0) {
                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }

    }

}

//Check Already Pledged against the Aid Package Item Update
function checkAlreadyPledgedAgainstAidPackageUpdate(AidPackageItem aidPackageItem, boolean deleteItem) returns boolean|error {
    decimal totalAmount = check dbClient->queryRow(`SELECT sum(TOTALAMOUNT) FROM AID_PACKAGE_ITEM WHERE PACKAGEID=${aidPackageItem.packageID} AND PACKAGEITEMID!=${aidPackageItem.packageItemID};`);
    Quotation quotation = check getQuotation(aidPackageItem.quotationID);
    if !deleteItem {
        totalAmount += <decimal>aidPackageItem.quantity * quotation.unitPrice;
    }
    decimal pledgedAmount = check dbClient->queryRow(`SELECT sum(AMOUNT) FROM PLEDGE WHERE PACKAGEID=${aidPackageItem.packageID};`);
    return pledgedAmount <= totalAmount;

}

//Update Medical Need Quantity
function updateMedicalNeedQuantity(int needId) returns error? {
    _ = check dbClient->execute(`UPDATE MEDICAL_NEED SET REMAININGQUANTITY=NEEDEDQUANTITY-(SELECT SUM(QUANTITY) FROM 
                     AID_PACKAGE_ITEM WHERE NEEDID=${needId}) WHERE NEEDID=${needId};`);
}

//Update Remaining Quantity in Quotation
function updateQuotationRemainingQuantity(AidPackageItem aidPackageItem) returns error? {
    Quotation aidPackageItemQuotation = check getQuotation(aidPackageItem.quotationID);
    _= check dbClient->execute(`UPDATE QUOTATION SET REMAININGQUANTITY=AVAILABLEQUANTITY-(SELECT SUM(QUANTITY) FROM 
                    AID_PACKAGE_ITEM WHERE QUOTATIONID=${aidPackageItemQuotation.quotationID}) 
                    WHERE QUOTATIONID=${aidPackageItemQuotation.quotationID};`);
}

function getReceivedAmount(int packageId) returns decimal|error {
    decimal recievedAmount = check dbClient->queryRow(`SELECT IFNULL(SUM(AMOUNT),0) FROM PLEDGE 
                                                        WHERE PACKAGEID = ${packageId};`);
    return recievedAmount;
}

function updateMedicalNeedsTable(MedicalNeed[] medicalNeeds) returns string|error {
    string statusMessageList = "";
    MedicalNeed[] needsRequireUpdate = [];
    MedicalNeed[] newMedicalNeed = [];
    foreach MedicalNeed medicalNeed in medicalNeeds {
        int|error needID = dbClient->queryRow(`SELECT NEEDID FROM MEDICAL_NEED 
                                    WHERE ITEMID=${medicalNeed.itemID} AND BENEFICIARYID =${medicalNeed.beneficiaryID} 
                                    AND PERIOD=${medicalNeed.period}`);
        if (needID is int) {
            needsRequireUpdate.push(medicalNeed);
        } else {
            newMedicalNeed.push(medicalNeed);
        }
    }
    string status = string `Total Medical Needs Count in file:${medicalNeeds.length()}, Needs require update:${needsRequireUpdate.length()}, New needs:${newMedicalNeed.length()}${"\n"}`;
    statusMessageList = statusMessageList + status;

    sql:ParameterizedQuery[] insertQueries =
        from var data in newMedicalNeed
        select `INSERT INTO MEDICAL_NEED 
                    (ITEMID, BENEFICIARYID, PERIOD, NEEDEDQUANTITY, REMAININGQUANTITY, URGENCY) 
                    VALUES (${data.itemID}, ${data.beneficiaryID},
                    ${data.period}, ${data.neededQuantity}, ${data.neededQuantity}, ${data.urgency})`;

    sql:ParameterizedQuery[] updateQueries =
        from var data in needsRequireUpdate
        select `UPDATE MEDICAL_NEED 
                    SET NEEDEDQUANTITY = ${data.neededQuantity},
                    REMAININGQUANTITY = ${data.neededQuantity} ,
                    URGENCY = ${data.urgency} 
                    WHERE ITEMID = ${data.itemID} AND BENEFICIARYID = ${data.beneficiaryID} AND PERIOD = ${data.period}`;
    string ret = check updateDataInTransaction(insertQueries, updateQueries);
    statusMessageList = statusMessageList + ret;
    log:printInfo(statusMessageList);
    return status;
}

function updateQuotationsTable(Quotation[] quotations) returns string|error {
    string statusMessageList = "";
    Quotation[] quotationsRequireUpdate = [];
    Quotation[] newquotations = [];
    foreach Quotation quotation in quotations {
        int|error quotationID = dbClient->queryRow(`SELECT QUOTATIONID FROM QUOTATION 
                                    WHERE ITEMID=${quotation.itemID} AND SUPPLIERID =${quotation.supplierID} 
                                    AND PERIOD=${quotation.period}`);
        if (quotationID is int) {
            quotationsRequireUpdate.push(quotation);
        } else {
            newquotations.push(quotation);
        }
    }
    string status = string `Total Quotations count in file:${quotations.length()}, Quotations require update:${quotationsRequireUpdate.length()}, New quotations:${newquotations.length()}${"\n"}`;
    statusMessageList = statusMessageList + status;
    sql:ParameterizedQuery[] insertQueries =
        from var data in newquotations
    select `INSERT INTO QUOTATION 
                (SUPPLIERID, ITEMID, BRANDNAME, AVAILABLEQUANTITY, REMAININGQUANTITY, PERIOD, EXPIRYDATE, UNITPRICE, REGULATORYINFO) 
                VALUES (${data.supplierID}, ${data.itemID},${data.brandName}, ${data.availableQuantity}, ${data.remainingQuantity}, ${data.period}, 
                ${data.expiryDate}, ${data.unitPrice}, ${data.regulatoryInfo})`;

    sql:ParameterizedQuery[] updateQueries =
        from var data in quotationsRequireUpdate
    select `UPDATE QUOTATION 
                SET AVAILABLEQUANTITY = ${data.availableQuantity},
                EXPIRYDATE = ${data.expiryDate},
                UNITPRICE = ${data.unitPrice}, 
                REGULATORYINFO = ${data.regulatoryInfo}
                WHERE ITEMID = ${data.itemID} AND SUPPLIERID = ${data.supplierID} AND PERIOD = ${data.period}`;
    string ret = check updateDataInTransaction(insertQueries, updateQueries);
    statusMessageList = statusMessageList + ret;
    log:printInfo(statusMessageList);
    return status;
}

function updateDataInTransaction(sql:ParameterizedQuery[] insertQueries, sql:ParameterizedQuery[] updateQueries) returns string|error {
    string status = "";
    transaction {
        sql:ExecutionResult[]|error insertResult = [];
        sql:ExecutionResult[]|error updateResult = [];
        if (insertQueries.length() > 0) {
            insertResult = dbClient->batchExecute(insertQueries);
        }
        if (updateQueries.length() > 0) {
            updateResult = dbClient->batchExecute(updateQueries);
        }
        if insertResult is error || updateResult is error {
            rollback;
            return error(generateTransactionErrorMessage(insertResult, updateResult));

        } else {
            error? err = commit;
            if err is error {
                return error("Error occurred while committing");
            }
            int totalInsertAffectedRowCount = calculateAffectedRowCountByBatchUpdate(insertResult);
            int totalUpdateAffectedRowCount = calculateAffectedRowCountByBatchUpdate(updateResult);
            status = string `DB Update status: New row count: ${totalInsertAffectedRowCount}, Updated Row Count: ${totalUpdateAffectedRowCount}`;
        }
    }
    return status;
}

function calculateAffectedRowCountByBatchUpdate(sql:ExecutionResult[]|error batchResult) returns int {
    if (batchResult is error) {
        return 0;
    }
    int totalAffectedCount = 0;
    foreach var summary in batchResult {
        totalAffectedCount = totalAffectedCount + <int>summary.affectedRowCount;
    }
    return totalAffectedCount;
}

function generateTransactionErrorMessage(sql:ExecutionResult[]|error insertResult,
        sql:ExecutionResult[]|error updateResult) returns string {

    string message = "Data upload transaction failed,";
    if (insertResult is sql:BatchExecuteError) {
        message = message + " with insert batch error! \n ";
        log:printError("Upload transaction failed:", insertResult);
    }
    if (updateResult is sql:BatchExecuteError) {
        message = message + " with update batch error! \n ";
        log:printError("Upload transaction failed:", updateResult);
    }
    return message;
}

function checkPeriodNeedandQuotation(int needid, int quotationID) returns boolean|error {
    MedicalNeed medicalNeed = check getMedicalNeed(needid);
    Quotation quotation = check getQuotation(quotationID);
    if medicalNeed.period == quotation.period {
        return true;
    }
    return false;
}

function getEpoch() returns int {
    return time:utcNow()[0];
}

