# configurando o Provedor AWS
provider "aws" {
  region = "ap-southeast-2" # REGIAO ONDE O MEU BUCEKT (GUILHERME) ESTA, PARA RODAR NA MAQUINA DE VOCES, MUDE PARA A REGIAO ONDE O SEU BUCKET ESTA, E AS CONFIG DA SUA CONTA AWS
}
# Buckets S3
resource "aws_s3_bucket" "local_files" {
  bucket = "local-files-${random_id.bucket_suffix.hex}"
  acl    = "private"
}



resource "aws_s3_bucket" "bronze" {
  bucket = "bronze-${random_id.bucket_suffix.hex}"
  acl    = "private"
}
resource "aws_s3_bucket" "silver" {
  bucket = "silver-${random_id.bucket_suffix.hex}"
  acl    = "private"
}
resource "aws_s3_bucket" "gold" {
  bucket = "gold-${random_id.bucket_suffix.hex}"
  acl    = "private"
}
# Fila SQS
resource "aws_sqs_queue" "queue" {
  name                      = "file-monitoring-queue-${random_id.bucket_suffix.hex}"
  delay_seconds             = 90
  max_message_size         = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
}
# SNS retestando para ver se funciona com video yt
resource "aws_sns_topic" "topic" {
  name = "file-monitoring-topic-${random_id.bucket_suffix.hex}"
  policy = jsonencode({
    Version = " 2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = "*"
        Condition = {
          ArnLike = {
            "aws:SourceArn": [
              "arn:aws:s3:::bronze-${random_id.bucket_suffix.hex}",
              "arn:aws:s3:::silver-${random_id.bucket_suffix.hex}",
              "arn:aws:s3:::gold-${random_id.bucket_suffix.hex}",
            ]
          }
        }
      },
    ]
  })
}





# Assinatura da fila SQS
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn           = aws_sns_topic.topic.arn
  protocol            = "sqs"
  endpoint            = aws_sqs_queue.queue.arn
  raw_message_delivery = true
}

# Notificações S3
resource "aws_s3_bucket_notification" "bronze_notification" {
  bucket = aws_s3_bucket.bronze.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".csv"
  }
}

resource "aws_s3_bucket_notification" "silver_notification" {
  bucket = aws_s3_bucket.silver.id

  topic {
    topic_arn = aws_sns_topic.topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "gold_notification" {
  bucket = aws_s3_bucket.gold.id

  topic {
    topic_arn = aws_sns_topic.topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# ID aleatório
resource "random_id" "bucket_suffix" {
  byte_length = 4


}