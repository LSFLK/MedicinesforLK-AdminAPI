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
    DonorScimResponse schimResult = check schimClientEp->get(string `/Users?domain=CUSTOMER-DEFAULT&filter=groups+eq+donor&attributes=displayName`);
    Donor[]? availableUsers = schimResult?.Resources;
    if availableUsers is Donor[] {
        return availableUsers;
    }
    return [];
}

isolated function getDonor(string donorId) returns Donor|error? {
    Donor|error schimResult = schimClientEp->get(string `/Users/${donorId}?attributes=displayName`);
    if schimResult is Donor {
        return schimResult;
    } else if schimResult is http:ClientRequestError {
        int requestStatus = schimResult.detail().statusCode;
        // If there is a data-binding failure, http-client will emit HTTP BAD_REQEST(400)
        if requestStatus == http:STATUS_BAD_REQUEST {
            return;
        }
    }
    return schimResult;
}
