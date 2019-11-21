'use strict';

/**
 * Sparse Indexes: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general-sparse-indexes.html
 * DDB Querying: https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB/DocumentClient.html#query-property
 * DDB Querying: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.NodeJs.04.html
 * Using Promises: https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/using-promises.html
 */

var debugFlag = false; var infoFlag = true; var errorFlag = true;
var logDebug = debugFlag ? console.log.bind(console) : function () { };
var logInfo = infoFlag ? console.log.bind(console) : function () { };
var logError = errorFlag ? console.log.bind(console) : function () { };

var AWS = require('aws-sdk');
var envInfo = require('./env_info');
var sts = new AWS.STS();
var docClient = new AWS.DynamoDB.DocumentClient();

//GSI "DatesUsed" refers to the below 3 different types
var dateUsedType_START = 'START';
var dateUsedType_END = 'END';
var dateUsedType_BOTH = 'BOTH';
const ROOT_SHOP = "/shop/";
const ROOT_VANITY = "/";

var ddb_shopurl_gsiname = "ShopUrlDatesUsedIndex";
var ddb_vanityurl_gsiname = "VanityUrlDatesUsedIndex";

//Filter Expressions
var filterExpSTART = 'StartDateTime BETWEEN :low_boundary AND :high_boundary';
var filterExpEND = 'EndDateTime BETWEEN :low_boundary AND :high_boundary';

//ProjectionExpressions
var projectionExp_ActualUrl = 'Uri, ActualUrl';
var projectionExp_FallbackUrl = 'Uri, FallbackUrl';

/**
 * exports.invalidate_cache :: to createInvalidation request on CloudFront for the identified expired cache-paths
 * @param {*} event 
 * @param {*} context 
 * @param {*} callback 
 */
exports.invalidate_cache = (event, context, callback) => {

	var shopcfdistrib_map = {};
	shopcfdistrib_map['wsj'] = envInfo.envData.SHOP_CFDISTRIB_WSJ; // "E368W8YL187UC8";
	shopcfdistrib_map['bar'] = envInfo.envData.SHOP_CFDISTRIB_BAR; // "EFMAVPN7LBI6U";
	//NOTE: To support any new CloudFront Distribution, add the respective key and CfDistribId

	var vanitycfdistrib_map = {};
	vanitycfdistrib_map['wsj'] = envInfo.envData.VANITY_CFDISTRIB_WSJ; // "E368W8YL187UC8";
	//vanitycfdistrib_map['bar'] = envInfo.envData.VANITY_CFDISTRIB_BAR; // For now, barrons domain doesn't exist for vanity

	var cf_role_arnval = "arn:aws:iam::" + envInfo.envData.CF_AWS_ACCTNUMBER + ":role/djcmpnp_lambda_urlmgmt_cfcacheinv_role_" + envInfo.envData.ENVIRONMENT_NAME;
	logDebug("invalidate_cache :: cf_role_arnval:", cf_role_arnval);

	var ddb_shopurl_tablename = 'djcmpnp_shopurls_ddbtable_' + envInfo.envData.ENVIRONMENT_NAME;     //'djcmpnp_shopurls_ddbtable_qa1';
	var ddb_vanityurl_tablename = 'djcmpnp_vanityurls_ddbtable_' + envInfo.envData.ENVIRONMENT_NAME; //'djcmpnp_vanityurls_ddbtable_qa1';

	//Both can execute paralelly... as follows: But, just for the clear logs, executing it in sequentially through promise...
	execqry_n_invalidatecfcache(ddb_shopurl_tablename, ddb_shopurl_gsiname, shopcfdistrib_map, cf_role_arnval, true);
	execqry_n_invalidatecfcache(ddb_vanityurl_tablename, ddb_vanityurl_gsiname, vanitycfdistrib_map, cf_role_arnval, false);
};

/**
 * execqry_n_invalidatecfcache executes the given table and performs cf cache invalidation
 * 
 * @param {*} ddb_tbl 
 * @param {*} ddb_gsi 
 * @param {*} shopurlflag 
 * @param {*} cfdistrib_map 
 * @param {*} cf_role_arnval
 */
const execqry_n_invalidatecfcache = (ddb_tbl, ddb_gsi, cfdistrib_map, cf_role_arnval, shopurlflag) => {
	var low_boundarytime = new Date(); var high_boundarytime = new Date();
	logDebug("invalidate_cache :: ======> current time_val: " + low_boundarytime.getTime());
	//TODO :: revert this 5mins change, after the demo
	//low_boundarytime.setHours(low_boundarytime.getHours() - 1);
	//high_boundarytime.setHours(high_boundarytime.getHours() + 1);
	low_boundarytime.setMinutes(low_boundarytime.getMinutes() - 5);
	high_boundarytime.setMinutes(high_boundarytime.getMinutes() + 5);

	var low_bndrytime = low_boundarytime.getTime();
	var high_bndrytime = high_boundarytime.getTime();
	logDebug("invalidate_cache :: low_boundarytime:  " + low_boundarytime + "  - time_val: " + low_bndrytime);
	logDebug("invalidate_cache :: high_boundarytime: " + high_boundarytime + " - time_val: " + high_bndrytime);

	//TODO :: remove this
	//low_bndrytime = 1540147356186; high_bndrytime = 1540154556186;

	// 1. Execute Query for the StartDateTime is defined ONLY and the StartDateTime is within the low_boundary and high_boundary. Result: FallbackUrl
	var qry1 = exec_query(ddb_tbl, ddb_gsi, filterExpSTART, dateUsedType_START, low_bndrytime, high_bndrytime, projectionExp_FallbackUrl, shopurlflag);

	// 2. Execute Query for the EndDateTime is defined ONLY and the EndDateTime is within the low_boundary and high_boundary. Result: ActualUrl
	var qry2 = exec_query(ddb_tbl, ddb_gsi, filterExpEND, dateUsedType_END, low_bndrytime, high_bndrytime, projectionExp_ActualUrl, shopurlflag);

	// 3. Execute Query for the both Start and End DateTimes are defined and the StartDateTime is within the low_boundary and high_boundary. Result: FallbackUrl
	var qry3 = exec_query(ddb_tbl, ddb_gsi, filterExpSTART, dateUsedType_BOTH, low_bndrytime, high_bndrytime, projectionExp_FallbackUrl, shopurlflag);

	// 4. Execute for the both Start and End DateTimes are defined and the EndDateTime is within the low_boundary and high_boundary. Result: ActualUrl
	var qry4 = exec_query(ddb_tbl, ddb_gsi, filterExpEND, dateUsedType_BOTH, low_bndrytime, high_bndrytime, projectionExp_ActualUrl, shopurlflag);

	Promise.all([qry1, qry2, qry3, qry4]).then(cache_paths => {
		logDebug("Promise.all :: cache_paths: " + cache_paths.length);
		perform_cacheinvalidation(cache_paths, cfdistrib_map, cf_role_arnval, shopurlflag);
	});
};

/**
 * exec_query executes the query on DynamoDB's GlobalSecondaryIndex (shopurls.DatesUsedIndex)
 * for the given query parameters and returns the results (cache_paths to be invalidated)
 * @param {*} ddbTblName
 * @param {*} filterExpVal 
 * @param {*} dateUsedTypeVal 
 * @param {*} lowboundaryVal 
 * @param {*} highboundaryVal 
 * @param {*} projectionExpVal 
 */
const exec_query = (ddbTblName, ddb_gsiname, filterExpVal, dateUsedTypeVal, lowboundaryVal, highboundaryVal, projectionExpVal, shopurlflag) => {

	return new Promise((resolve, reject) => {
		var qry_params = {
			TableName: ddbTblName,
			IndexName: ddb_gsiname,
			KeyConditionExpression: 'DatesUsed = :dateused_type',
			FilterExpression: filterExpVal,
			ExpressionAttributeValues: {
				':dateused_type': dateUsedTypeVal,
				':low_boundary': lowboundaryVal,
				':high_boundary': highboundaryVal
			},
			ProjectionExpression: projectionExpVal
		};

		docClient.query(qry_params, function (err, qry_data) {
			if (err) {
				logError("exec_query :: qry_params:" + qry_params + " :: err: " + err);
			} else {
				var qry_results = [];      //TODO :: check to add Promise.all on the qry_data.Items
				qry_data.Items.forEach(function (url_data) {
					logDebug("exec_query :: Uri: " + url_data.Uri);
					var uri_data = url_data.Uri;
					var djdomain = uri_data.substring(0, uri_data.indexOf(":"));
					var urival = uri_data.substring(uri_data.indexOf(":") + 1);
					if (shopurlflag == true) {
						if (projectionExpVal === 'ActualUrl') {
							if (url_data.ActualUrl && url_data.ActualUrl !== '') {
								logDebug("exec_query :: ActualUrl: " + url_data.ActualUrl);
								qry_results.push(djdomain + ":" + url_data.ActualUrl);
							}
						} else {
							if (url_data.FallbackUrl && url_data.FallbackUrl !== '') {
								logDebug("exec_query :: FallbackUrl: " + url_data.FallbackUrl);
								qry_results.push(djdomain + ":" + url_data.FallbackUrl);
							}
						}
					} else {
						logDebug("exec_query :: urival: " + urival);
						qry_results.push(djdomain + ":" + urival);
					}
				});

				logDebug("-------------  exec_query :: Qry Result length: " + qry_results.length + " ---------------");
				resolve(qry_results);
			}
		});
	});
};

/**
 * perform_cacheinvalidation builds a single list of cache_paths to be invalidates
 * and creates Invalidation Request on the CloudFront Distribution
 * @param {*} cache_paths 
 * @param {*} cfdistribMap
 * @param {*} cf_role_arnval
 * @param {*} shopurlflag
 */
const perform_cacheinvalidation = (cache_paths, cfdistribMap, cf_role_arnval, shopurlflag) => {
	var all_cachepaths = [];
	var currtimestamp = new Date().getTime();
	var domainCachePathListMap = {}; //array of cache-paths for each domain (wsj and bar)

	cache_paths.forEach(function (curr_cache_pathlist) {
		logDebug("perform_cacheinvalidn :: curr_cache_pathlist: " + curr_cache_pathlist);
		if (curr_cache_pathlist && curr_cache_pathlist != '') {
			curr_cache_pathlist.forEach(function (curr_cache_path) {
				all_cachepaths.push(curr_cache_path);
				all_cachepaths.push(curr_cache_path + "/*");
			});
		}
	});

	logDebug("=================== about to seggregate cachepaths by domain ================");
	all_cachepaths.forEach(function (curr_path) {
		var domainval = curr_path.substring(0, curr_path.indexOf(":"));
		var cachepathval = curr_path.substring(curr_path.indexOf(":") + 1);
		logDebug("perform_cacheinvalidn ::: curr_path: " + curr_path + " ::: domainval: " + domainval + " ::: cachepathval: " + cachepathval);

		domainCachePathListMap[domainval] = domainCachePathListMap[domainval] || [];

		if (shopurlflag == true) {
			domainCachePathListMap[domainval].push(ROOT_SHOP + cachepathval);
		} else {
			domainCachePathListMap[domainval].push(ROOT_VANITY + cachepathval);
		}
	});

	var assumecfrole = assume_cfrole(cf_role_arnval);
	assumecfrole.then(data => {

		var cloudfront = new AWS.CloudFront({
			apiVersion: '2018-06-18',
			accessKeyId: data.Credentials.AccessKeyId,
			secretAccessKey: data.Credentials.SecretAccessKey,
			sessionToken: data.Credentials.SessionToken
		});

		logDebug("============== about to build createInvalidation request for each domain ============");
		Object.keys(cfdistribMap).forEach(function (currdomainkey) {
			var cfdistribId = cfdistribMap[currdomainkey];
			logInfo("perform_cacheinvalidn ::: currdomainkey: " + currdomainkey + " ::: cfdistribId: " + cfdistribId);

			var domainCachePathList = domainCachePathListMap[currdomainkey];
			logInfo("perform_cacheinvalidn ::: domainCachePathList: " + domainCachePathList);
			if (domainCachePathList && domainCachePathList.length > 0) {

				if (domainCachePathList.length > 2) { //TODO :: revert to 0, before check-in. 2 is just for testing
					var cfinvalidationreq_params = {
						DistributionId: cfdistribId,
						InvalidationBatch: {
							CallerReference: "cfCacheInvalidatingScheduler::" + currtimestamp,
							Paths: {
								Quantity: domainCachePathList.length,
								Items: domainCachePathList
							}
						}
					};

					logDebug("perform_cacheinvalidn ::: about to createInvalidation Request on CloudFront");
					cloudfront.createInvalidation(cfinvalidationreq_params, function (err, data) {
						if (err) {  // an error occurred
							logError(err, err.stack);
						} else {  // successful response
							logInfo(data);
						}
					});
				} else {
					logInfo("perform_cacheinvalidn ::: no cache_paths to be invalidated");
				}
			}
		});
	});
};

const assume_cfrole = (cf_role_arn) => {
	return new Promise((resolve, reject) => {
		sts.assumeRole({
			RoleArn: cf_role_arn,
			RoleSessionName: 'awssdk'
		}, function (err, data) {
			if (err) {
				logError("urlfinder :: assume_cfrole :: ERROR :: assumeRole :: err:", err);
			} else { // successful response
				resolve(data);
			}
		});
	});
};