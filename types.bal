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
    int? beneficiaryID = ();
    string name;
    string shortName;
    string email;
    string phoneNumber;
};

type Donor record {
    int? donarID = ();
    string orgName;
    string orgLink;
    string email;
    string phoneNumber;
};

// Main Types
type MedicalItem record {
    int? itemID = ();
    string name;
    string shortName;
    string email;
    string phoneNumber;
};

type RequirementList record {
    string name;
    MedicalNeed[] needs = [];
};

type MedicalNeed record {
    int? needID = ();
    int itemID;
    int beneficiaryID;
    time:Date period;
    string urgency;
    int neededQuantity;
    Beneficiary? beneficiary = ();
    MedicalItem? medicalItem = ();
};

type Quotation record {
    int? quotationID = ();
    int supplierID;
    int itemID;
    string brandName;
    int availableQuantity;
    time:Date period;
    time:Date expiryDate;
    string regulatoryInfo;
    decimal unitPrice;
    Supplier? supplier = ();
};

type AidPackage record {
    int? packageID = ();
    string description;
    string name;
    string? status = "Draft";
    AidPackageItem?[] aidPackageItems = [];
};

type AidPackageItem record {
    int? packageItemID = ();
    int? packageID = ();
    int quotationID;
    int needID;
    int quantity;
    decimal totalAmount = 0;
    Quotation? quotation = ();
};

type AidPackageUpdate record {
    int? packageUpdateId = ();
    int? packageID = ();
    string updateComment;
    string? dateTime = ();
};

type Pledge record {
    int? pledgeID = ();
    int packageID;
    int donorID;
    decimal amount;
    string status;
    Donor? donor;
};

type PledgeUpdate record {
    int? pledgeUpdateID = ();
    int? pledgeID = ();
    string updateComment;
    string? dateTime = ();
};

// Information type
type MedicalNeedInfo record {
    int needID;
    int itemID;
    string name;
    time:Date period;
    string urgency;
    int neededQuantity;
    int remainingQuantity;
    Beneficiary? beneficiary = ();
    Quotation[] supplierQuotes = [];
};