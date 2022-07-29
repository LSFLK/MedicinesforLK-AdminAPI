import ballerina/time;

type Supplier record {
    int? supplierID = ();
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
    string id;
    string userName;
    string firstName;
    string lastName;
    string email?;
};

// Main Types
type MedicalItem record {
    int itemID;
    string name;
    string 'type;
    string unit;
};

type MedicalNeed record {
    int? needID = ();
    int itemID;
    int beneficiaryID;
    time:Date period;
    string urgency;
    int neededQuantity;
    int? remainingQuantity = 0;
    Beneficiary? beneficiary = ();
    Quotation[] supplierQuotes = [];
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
    Supplier supplier?;
    MedicalItem? medicalItem = ();
};

type AidPackage record {
    int? packageID = ();
    string description;
    string name;
    string? status = "Draft";
    decimal goalAmount?;
    decimal receivedAmount?;
    AidPackageItem[] aidPackageItems = [];
};

type AidPackageItem record {
    int? packageItemID = ();
    int? packageID = ();
    int quotationID;
    int needID;
    time:Date period?;
    int initialQuantity = 0;
    int quantity;
    decimal totalAmount = 0;
    Quotation? quotation = ();
};

type AidPackageUpdate record {
    int? packageUpdateID = ();
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

