data "external" "lambda_packager" {
  count = "${var.execute_program_path == "" ? 0 : 1}"
  program = ["${path.module}${var.execute_program_path}"]

  query = {
    include_paths = "${join(",", var.include_paths)}"
    output_path   = "${local.output_path}"
  }
}

resource "aws_lambda_function" "lambda" {
  count         = "${var.enable ? 1 : 0}"
  function_name = "${var.name}${var.lambda_name_suffix}"
  description   = "${var.description}"
  handler       = "${var.handler}"
  runtime       = "${var.runtime}"
  timeout       = "${var.timeout}"
  publish       = "${var.publish}"

  role = "${join(var.role, aws_iam_role.lambda.*.arn)}"

  filename         = "${var.package_path}"
  source_code_hash = "${local.package_hash}"

  tags = "${var.tags}"
}

# role             = "${aws_iam_role.djcmpnp_urlcfcacheinvlambdaexec_role.arn}"
# handler          = "djcmpnp_shopurlcfcacheinv_function.invalidate_cache"
# timeout          = 120
# source_code_hash = "${data.archive_file.deploy_shopurlcfcacheinv.output_base64sha256}"
# runtime          = "nodejs8.10"
# publish          = true

