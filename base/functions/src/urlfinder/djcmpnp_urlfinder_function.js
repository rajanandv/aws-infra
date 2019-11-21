'use strict';

/**
 * Lambda example: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html
 * Lambda Event Structure: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html
 * Custom origin: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html#lambda-examples-content-based-custom-origin-request-trigger
 * 
 * AWS referring country codes: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/header-caching.html
 * The complete list of country codes (249): https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
 * Country codes & Region codes: https://gist.github.com/richjenks/15b75f1960bc3321e295
 */

var AWS = require('aws-sdk');
var sts = new AWS.STS();
var envInfo = require('./env_info');
const path = require('path');
const querystring = require('querystring');

var debugFlag = true; var infoFlag = true; var errorFlag = true;
var logDebug = debugFlag ? console.log.bind(console) : function () { };
var logInfo = infoFlag ? console.log.bind(console) : function () { };
var logError = errorFlag ? console.log.bind(console) : function () { };

var wsjDomainUrlMap = {};
wsjDomainUrlMap['AMER'] = '/shop/';
//wsjDomainUrlMap['AMER'] = '/shop/US/';
wsjDomainUrlMap['APAC'] = '/shop/APAC/';
wsjDomainUrlMap['EMEA'] = '/shop/EMEA/';
var defaultUrlWSJ = '/shop/';

var barDomainUrlMap = {};
barDomainUrlMap['AMER'] = '/shop/';
//barDomainUrlMap['AMER'] = '/shop/US/';
barDomainUrlMap['APAC'] = '/shop/APAC/';
barDomainUrlMap['EMEA'] = '/shop/EMEA/';
var defaultUrlBarrons = '/shop/';

const default_doc = 'index.html';
const REDIRECT_PREFIX = "redirect:";
const CHAR_COLON = ":";
const CHAR_SLASH = "/";
const CHAR_QNMARK = "?";

const PROTOCOL_PREFIX = "https://";
const DOMAIN_WSJ = "wsj";
const DOMAIN_BAR = "bar";
const VANITYDOMAIN_PREFIX = "wsj:";
const DEFAULT_CNTRYCODE  = "US";
const DEFAULT_REGIONCODE = "AMER";
const EMPTY_URI = "";
const EMPTY_URI_SLASH = "/";
const ROOT_INDEX = "/index.html";

//NOTE: All the shop-pages for WSJ and Barrons contain "shop" in the S3 bucket's folder name
const DOMAINPATH_SHOPFOLDER = "shop";
const ROOT_SHOP = "/shop/";
const URI_SHOPPAGES = "shop";

exports.find_url = (event, context, callback) => {

    var domainUrlMap = {};
    domainUrlMap['wsj'] = PROTOCOL_PREFIX + envInfo.envData.DOMAIN_WSJ; //store.wsj.com
    domainUrlMap['bar'] = PROTOCOL_PREFIX + envInfo.envData.DOMAIN_BAR; //store.barrons.com
    var ddb_role_arnval = "arn:aws:iam::"+envInfo.envData.DDB_AWS_ACCTNUMBER+":role/djcmpnp_lambdaedge_urlmgmt_dynamodb_role_"+envInfo.envData.ENVIRONMENT_NAME;
    logDebug("urlfinder :: find_url :: ddb_role_arnval: ", ddb_role_arnval);

    var vanityDomainUrlMap = {};
    vanityDomainUrlMap['wsj'] = envInfo.envData.DOMAIN_WSJ; //store.wsj.com
    vanityDomainUrlMap['bar'] = envInfo.envData.DOMAIN_BAR; //store.barrons.com
    //NOTE: To support any new domains (e.g., marketwatch), add the respective key/value

    var ddb_shopurl_tablename = 'djcmpnp_shopurls_ddbtable_' + envInfo.envData.ENVIRONMENT_NAME;     //'djcmpnp_shopurls_ddbtable_qa1';
    var ddb_vanityurl_tablename = 'djcmpnp_vanityurls_ddbtable_' + envInfo.envData.ENVIRONMENT_NAME; //'djcmpnp_vanityurls_ddbtable_qa1';
    var domain_sitecontrol =  envInfo.envData.DOMAIN_SITECONTROL; //com-caj-int.dist.dj01.onservo.com
    logDebug("urlfinder :: find_url :: shopurl_tablename: "+ddb_shopurl_tablename+", vanityurl_tablename: "+ddb_vanityurl_tablename);

    let newUri;
    const request = event.Records[0].cf.request;
    const parsedPath = path.parse(request.uri);
    logDebug('urlfinder :: find_url :: RequestURI:', request.uri);

    var domainPath = request.origin.s3.path;
    logInfo("urlfinder :: find_url :: domainPath:", domainPath);

    //in case of vanity, domainPath is undefined. This would resulting into WSJ
    var defaultUrlByCountry = find_defaulturl_bycountry(request.headers, domainPath);
    logInfo("urlfinder :: find_url :: defaultUrlByCountry:", defaultUrlByCountry);

    var vanityUrlFlag = true; //assuming the incoming request is for vanity
    var ddb_tablename = ddb_vanityurl_tablename;
    if(domainPath.indexOf(DOMAINPATH_SHOPFOLDER) > -1){
        ddb_tablename = ddb_shopurl_tablename;
        vanityUrlFlag = false;
    }
    logDebug('urlfinder :: find_url :: ddb_tablename to Qry:', ddb_tablename);

    if(vanityUrlFlag){
        var vanityuri_val = VANITYDOMAIN_PREFIX + parsedPath.base;
        logInfo("urlfinder :: find_url :: uri_val to search in DDB:", vanityuri_val); // vanityuri_val
        var vanityddbQryRecPromise = exec_query(ddb_tablename, vanityuri_val, defaultUrlByCountry, true, vanityDomainUrlMap, ddb_role_arnval);
        vanityddbQryRecPromise.then(path2display => {
            logDebug("urlfinder :: find_url :: ddbQryRecPromise.then :: path2display:", path2display);
            if (path2display.indexOf(REDIRECT_PREFIX) > -1) {
                var path2redirect = path2display.substring(REDIRECT_PREFIX.length);
                logDebug('urlfinder :: find_url :: promise :: about to redirect :: path2redirect:', path2redirect);
                const response = vanity_redirecting_response(path2redirect);
                callback(null, response);
            }
        });

    }else{
        const params = querystring.parse(request.querystring); //(request.querystring.toLowerCase());
        const sortedParams = {};
        Object.keys(params).sort().forEach(key => {
            sortedParams[key] = params[key];
        });

        request.querystring = querystring.stringify(sortedParams); //Update request querystring with normalized
        var qrystringVal = request.querystring;
        logInfo("urlfinder :: find_url :: qrystringVal:", qrystringVal);
        if (qrystringVal !== '') {
            //TODO:: security :: XSS & dynamic-parameter supressing/adding through URL-management screen from PnP-BCC
            //const params = querystring.parse(request.querystring);
            //request.querystring = querystring.stringify(updatedFilteredParams(params));
            qrystringVal = CHAR_QNMARK + qrystringVal; //this will be appended to the redirectURL
        }

        var domain_type = DOMAIN_BAR; //defaulting it to bar (barrons)
        if (domainPath.indexOf(DOMAIN_WSJ) > -1) {
            domain_type = DOMAIN_WSJ;
        }
        logInfo("urlfinder :: find_url :: domain_type:", domain_type);

        var defaultWSJShopUriFlag = false;
        var defaultBarronsShopUriFlag = false;
        for (var key in wsjDomainUrlMap) {
            if(request.uri === wsjDomainUrlMap[key]){
                defaultWSJShopUriFlag = true;
            }
        }
        for (var key in barDomainUrlMap) {
            if(request.uri === barDomainUrlMap[key]){
                defaultBarronsShopUriFlag = true;
            }
        }
        logDebug("urlfinder :: find_url :: defaultWSJShopUriFlag:", defaultWSJShopUriFlag);
        logDebug("urlfinder :: find_url :: defaultBarronsShopUriFlag:", defaultBarronsShopUriFlag);

        var reqUriVal = request.uri;
        if (reqUriVal === EMPTY_URI || reqUriVal === EMPTY_URI_SLASH || reqUriVal === ROOT_INDEX ) {
            const response = redirecting_response(domainUrlMap[domain_type], defaultUrlByCountry, null);
            logInfo("urlfinder :: find_url :: blank-uri or slash :: response:", response);
            logInfo("urlfinder :: find_url :: blank-uri or slash :: redirecting to:", defaultUrlByCountry);
            callback(null, response);

        } else if (reqUriVal.indexOf(URI_SHOPPAGES) == -1) {
            logInfo("urlfinder :: find_url :: reqUriVal:", reqUriVal);
            logInfo("urlfinder :: find_url :: forwarding to sitecontrol:", domain_sitecontrol);
            callback(null, customoriginreq_sitecontrol(request, domain_sitecontrol) );

        } else if (parsedPath.ext !== '') {
            logInfo("urlfinder :: find_url :: non-empty-ext :: same as original :: final URI:", request.uri);
            callback(null, request);
        } else if (request.uri === ROOT_SHOP || defaultWSJShopUriFlag == true || defaultBarronsShopUriFlag == true) {
            request.uri = request.uri + default_doc;
            logInfo("urlfinder :: find_url :: root :: final URI:", request.uri);
            callback(null, request);

        } else if (!request.uri.endsWith(CHAR_SLASH)) {
            newUri = request.uri + CHAR_SLASH;
            logDebug('urlfinder :: find_url :: about to redirect :: newUri:', newUri);
            const response = redirecting_response(domainUrlMap[domain_type], newUri, qrystringVal);
            callback(null, response);

        } else {
            var uri_val = domain_type + CHAR_COLON + parsedPath.base;
            logInfo("urlfinder :: find_url :: uri_val to search in DDB:", uri_val); // uri_val is the Primary-Partition-Key in DDB
            var ddbQryRecPromise = exec_query(ddb_tablename, uri_val, defaultUrlByCountry, false, domainUrlMap, ddb_role_arnval);
            ddbQryRecPromise.then(path2display => {
                logDebug("urlfinder :: find_url :: ddbQryRecPromise.then :: path2display:", path2display);

                if (path2display.indexOf(REDIRECT_PREFIX) > -1) {
                    var path2redirect = path2display.substring(REDIRECT_PREFIX.length);
                    logDebug('urlfinder :: find_url :: promise :: about to redirect :: path2redirect:', path2redirect);
                    const response = redirecting_response(domainUrlMap[domain_type], path2redirect, qrystringVal);
                    callback(null, response);
                } else {
                    newUri = path.join(parsedPath.dir, path2display, default_doc);
                    request.uri = newUri; //Replace the received URI with the URI that includes the index page
                    logInfo("urlfinder :: find_url :: final URI:", request.uri);
                    callback(null, request);
                }
            });
        }
    }
};

/**
 * exec_query executes the query on DynamoDB's Table: shopurl for the given Uri and 
 * fetches the identified record to find out the respective URL (ActualUrl or FalllbackUrl) to display
 * 
 * @param {*} ddbTableName
 * @param {*} uriVal
 * @param {*} defaultUrlByCountry
 * @param {*} vanityFlag
 * @param {*} domainUrlMapObj
 */
const exec_query = (ddbTableName, uriVal, defaultUrlByCountry, vanityFlag, domainUrlMapObj, ddb_role_arnval) => {
            //RoleArn: "arn:aws:iam::577744393569:role/ddb_role_A",

    return new Promise((resolve, reject) => {
        var ddb_params = {
            TableName: ddbTableName,
            Key: { 'Uri': { S: uriVal } }
        };

        var assumeddbrole = assume_ddbrole(ddb_role_arnval);
        assumeddbrole.then(data => {

            var ddb = new AWS.DynamoDB({
                apiVersion: '2012-10-08',
                accessKeyId: data.Credentials.AccessKeyId,
                secretAccessKey: data.Credentials.SecretAccessKey,
                sessionToken: data.Credentials.SessionToken
            });

            ddb.getItem(ddb_params, function (err, uridata_result) {
                var redirectUrlVal; 
                if (err) {
                    logError("urlfinder :: exec_query :: ERROR :: exec_query :: err:", err);
                    redirectUrlVal = REDIRECT_PREFIX; 
                    redirectUrlVal += (vanityFlag==true) ? (domainUrlMapObj["wsj"] + defaultUrlByCountry) : defaultUrlByCountry;
                    resolve(redirectUrlVal);
                } else {
                    logInfo("urlfinder :: exec_query :: getItem :: uri item:", uridata_result.Item);

                    var uridata_rec = uridata_result.Item;
                    var redirectFlag = false;
                    if (uridata_rec) {
                        let actualUrlVal;
                        if (uridata_rec.ActualUrl) {
                            actualUrlVal = uridata_rec.ActualUrl.S;
                            logDebug("urlfinder :: exec_query :: ActualUrlVal:", actualUrlVal);
                        }

                        let fallbackUrlVal;
                        if (uridata_rec.FallbackUrl) {
                            fallbackUrlVal = uridata_rec.FallbackUrl.S;
                            logDebug("urlfinder :: exec_query :: FallbackUrl:", fallbackUrlVal);
                        }

                        let startDateTimeVal;
                        if (uridata_rec.StartDateTime && uridata_rec.StartDateTime.N > 0) {
                            startDateTimeVal = uridata_rec.StartDateTime.N;
                            logDebug("urlfinder :: exec_query :: startDateTimeVal:", startDateTimeVal);
                        }

                        let endDateTimeVal;
                        if (uridata_rec.EndDateTime && uridata_rec.EndDateTime.N > 0) {
                            endDateTimeVal = uridata_rec.EndDateTime.N;
                            logDebug("urlfinder :: exec_query :: endDateTimeVal:", endDateTimeVal);
                        }

                        var url2display = actualUrlVal;
                        logDebug("exec_query :: initial :: url2display:", url2display);
                        var currentTime = Date.now();
                        if (startDateTimeVal && currentTime < startDateTimeVal) {
                            if (fallbackUrlVal) {
                                redirectFlag = true;
                                url2display = fallbackUrlVal;
                                logDebug("exec_query :: startDateTimeVal :: fallbackUrl :: url2display:", url2display);
                            }
                        }
                        if (endDateTimeVal && currentTime > endDateTimeVal) {
                            if (fallbackUrlVal) {
                                redirectFlag = true;
                                url2display = fallbackUrlVal;
                                logDebug("exec_query :: endDateTimeVal :: fallbackUrl :: url2display:", url2display);
                            }
                        }

                        logDebug("exec_query :: url2display:", url2display);
                        if (!url2display || url2display === '') {
                            logDebug("exec_query :: url2display not found. Hence, setting up the default_url");
                            redirectFlag = true;
                            url2display = defaultUrlByCountry;
                        }

                        if(vanityFlag==true){
                            url2display = REDIRECT_PREFIX + url2display; 
                        }else if(redirectFlag==true){
                            url2display = REDIRECT_PREFIX + ROOT_SHOP + url2display;
                        }

                        logInfo("urlfinder :: exec_query :: finally about to resolve:", url2display);
                        resolve(url2display);
                    } else {
                        redirectUrlVal = REDIRECT_PREFIX; 
                        redirectUrlVal += (vanityFlag==true) ? (domainUrlMapObj["wsj"] + defaultUrlByCountry) : defaultUrlByCountry;
                        logDebug("urlfinder :: exec_query :: redirectUrlVal:", redirectUrlVal);
                        resolve( redirectUrlVal);
                    }
                }
            });
        });

    });
};

/**
 * Prepares response object for the callback with FallbackUrl
 * @param {*} headers
 * @param {*} domainPath
 */
const find_defaulturl_bycountry = (headersObj, domainPath) => {
    var countryCode;
    if (headersObj['cloudfront-viewer-country']) {
        countryCode = headersObj['cloudfront-viewer-country'][0].value;
        logDebug("urlfinder :: find_defaulturl_bycountry :: 1 :: countryCode:", countryCode);
        countryCode = (!countryCode) ? DEFAULT_CNTRYCODE : countryCode;
    }
    logDebug("urlfinder :: find_defaulturl_bycountry :: 2 :: countryCode:", countryCode);

    var regionCode = envInfo.envData[countryCode];
    logDebug("urlfinder :: find_defaulturl_bycountry :: 1 :: regionCode:", regionCode);
    regionCode = (!regionCode) ? DEFAULT_REGIONCODE : regionCode;
    logDebug("urlfinder :: find_defaulturl_bycountry :: 2 :: regionCode:", regionCode);

    var defaultUrlByCountryVal = wsjDomainUrlMap[regionCode]; //assuming that it is WSJ
    defaultUrlByCountryVal = (!defaultUrlByCountryVal) ? defaultUrlWSJ : defaultUrlByCountryVal;
    if (domainPath.indexOf(DOMAIN_BAR) > -1) {
        defaultUrlByCountryVal = barDomainUrlMap[regionCode];
        defaultUrlByCountryVal = (!defaultUrlByCountryVal) ? defaultUrlBarrons : defaultUrlByCountryVal;
    }
    logDebug("urlfinder :: find_defaulturl_bycountry :: defaultUrlByCountryVal:", defaultUrlByCountryVal);

    return defaultUrlByCountryVal;
};

const customoriginreq_sitecontrol = (reqObj, siteCtrlDomainVal) => {
    reqObj.origin = {
        custom: {
            domainName: siteCtrlDomainVal,
            port: 443,
            protocol: 'https',
            path: '',
            sslProtocols: ['TLSv1', 'TLSv1.1', 'TLSv1.2'],
            readTimeout: 30,
            keepaliveTimeout: 30,
            customHeaders: {}
        }
    };
    reqObj.headers['host'] = [{ key: 'host', value: siteCtrlDomainVal }];

    return reqObj;
};

/**
 * Prepares response object for the callback with FallbackUrl
 * @param {*} domainVal
 * @param {*} url2redirect 
 * @param {*} qryStrVal
 */
const redirecting_response = (domainVal, url2redirect, qryStrVal) => {
    var completeUrl2redirect = domainVal + url2redirect;
    if(qryStrVal !== null && qryStrVal.length > 0){
        completeUrl2redirect += qryStrVal;
    }
    var response_val = {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: completeUrl2redirect,
            }],
        },
    };

    return response_val;
};

/**
 * Prepares response object for the redirectURL
 * @param {*} url2redirect 
 */
const vanity_redirecting_response = (url2redirect) => {
    var completeUrl2redirect = PROTOCOL_PREFIX + url2redirect;
    var response_val = {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: completeUrl2redirect,
            }],
        },
    };

    return response_val;
};

const assume_ddbrole = (ddb_role_arn) => {
    return new Promise((resolve, reject) => {
        sts.assumeRole({
            RoleArn: ddb_role_arn,
            RoleSessionName: 'awssdk'
        }, function (err, data) {
            if (err) {
                logError("urlfinder :: assume_ddbrole :: ERROR :: assumeRole :: err:", err);
            } else { // successful response
                resolve(data);
            }
        });
    });
};