# frozen_string_literal: true

template(:network) do
  product   = :kubernetes
  base_tags = { product: product }

  resource :aws_vpc, product do
    cidr_block '10.1.0.0/16'
    enable_dns_support true
    enable_dns_hostnames true
    tags base_tags.merge(
      {
        Name: "#{product}_vpc"
      }
    )
  end

  # vpc_id_ref = "${aws_vpc.#{product}.id}"

  # resource :aws_internet_gateway, "#{product}_igw" do
  #   vpc_id vpc_id_ref
  #   tags base_tags.merge(Name: "#{product}_igw")
  # end

  # resource :aws_subnet, "#{product}_public_subnet" do
  #   vpc_id vpc_id_ref
  #   cidr_block '10.0.1.0/24'
  #   map_public_ip_on_launch true
  #   availability_zone 'us-east-1a'
  #   tags base_tags.merge(Name: "#{product}_public_subnet")
  # end

  # resource :aws_subnet, "#{product}_web_subnet" do
  #   vpc_id vpc_id_ref
  #   cidr_block '10.0.2.0/24'
  #   map_public_ip_on_launch false
  #   availability_zone 'us-east-1b'
  #   tags base_tags.merge(Name: "#{product}_web_subnet")
  # end

  # resource :aws_subnet, "#{product}_db_subnet" do
  #   vpc_id vpc_id_ref
  #   cidr_block '10.0.3.0/24'
  #   map_public_ip_on_launch false
  #   availability_zone 'us-east-1c'
  #   tags base_tags.merge(Name: "#{product}_db_subnet")
  # end

  # resource :aws_security_group, "#{product}_lb_sg" do
  #   vpc_id vpc_id_ref
  #   description 'Security group for Load Balancer'
  #   tags base_tags.merge(Name: "#{product}_lb_sg")
  # end

  # lb_sg_ref = "${aws_security_group.#{product}_lb_sg.id}"

  # resource :aws_security_group, "#{product}_web_sg" do
  #   vpc_id vpc_id_ref
  #   description 'Security group for Web Tier'
  #   tags base_tags.merge(Name: "#{product}_web_sg")
  # end

  # web_sg_ref = "${aws_security_group.#{product}_web_sg.id}"

  # resource :aws_security_group, "#{product}_db_sg" do
  #   vpc_id vpc_id_ref
  #   description 'Security group for Database Tier'
  #   tags base_tags.merge(Name: "#{product}_db_sg")
  # end

  # db_sg_ref = "${aws_security_group.#{product}_db_sg.id}"

  # Security Group Rules - Separate Resources

  ## Load Balancer: Allow HTTP/HTTPS from the internet
  # resource :aws_security_group_rule, "#{product}_lb_http_ingress" do
  #   security_group_id lb_sg_ref
  #   type 'ingress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end

  # resource :aws_security_group_rule, "#{product}_lb_https_ingress" do
  #   security_group_id lb_sg_ref
  #   type 'ingress'
  #   from_port 443
  #   to_port 443
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end

  ## Load Balancer Egress: Allow traffic to Web Tier
  # resource :aws_security_group_rule, "#{product}_lb_to_web_egress" do
  #   security_group_id lb_sg_ref
  #   type 'egress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   source_security_group_id web_sg_ref
  # end

  ## Web Tier: Allow traffic from Load Balancer only
  # resource :aws_security_group_rule, "#{product}_web_ingress_from_lb" do
  #   security_group_id web_sg_ref
  #   type 'ingress'
  #   from_port 80
  #   to_port 80
  #   protocol 'tcp'
  #   source_security_group_id lb_sg_ref
  # end

  ## Web Tier Egress: Allow traffic to Database Tier
  # resource :aws_security_group_rule, "#{product}_web_to_db_egress" do
  #   security_group_id web_sg_ref
  #   type 'egress'
  #   from_port 3306
  #   to_port 3306
  #   protocol 'tcp'
  #   source_security_group_id db_sg_ref
  # end

  ## Database Tier: Allow traffic from Web Tier only
  # resource :aws_security_group_rule, "#{product}_db_ingress_from_web" do
  #   security_group_id db_sg_ref
  #   type 'ingress'
  #   from_port 3306
  #   to_port 3306
  #   protocol 'tcp'
  #   source_security_group_id web_sg_ref
  # end

  #######################################################################################
  # compute testing
  #######################################################################################

  # 🛡 Security Group for the ASG Instances
  # resource :aws_security_group, "#{product}_asg_sg" do
  #   vpc_id vpc_id_ref
  #   description 'Security group for ASG NixOS node'
  #   tags base_tags.merge(Name: "#{product}_asg_sg")
  # end

  # asg_sg_ref = "${aws_security_group.#{product}_asg_sg.id}"

  # resource :aws_security_group_rule, "#{product}_asg_ssh_ingress" do
  #   security_group_id asg_sg_ref
  #   type 'ingress'
  #   from_port 22
  #   to_port 22
  #   protocol 'tcp'
  #   cidr_blocks ['0.0.0.0/0']
  # end

  # resource :aws_key_pair, "#{product}_key" do
  #   key_name "#{product}-nixos-key"
  #   public_key File.read("#{Dir.home}/.ssh/id_rsa.pub") # Path to your local public key
  #   tags base_tags.merge(Name: "#{product}-nixos-key")
  # end

  # key_name_ref = "${aws_key_pair.#{product}_key.key_name}"
  # resource :aws_launch_template, "#{product}_nixos_lt" do
  #   name "#{product}-nixos-template"
  #   image_id 'ami-08ee7b48673f8a214'
  #   instance_type 't3.micro'
  #   key_name key_name_ref
  #   vpc_security_group_ids [asg_sg_ref]
  #
  #   # NixOS Cloud Init (Replace this with a valid NixOS config)
  #   # user_data = Base64.strict_encode64(<<-EOF
  #   #   #cloud-config
  #   #   users:
  #   #     - name: admin
  #   #       sudo: ALL=(ALL) NOPASSWD:ALL
  #   #       shell: /bin/bash
  #   #       ssh_authorized_keys:
  #   #         - "your-public-ssh-key" # ⚠️ Add your SSH key
  #   #   EOF
  #   # )
  #
  #   tag_specifications [{
  #     resource_type: 'instance',
  #     tags: base_tags.merge(Name: "#{product}_nixos_instance")
  #   }]
  # end

  # launch_template_ref = "${aws_launch_template.#{product}_nixos_lt.id}"
  # web_subnet_ref      = "${aws_subnet.#{product}_web_subnet.id}"
  # resource :aws_autoscaling_group, "#{product}_nixos_asg" do
  #   launch_template({ id: launch_template_ref, version: '$Latest' })
  #   desired_capacity 0
  #   max_size  0
  #   min_size  0
  #   vpc_zone_identifier [web_subnet_ref]
  #   tag [{
  #     key: 'Name',
  #     value: "#{product}_nixos_asg",
  #     propagate_at_launch: true
  #   }]
  # end
end
