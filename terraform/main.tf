terraform {
 backend "gcs" {
   bucket = "thoughtworks-newsfeedapp-terraform"
   prefix = "/state/newsfeedapp"
 } 
}