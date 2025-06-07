provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

resource "aws_s3_bucket" "wiz_bucket" {
  bucket = "wiz-demo-bucket-${random_id.rand.hex}"
  acl    = "private"

  tags = {
    Name        = "WizDemo"
    Environment = "Dev"
  }
}

resource "random_id" "rand" {
  byte_length = 4
}
