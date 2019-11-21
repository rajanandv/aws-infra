locals {
  output_path = "${var.output_path != "" ? var.output_path : "${path.cwd}/.terraform/${var.name}.zip"}"
  package_hash = "${var.package_hash != "" ? var.package_hash : base64sha256(file(var.package_path))}"
}
