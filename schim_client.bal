import ballerina/http;

final http:Client schimClientEp = check new(schimEndpoint, 
    auth = {
        tokenUrl: tokenEndpoint,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: schimScopes
    }
);

# Record to represent SCHIM Donor search response.
# 
# + Resources - Results for the search query
type DonorScimResponse record {
    Donor[] Resources?;
};

isolated function getDonors(int pageNumber, int pageCount) returns Donor[]|error {
    DonorScimResponse scimResult = check schimClientEp->get(string `/Users?domain=CUSTOMER-DEFAULT&filter=groups+eq+donor&attributes=displayName`);
    Donor[]? availableUsers = scimResult?.Resources;
    if availableUsers is Donor[] {
        return availableUsers;
    }
    return [];
}

isolated function getDonor(string donorId) returns Donor|error {
    DonorScimResponse scimResult = check schimClientEp->get(string `/Users?filter=id eq ${donorId}&attributes=displayName`);
    Donor[]? availableUsers = scimResult?.Resources;
    if availableUsers is Donor[] {
        return availableUsers[0];
    }
    return error(string `Could not find the donor for Id ${donorId}`);
}
