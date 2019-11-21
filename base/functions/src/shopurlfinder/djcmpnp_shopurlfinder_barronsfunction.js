'use strict';
const DOMAIN_WSJ = "wsj";
const DOMAIN_BAR = "barrons";
const CHAR_SLASH = "/";
const DEFAULT_SHOP = "/shop/";


exports.handler = (event, context, callback) => {
    
    // Extract the request from the CloudFront event that is sent to Lambda@Edge 
    var request = event.Records[0].cf.request;

    //https://caj-int.smpdev.wsj.com/shop/EMEA09202018
    // Extract the URI from the request
    var olduri = request.uri;
    var qrystringVal = request.querystring;
    if (qrystringVal !== '') {
        qrystringVal = '?' + qrystringVal;
    }
    // Match any '/' that occurs at the end of a URI. Replace it with a default index
    var newuri = olduri.replace(/\/$/, '\/index.html');

    var urlarr = newuri.split('/');

    if(olduri === '' || olduri === '/'){ //PnP :: added this condition for default shop-page
        const response = redirecting_response(DEFAULT_SHOP, qrystringVal);
        callback(null, response);

    }else if (!newuri.endsWith(CHAR_SLASH) && urlarr[urlarr.length-1].indexOf('.') === -1) {
        newuri = newuri + CHAR_SLASH;
        const response = redirecting_response(newuri, qrystringVal);
        callback(null, response);
    } else  {

        var brandFolder = "barrons";

        //adding brand folder to request
        //var brandFolder = "barrons"; //default
        //if(newuri.indexOf(DOMAIN_WSJ) > -1){
        //    brandFolder = "wsj";
        //}

        //PnP :: appended an additional "/shop" path after the brandFolder
        //newuri = newuri.replace('/shop','/shop/' + brandFolder);
        newuri = newuri.replace('/shop', '/shop/' + brandFolder + '/shop');

        // Log the URI as received by CloudFront and the new URI to be used to fetch from origin
        console.log("Old URI: " + olduri);
        console.log("New URI: " + newuri);
        
        // Replace the received URI with the URI that includes the index page
        request.uri = newuri;
        
        // Return to CloudFront
        return callback(null, request);
    }

};


const redirecting_response = (url2redirect, qryStrVal) => {
    var completeUrl2redirect =  url2redirect + qryStrVal;
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