import ballerina/time;

// Stakeholders
type Supplier record {
    int supplierID = -1;
    string name;
    string shortName;
    string email;
    string phoneNumber;
};

type Beneficiary record {
    int beneficiaryID = -1;
    string name;
    string shortName;
    string email;
    string phoneNumber;
};

type Donor record {
    int donorID = -1;
    string orgName;
    string orgLink;
    string email;
    string phoneNumber;
};

// Main Types
type MedicalItem record {
    int itemID = -1;
    string name;
    string 'type;
    string unit;
};

type MedicalNeed record {
    int needID = -1;
    int itemID;
    int beneficiaryID;
    time:Date period;
    string urgency;
    int neededQuantity;
    int remainingQuantity;
    Beneficiary? beneficiary = ();
    Quotation[] supplierQuotes = [];
    MedicalItem? medicalItem = ();
};

type Quotation record {
    int quotationID = -1;
    int supplierID;
    int itemID;
    string brandName;
    int availableQuantity;
    time:Date period;
    time:Date expiryDate;
    string regulatoryInfo;
    decimal unitPrice;
    Supplier? supplier = ();
    MedicalItem? medicalItem = ();
};

type AidPackage record {
    int packageID = -1;
    string description;
    string name;
    string status;
    AidPackageItem[] aidPackageItems = [];
};

type AidPackageItem record {
    int packageItemID = -1;
    int packageID;
    int quotationID;
    int needID;
    int quantity;
    decimal totalAmount;
    Quotation? quotation = ();
};

type AidPackageUpdate record {
    int packageUpdateId = -1;
    int packageID;
    string updateComment;
    string? dateTime;
};

type Pledge record {
    int pledgeID = -1;
    int packageID;
    int donorID;
    decimal amount;
    string status;
    Donor? donor;
};

type PledgeUpdate record {
    int pledgeUpdateID = -1;
    int pledgeID;
    string updateComment;
    string? dateTime = ();
};