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

// Enum
enum NeedUrgency {
  Normal,
  Critical,
  Urgent
}
enum AidPackageStatus {
  Draft,
  Published,
  Awaiting\ Payment,
  Ordered,
  Shipped,
  Received\ at\ MoH,
  Delivered
}
enum PledgeStatus{
  Pledged, 
  Payment\ Initiated, 
  Payment\ Confirmed
}

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
  NeedUrgency urgency;
  int quantity;
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
};
type AidPackage record {
  int packageID=-1;
  string description;
  string name;
  AidPackageStatus status;
  AidPackageItem[] aidPackageItems=[]; // OBJECTS
};
type AidPackageItem record {
  int packageItemID=-1;
  int packageID;
  int quotationID;
  int needID;
  decimal quantity;
  int totalAmount;
};
type Pledge record {
  int packageID;
  int donorID; 
  decimal amount;
  PledgeStatus status;
};