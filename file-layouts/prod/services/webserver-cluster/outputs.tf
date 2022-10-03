output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
  description = "the domain name of the load balancer"
}