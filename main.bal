import ballerina/time;

// Stakeholders (Main Actors)
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
  int donarID = -1;
  string orgName;
  string orgLink;
  string email;
  string phoneNumber;
};

// Main Types
type MedicalItem record {
  int itemID; 
  string name; 
  string shortName; 
  string email;
  string phoneNumber;
};
type RequirementList record {
  string name;
  MedicalNeed[] needs;
};
type MedicalNeed record {
  int needID;
  int itemID;
  int beneficiaryID; 
  time:Date period;
  string urgency;
  int quantity;
  Beneficiary? beneficiary;
};
type Quotation record {
  int quotationID;
  int supplierID;
  int itemID;
  int availableQuantity;
  time:Date expiryDate; 
  string regulatoryInfo;
  string brandName;
  int unitPrice;
  Supplier? supplier;
  MedicalItem? medicalItem;
};
type AidPackage record {
  int packageID=-1;
  string description;
  string name;
  string status;
  AidPackageItem?[] aidPackageItems=[];
};
type AidPackageItem record {
  int packageItemID=-1;
  int packageID;
  int quotationID;
  int needID;
  decimal quantity;
  int totalAmount;
  Quotation? quotation;
};
type Pledge record {
  int packageID;
  int donorID; 
  decimal amount;
  string status;
};