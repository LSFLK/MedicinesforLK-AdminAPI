import ballerina/mime;
import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerina/regex;

function handleCSVBodyParts(http:Request request) returns string[][]|error {
    var bodyParts = request.getBodyParts();
    if (bodyParts is mime:Entity[]) {
        string[][] csvLines = [];
        foreach var bodyPart in bodyParts {
            var mediaType = mime:getMediaType(bodyPart.getContentType());
            if (mediaType is mime:MediaType) {
                string baseType = mediaType.getBaseType();
                if ("text/csv" == baseType) {
                    byte[] payload = check bodyPart.getByteArray();
                    csvLines = check getCSVData(payload);
                } else {
                    return error("Invalid base type, not text/csv");
                }
            } else {
                return error("Invalid media type");
            }
        }
        return csvLines;
    } else {
        return error("Error in decoding multiparts!");
    }
}

function getCSVData(byte[] payload) returns string[][]|error {
    io:ReadableByteChannel readableByteChannel = check io:createReadableChannel(payload);
    io:ReadableCharacterChannel readableCharacterChannel = new (readableByteChannel, "UTF-8");
    io:ReadableCSVChannel readableCSVChannel = new io:ReadableCSVChannel(readableCharacterChannel, ",", 1);
    return check channelReadCsv(readableCSVChannel);
}

function channelReadCsv(io:ReadableCSVChannel readableCSVChannel) returns string[][]|error {
    string[][] results = [];
    int i = 0;
    while readableCSVChannel.hasNext() {
        var records = readableCSVChannel.getNext();
        if records is string[] {
            results[i] = records;
            i += 1;
        } else if records is error {
            check readableCSVChannel.close();
            return records;
        }
    }
    check readableCSVChannel.close();
    return results;
}

function readMedicalNeedsCSVLine(string[] line, int csvLineNo) returns [string, int, string, string, string, string, string, int]|error => [
    line[0],
    check readIntCSVField(line[1], csvLineNo),
    line[2],
    line[3],
    line[4],
    line[5],
    line[6],
    check readIntCSVField(line[7], csvLineNo)
];

function readSupplyQuotationsCSVLine(string[] line, int csvLineNo) returns [string, string, string, string, string, string, int, string, decimal]|error => [
    line[0],
    line[1],
    line[2],
    line[3],
    line[4],
    line[5],
    check readIntCSVField(line[6], csvLineNo),
    line[7],
    check readDollerCSVField(line[8], csvLineNo)
];

function readIntCSVField(string value, int csvLineNo) returns int|error {
    int|error intVal = int:fromString(value.trim());
    if (intVal is error) {
        return error(string `Error in parsing int:${value} in line ${csvLineNo}`);
    }
    return intVal;
}

function readDollerCSVField(string value, int csvLineNo) returns decimal|error {
    decimal|error decimalVal = decimal:fromString(value.substring(1, value.length() - 1).trim());
    if (decimalVal is error) {
        return error(string `Error in parsing doller amount:${value} in line ${csvLineNo}`);
    }
    return decimalVal;
}

function getPeriod(string period) returns time:Date|error {
    string[] dateParts = regex:split(period, " ");
    int year = check int:fromString(dateParts[1]);
    int month = check getMonth(dateParts[0]);
    time:Date date = {year: year, month: month, day: 1};
    return date;
}

function getMonth(string month) returns int|error {
    match month {
        "Jan" => {
            return 1;
        }
        "Feb" => {
            return 2;
        }
        "Mar" => {
            return 3;
        }
        "Apr" => {
            return 4;
        }
        "May" => {
            return 5;
        }
        "Jun" => {
            return 6;
        }
        "Jul" => {
            return 7;
        }
        "Aug" => {
            return 8;
        }
        "Sep" => {
            return 9;
        }
        "Oct" => {
            return 10;
        }
        "Nov" => {
            return 11;
        }
        "Dec" => {
            return 12;
        }
        _ => {
            return error("Invalid month in the Period");
        }
    }
}

function getDateFromString(string dateString) returns time:Date|error {
    string[] dateParts = regex:split(dateString, "/");
    time:Date date = {
        year: check int:fromString(dateParts[2]),
        month: check int:fromString(dateParts[0]),
        day: check int:fromString(dateParts[1])
    };
    return date;
}

function createMedicalNeedsFromCSVData(string[][] inputCSVData) returns MedicalNeed[]|error {
    MedicalNeed[] medicalNeeds = [];
    string errorMessages = "";
    int csvLineNo = 0;
    foreach var line in inputCSVData {
        boolean hasError = false;
        int medicalItemId = -1;
        int medicalBeneficiaryId = -1;
        csvLineNo += 1;
        if (line.length() == 8) {
            var [_, _, urgency, period, beneficiary, itemName, _, neededQuantity] = check readMedicalNeedsCSVLine(line, csvLineNo);
            int|error itemID = getMedicalItemId(itemName);
            if (itemID is error) {
                errorMessages = errorMessages + string `Line:${csvLineNo}| ${itemName} is missing in MEDICAL_ITEM table 
`;
                hasError = true;
            } else {
                medicalItemId = itemID;
            }
            int|error beneficiaryID = getBeneficiaryId(beneficiary);
            if (beneficiaryID is error) {
                errorMessages = errorMessages + string `Line:${csvLineNo}| ${beneficiary} is missing in BENEFICIARY table 
`;
                hasError = true;
            } else {
                medicalBeneficiaryId = beneficiaryID;
            }
            if (!hasError) {
                MedicalNeed medicalNeed = {
                    itemID: medicalItemId,
                    beneficiaryID: medicalBeneficiaryId,
                    period: check getPeriod(period),
                    urgency,
                    neededQuantity
                };
                medicalNeeds.push(medicalNeed);
            }
        } else {
            return error(string `Invalid CSV Length in line:${csvLineNo}`);
        }
    }
    if (errorMessages.length() > 0) {
        return error(errorMessages);
    }
    return medicalNeeds;
}

function createQuotationFromCSVData(string[][] inputCSVData) returns Quotation[]|error {
    Quotation[] qutoations = [];
    string errorMessages = "";
    int csvLineNo = 0;
    foreach var line in inputCSVData {
        boolean hasError = false;
        int medicalItemId = -1;
        int quotationSupplierId = -1;
        csvLineNo += 1;
        if (line.length() == 9) {
            var [_, supplier, itemNeeded, regulatoryInfo, brandName, period, availableQuantity, expiryDate, unitPrice]
                = check readSupplyQuotationsCSVLine(line, csvLineNo);
            int|error itemID = getMedicalItemId(itemNeeded);
            if (itemID is error) {
                errorMessages = errorMessages + string `Line:${csvLineNo}| ${itemNeeded} is missing in MEDICAL_ITEM table
`;
                hasError = true;
            } else {
                medicalItemId = itemID;
            }
            int|error supplierID = getSupplierId(supplier);
            if (supplierID is error) {
                errorMessages = errorMessages + string `Line:${csvLineNo}| ${supplier} is missing in SUPPLIER table
`;
                hasError = true;
            } else {
                quotationSupplierId = supplierID;
            }
            if (!hasError) {
                Quotation quotation = {
                    supplierID: quotationSupplierId,
                    itemID: medicalItemId,
                    brandName,
                    availableQuantity,
                    period: check getPeriod(period),
                    expiryDate: check getDateFromString(expiryDate),
                    regulatoryInfo,
                    unitPrice
                };
                qutoations.push(quotation);
            }
        }
        else {
            return error(string `Invalid CSV Length in line:${csvLineNo}`);
        }
    }
    if (errorMessages.length() > 0) {
        return error(errorMessages);
    }
    return qutoations;
}
