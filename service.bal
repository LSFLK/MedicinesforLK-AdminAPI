import ballerina/http;
import ballerinax/mysql;

final mysql:Client dbClient = check new (dbHost, dbUser, dbPass, db, dbPort);

# A service representing a network-accessible API bound to port `9090`.
service /admin on new http:Listener(9090) {

    # A resource for reading all medical needs
    # + return - List of MedicalNeeds
    resource function get medicalneeds() returns MedicalNeed[]|error {
        MedicalNeed[] medicalNeeds = check getMedicalNeeds();
        foreach MedicalNeed medicalNeed in medicalNeeds {
            medicalNeed.period.day = 1;
            medicalNeed.medicalItem = check getMedicalItem(medicalNeed.itemID);
            medicalNeed.beneficiary = check getBeneficiary(medicalNeed.beneficiaryID);
            medicalNeed.supplierQuotes = check getMatchingQuotatonsForMedicalNeed(medicalNeed);
        }
        return medicalNeeds;
    }

    # A resource for reading all suppliers
    # + return - List of suppliers
    resource function get suppliers() returns Supplier[]|error {
        return getSuppliers();
    }

    # A resource for fetching a supplier
    # + return - A supplier
    resource function get suppliers/[int supplierId]() returns Supplier|error {
        return getSupplier(supplierId);
    }

    # A resource for creating a asupplier
    # + return - A Supplier
    resource function post supplier(@http:Payload Supplier supplier) returns Supplier|error {
        return addSupplier(supplier);
    }

    resource function get donors/[string donorId]() returns Donor|error {
        return getDonor(donorId);
    }

    resource function get donors() returns Donor[]|error {
        return getDonors();
    }

    # A resource for creating  quotation
    # + return - A quotation
    resource function post quotation(@http:Payload Quotation quotation) returns Quotation|error {
        quotation.period.day = 1;
        quotation.quotationID = check addQuotation(quotation);
        quotation.supplier = check getSupplier(quotation.supplierID);
        return quotation;
    }

    # A resource for reading all Aid-Packages optionally filter by status
    # + return - List of Aid-Packages 
    resource function get aidpackages(string? status) returns AidPackage[]|error {
        AidPackage[] aidPackages = check getAidPackages(status);
        foreach AidPackage aidPackage in aidPackages {
            check constructAidPackageData(aidPackage);
        }
        return aidPackages;
    }

    # A resource for fetching an Aid-Package
    # + return - An Aid-Package
    resource function get aidpackages/[int packageId]() returns AidPackage|error {
        AidPackage aidPackage = check getAidPackage(packageId);
        check constructAidPackageData(aidPackage);
        return aidPackage;
    }

    # A resource for creating an Aid-Package
    # + return - An Aid-Package
    resource function post aidpackages(@http:Payload AidPackage aidPackage) returns AidPackage|error {
        int aidPackageid = check addAidPackage(aidPackage);
        aidPackage.packageID = aidPackageid;
        foreach AidPackageItem aidPackageItem in aidPackage.aidPackageItems {
            check constructAidPAckageItem(aidPackageid, aidPackageItem);
        }
        return aidPackage;
    }

    # A resource for modifying an Aid-Package
    # + return - An Aid-Package
    resource function patch aidpackages(@http:Payload AidPackage aidPackage) returns AidPackage|error {
        check updateAidPackage(aidPackage);
        AidPackageItem[] aidPackageItems = check getAidPackageItems(aidPackage.packageID ?: -1);
        foreach AidPackageItem aidPackageItem in aidPackageItems {
            aidPackageItem.quotation = check getQuotation(aidPackageItem.quotationID);
        }
        aidPackage.aidPackageItems = aidPackageItems;
        return aidPackage;
    }

    # A resource for creating AidPackage-Item
    # + return - AidPackage-Item
    resource function post aidpackages/[int packageID]/aidpackageitems(@http:Payload AidPackageItem aidPackageItem)
                                                                    returns AidPackageItem|error {
        if (check checkPeriodNeedandQuotation(aidPackageItem.needID, aidPackageItem.quotationID)) {
            if (check checkMedicalNeedQuantityAvailable(aidPackageItem)) {
                check constructAidPAckageItem(packageID, aidPackageItem);
                return aidPackageItem;
            } else {
                return error 'error("Medical Need Remaining Amount Exceeds Aid Package Item Amount");
            }
        } else {
            return error 'error("Medical Need and Qutation, Period Mismatch");
        }
    }

    # A resource for updating AidPackage-Item
    # + return - AidPackage-Item
    resource function put aidpackages/[int packageID]/aidpackageitems(@http:Payload AidPackageItem aidPackageItem)
                                                                    returns AidPackageItem|error {
        if (check checkPeriodNeedandQuotation(aidPackageItem.needID, aidPackageItem.quotationID)) {
            aidPackageItem.packageID = packageID;
            if (check checkMedicalNeedQuantityAvailable(aidPackageItem)) {
                check insertOrUpdateAidPackageItem(aidPackageItem);
                check updateMedicalNeedQuantity(aidPackageItem.needID);
                aidPackageItem.quotation = check getQuotation(aidPackageItem.quotationID);
                return aidPackageItem;
            } else {
                return error 'error("Medical Need Remaining Amount Exceeds Aid Package Item Amount");
            }
        } else {
            return error 'error("Medical Need and Qutation, Period Mismatch");
        }

    }

    # A resource for removing an AidPackage
    # + return - aidPackageId
    resource function delete aidpackages/[int packageID]() returns int|error {
        AidPackageItem[] aidPackageItems = check getAidPackageItems(packageID);
        foreach AidPackageItem aidPackageItem in aidPackageItems {
            check deleteAidPackageItem(packageID, <int> aidPackageItem.packageItemID);
        }
        check deleteAidPackage(packageID);
        return packageID;
    }

    # A resource for removing an AidPackage-Item
    # + return - aidPackageItem
    resource function delete aidpackages/[int packageID]/aidpackageitems/[int packageItemID]() returns int|error {
        check deleteAidPackageItem(packageID, packageItemID);
        return packageItemID;
    }

    # A resource for fetching all comments of an Aid-Package
    # + return - list of AidPackageUpdateComments
    resource function get aidpackages/[int packageId]/updatecomments() returns AidPackageUpdate[]|error {
        return check getAidPackageUpdate(packageId);
    }

    # A resource for saving update with a comment to an Aid-Package
    # + return - AidPackageUpdateComment
    resource function put aidpackages/[int packageID]/updatecomments(@http:Payload AidPackageUpdate aidPackageUpdate)
                                                                returns AidPackageUpdate?|error {
        aidPackageUpdate.packageID = packageID;
        check insertOrUpdateAidPackageUpdate(aidPackageUpdate);
        aidPackageUpdate.dateTime = check getAidPackageUpdateLUT(aidPackageUpdate.packageUpdateID);
        return aidPackageUpdate;
    }

    # A resource for removing an update comment from an Aid-Package
    # + return - aidPackageUpdateId
    resource function delete aidpackages/[int packageId]/updatecomment/[int packageUpdateId]() returns int|error {
        check deleteAidPackageUpdate(packageId, packageUpdateId);
        return packageUpdateId;
    }

    # A resource for fetching all pledges of an Aid-Package
    # + return - list of pledges
    resource function get aidpackages/[int packageId]/pledges() returns Pledge[]|error {
        return getPledges(packageId);
    }

    # A resource for fetching details of all pledges
    # + return - list of Pledges
    resource function get pledges() returns Pledge[]|error {
        return getPledges();
    }

    # A resource for fetching pledge for a given pledge ID
    # + return - Pledge
    resource function get pledges/[int pledgeId]() returns Pledge|error {
        return getPledge(pledgeId);
    }

    # A resource for update status of a Pldege
    # + return - pledgeUpdateID
    resource function patch pledges/[int pledgeId]/status/[string status]() returns Pledge|error {
        return check updatePledge(status, pledgeId);
    }

    # A resource for fetching all comments of a pledge
    # + return - list of PledgeUpdateComments
    resource function get pledges/[int pledgeId]/updatecomments() returns PledgeUpdate[]|error {
        return check getPledgeUpdates(pledgeId);
    }

    # A resource for removing a Pldege
    # + return - pledgeID
    resource function delete pledges/[int pledgeId]() returns int|error {
        check deletePledge(pledgeId);
        return pledgeId;
    }

    # A resource for removing an update comment from a Pldege
    # + return - pledgeUpdateID
    resource function delete pledges/[int pledgeId]/updatecomment/[int pledgeUpdateId]() returns int|error {
        check deletePledgeUpdate(pledgeId, pledgeUpdateId);
        return pledgeUpdateId;
    }

    # A resource for saving update with a comment to a Pledge
    # + return - PledgeUpdate
    resource function put pledges/[int pledgeID]/updatecomment(@http:Payload PledgeUpdate pledgeUpdate) returns PledgeUpdate?|error {
        pledgeUpdate.pledgeID = pledgeID;
        check insertOrUpdatePledgeUpdate(pledgeUpdate);
        pledgeUpdate.dateTime = check getPledgeUpdateLUT(pledgeUpdate.pledgeUpdateID);
        return pledgeUpdate;
    }

    # A resource for uploading medical needs CSV file
    #
    # + request - http:Request with the file payload
    # + return - Return http:Response or an error
    resource function post requirements/medicalneeds(http:Request request) returns http:Response|error {
        do {
            http:Response response = new;
            string[][] csvLines = check handleCSVBodyParts(request);
            MedicalNeed[] medicalNeeds = check createMedicalNeedsFromCSVData(csvLines);
            string status = check updateMedicalNeedsTable(medicalNeeds);
            response.setPayload("CSV File uploaded successfully!\n" + status);
            return response;
        } on fail var e {
            return e;
        }
    }

    # Resource for uploading quotations
    #
    # + request - http:Request with the file payload
    # + return - Return http:Response or an error
    resource function post quotations(http:Request request) returns http:Response|error {
        do {
            http:Response response = new;
            string[][] csvLines = check handleCSVBodyParts(request);
            Quotation[] quotations = check createQuotationFromCSVData(csvLines);
            string status = check updateQuotationsTable(quotations);
            response.setPayload("CSV File uploaded successfully!\n" + status);
            return response;
        } on fail var e {
            return e;
        }
    }
}
