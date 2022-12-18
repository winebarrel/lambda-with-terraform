data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "nyan" {
  name_prefix        = "nyan-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name   = "logs"
    policy = data.aws_iam_policy_document.logs.json
  }
}


resource "null_resource" "npm_install" {
  triggers = {
    package_json      = filebase64sha256("src/package.json")
    package_lock_json = filebase64sha256("src/package-lock.json")
  }

  provisioner "local-exec" {
    working_dir = "src"
    command     = "npm install"
  }
}


data "archive_file" "nyan" {
  type        = "zip"
  output_path = "app.zip"
  source_dir  = "src"
  depends_on  = [null_resource.npm_install]
}

resource "aws_lambda_function" "nyan" {
  function_name    = "nyan"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.nyan.arn
  handler          = "app.handler"
  filename         = data.archive_file.nyan.output_path
  source_code_hash = data.archive_file.nyan.output_base64sha256
}
