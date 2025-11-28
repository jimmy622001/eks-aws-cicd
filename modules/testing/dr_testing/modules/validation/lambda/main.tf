/**
 * DR Testing Validation Lambda Module
 */

resource "aws_lambda_function" "validation" {
  function_name = "${var.project_name}-dr-validation"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  
  filename      = "${path.module}/function.zip"
  
  environment {
    variables = {
      PRIMARY_REGION = var.primary_region
      DR_REGION      = var.dr_region
      PROJECT_NAME   = var.project_name
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "dr-validation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "dr-validation-lambda-policy"
  description = "Policy for DR validation Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "eks:DescribeCluster",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "dynamodb:DescribeTable",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}