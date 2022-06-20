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
  int itemID=-1; 
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
  int needID=-1;
  int itemID;
  int beneficiaryID; 
  time:Date period;
  string urgency;
  int quantity;
  Beneficiary? beneficiary = ();
};
type Quotation record {
  int quotationID=-1;
  int supplierID;
  int itemID;
  string brandName;
  int availableQuantity;
  time:Date expiryDate; 
  string regulatoryInfo;
  decimal unitPrice;
  Supplier? supplier = ();
  MedicalItem? medicalItem = ();
};
type AidPackage record {
  int packageID=-1;
  string? description = ();
  string? name = ();
  string status="Draft";
  AidPackageItem[] aidPackageItems=[];
};
type AidPackageItem record {
  int packageItemID=-1;
  int packageID=-1;
  int quotationID;
  int needID;
  int quantity;
  decimal totalAmount = 0;
  Quotation? quotation = ();
};
type Pledge record {
  int pledgeID=-1;
  int packageID;
  int donorID; 
  decimal amount;
  string status;
};

// Information type
type MedicalNeedInfo record {
  int needID=-1;
  time:Date period;
  string urgency;
  int quantity;
  Beneficiary? beneficiary = ();
  Quotation[] supplierQuotes = [];
};