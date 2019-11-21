resource "aws_iam_role" "ec2_iam_role" {
  name = "${local.shrsvc_app_service_name}-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [{
        "Effect": "Allow",
        "Principal": {"Service":  "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
    }
    ]
}
EOF
}

# resource "aws_iam_role_policy" "iam_role_policy" {
#     name = "pnp_generic_policy"
#     role = "${aws_iam_role.ec2_iam_role.id}"
#     policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement":
#     [
#         {
#             "Sid": "Stmt1499109483000",
#             "Effect": "Allow",
#             "Action": [
#                 "cloudwatch:*"
#             ],
#             "Resource": [
#                 "*"
#             ]
#         },
#         {
#             "Sid": "Stmt1499103493000",
#             "Effect": "Allow",
#             "Action": [
#                 "dynamodb:BatchGetItem",
#                 "dynamodb:BatchWriteItem",
#                 "dynamodb:PutItem",
#                 "dynamodb:DescribeTable",
#                 "dynamodb:DeleteItem",
#                 "dynamodb:GetItem",
#                 "dynamodb:Query",
#                 "dynamodb:Scan",
#                 "dynamodb:UpdateItem"
#             ],
#             "Resource": [
#                 "arn:aws:dynamodb:*:*:table/${lookup(local.shopurl_dynamodb_config, "table_name")}*"
#                 "arn:aws:dynamodb:*:*:table/${lookup(local.vanityurl_dynamodb_config, "table_name")}*"
#             ]
#         },
#         {
#             "Sid": "Stmt4ProdCloudFront",
#             "Effect": "Allow",
#             "Action": "sts:AssumeRole",
#             "Resource": "arn:aws:iam::${lookup(var.cloudfronts_aws_account_map, var.environment)}:role/djcmpnp_urlmgmt_lambdacahceinv_cf_role_${var.environment}"
#         },
#         { 
#             "Sid": "Stmt1499103495400",
#             "Effect": "Allow", 
#             "Action": "sts:AssumeRole",
#             "Resource": "arn:aws:iam:::role/djis-caj-pnp-dynconfig-${var.environment}" 
#         }
#     ]
# }
# EOF
# }



#   {
#       "Sid": "Stmt1499103348000",
#       "Effect": "Allow",
#       "Action": [
#           "s3:*"
#       ],
#       "Resource": [
#           "*"
#       ]
#   },