import ballerina/http;

# Record to represent SCHIM user search request.
#
# + schemas - SCHIM schema for the request
# + attributes - Required attributes for the response  
# + filter - User filter query
# + domain - User domain  
# + startIndex - Start index for the search(search has 1-based indexes) 
# + count - Maximum number of results for the response
type SchimUserSearchRequest record {|
    string[] schemas = ["urn:ietf:params:scim:api:messages:2.0:SearchRequest"];
    string[] attributes?;
    string filter;
    string domain;
    int startIndex;
    int count;
|};

# Record to represent SCHIM user search response.
#
# + totalResults - Number of results
# + startIndex - Start index for the search(search has 1-based indexes)
# + itemsPerPage - Maximum number of results for the response
# + schemas - SCHIM schema for the response  
# + Resources - Results for the search query
type SchimUserResponse record {|
    int totalResults;
    int startIndex;
    int itemsPerPage;
    json schemas;
    User[] Resources?;
|};

# Record representing the SCHIM user resource.
#
# + meta - Meta information regarding the user resource
# + id - User Id of the current user resource
# + userName - Username of the current user resource  
# + name - Name of the user resource
# + emails - Available emails of the user resource  
# + roles - Available roles for the user resource  
# + groups - User groups in which the user resource is a member
type User record {
    json meta;
    string id;
    string userName;
    record {|
        string givenName;
        string familyName;
    |} name;
    (Email|string)[] emails;
    json[] roles?;
    json[] groups?;
};

# Record representing the email details of the user resource.
#
# + 'type - Email type  
# + value - Email address  
# + primary - Flag indicating whether this email is a primary email or not
type Email record {|
    string 'type;
    string value;
    boolean primary?;
|};

final http:Client schimClientEp = check new(schimEndpoint, 
    auth = {
        tokenUrl: tokenEndpoint,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: schimScopes
    }
);

isolated function getDonors(int pageNumber, int pageCount) returns Donor[]|error {
    // int startIdx = pageNumber == 0 ? 1: pageCount + (pageNumber - 1 * pageCount);
    // SchimUserSearchRequest requestPayload = {
    //     filter: "groups eq donor",
    //     domain: userDomain,
    //     startIndex: startIdx,
    //     count: pageCount
    // };
    // SchimUserResponse schimResponse = check schimClientEp->post("/Users/.search", requestPayload);
    // User[]? availableUsers = schimResponse?.Resources;
    // if availableUsers is User[] {
    //     return
    //     from var {id, userName, name, emails} in availableUsers
    //     select {
    //         id: id, 
    //         userName: userName, 
    //         firstName: name.givenName, 
    //         lastName: name.familyName, 
    //         email: check getPrimaryEmail(emails)
    //     };
    // }
    return [];
}

type DonorScimResponse record {
    Donor[] Resources?;
};

isolated function getDonor(string donorId) returns Donor? {
    DonorScimResponse|error scimResult = schimClientEp->get("/Users?filter=id eq " + donorId + "&attributes=displayName");
    if scimResult is error {
        return;
    }
    Donor[]? donors = scimResult.Resources; // donors.length must be 1 when it's an array
    return donors != () ? donors[0] : ();
}

isolated function getPrimaryEmail((Email|string)[] emails) returns string|error {
    foreach Email|string email in emails {
        if email is Email {
            if email?.primary is true {
                return email.value;
            }
        } else {
            return email;
        }
    }
    return error("No primary email found");
}
