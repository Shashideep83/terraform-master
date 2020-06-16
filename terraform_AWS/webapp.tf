provider "aws" {
  region     = "ap-south-1"
  access_key = ""
  secret_key = ""
}





resource "aws_instance" "myin" {
ami="ami-052c08d70def0ac62"
instance_type="t2.micro"
key_name="redhat"
security_groups=["launch-wizard-1"]

connection {
	
	type = "ssh"
	user = "ec2-user"
	private_key=file("/home/shashi/Downloads/redhat.pem")
	host =aws_instance.myin.public_ip
}


provisioner "remote-exec" {
	
	inline=[
		"sudo yum install httpd php git -y",
		"sudo systemctl restart httpd",
		"sudo systemctl enable httpd"
	]
}


tags= {

Name="terraform os"
}
}



resource "aws_ebs_volume" "ebs1terra" {
  availability_zone = aws_instance.myin.availability_zone
  size              = 1
 
  tags = {
    Name = "ebshardisk"
  }
}





resource "aws_volume_attachment" "ebs_attach_myin" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1terra.id
  instance_id = aws_instance.myin.id
  force_detach=true
}






resource "null_resource" "nulllocal8" {

provisioner "local-exec" {
	
	command = "echo ${aws_instance.myin.public_ip} > public_ip.txt"
}
}
 
resource "null_resource" "nullremote9" {

depends_on=[
		
		aws_volume_attachment.ebs_attach_myin,

		]

connection {
	
	type = "ssh"
	user = "ec2-user"
	private_key=file("/home/shashi/Downloads/redhat.pem")
	host =aws_instance.myin.public_ip
}

provisioner "remote-exec" {
	
	inline=[
		"sudo mkfs.ext4 /dev/xvdh",
		"sudo mount /dev/xvdh /var/www/html",
		"sudo rm -rf /var/www/html/*",
		"sudo git clone https://github.com/Shashideep83/pull_terraform.git /var/www/html"

	]
}
}
resource "aws_cloudfront_distribution" "terra-cloudfront" {
 enabled = true
 is_ipv6_enabled = true
 
 origin {
  domain_name = aws_s3_bucket.terra-bucket.bucket_regional_domain_name
  origin_id = local.s3_origin_id
 }
restrictions {
  geo_restriction {
   restriction_type = "none"
  }
 }
default_cache_behavior {
  target_origin_id = local.s3_origin_id
  allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
     cached_methods  = ["HEAD", "GET", "OPTIONS"]
forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
  }
viewer_protocol_policy = "redirect-to-https"
     min_ttl                = 0
     default_ttl            = 120
     max_ttl                = 86400
 }
viewer_certificate {
     cloudfront_default_certificate = true
   }
}
